import {
  Injectable,
  InternalServerErrorException,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WORKOUT_IMPORT_SYSTEM_PROMPT } from './prompts/workout-import-system-prompt';
import {
  extractJsonText,
  ImportedRoutine,
  normalizeImportedRoutines,
} from './workout-import.util';

const AI_OVERLOAD_MESSAGE =
  'Estamos enfrentando uma sobrecarga na IA. Tente novamente em alguns instantes.';
const TOTAL_TIMEOUT_MS = 40_000;
const PER_MODEL_TIMEOUT_MS = 12_000;
const MODEL_COOLDOWN_MS = 30_000;
const MAX_MODELS = 8;
const DEFAULT_PRIMARY_MODEL = 'gemini-3.5-flash-lite';
const DEFAULT_FALLBACK_MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash-lite',
  'gemini-3-flash',
].join(',');

@Injectable()
export class WorkoutImportProvider {
  private readonly logger = new Logger(WorkoutImportProvider.name);
  private readonly modelCooldownUntil = new Map<string, number>();

  constructor(private readonly configService: ConfigService) {}

  async parseNotes(text: string): Promise<ImportedRoutine[]> {
    const apiKey = this.configService.get<string>('API_KEY');
    if (!apiKey) {
      throw new InternalServerErrorException('API_KEY não configurada');
    }

    const models = this.resolveModels();
    const deadlineAt = Date.now() + TOTAL_TIMEOUT_MS;
    let lastErrorMessage = 'nenhuma tentativa concluída';
    const failedModels: string[] = [];

    for (let index = 0; index < models.length; index += 1) {
      const model = models[index];
      const remainingMs = deadlineAt - Date.now();
      if (remainingMs <= 0) {
        break;
      }

      if (this.isModelInCooldown(model)) {
        const hasLaterAvailable = models
          .slice(index + 1)
          .some((candidate) => !this.isModelInCooldown(candidate));
        if (hasLaterAvailable) {
          failedModels.push(model);
          lastErrorMessage = `cooldown ativo (${MODEL_COOLDOWN_MS}ms)`;
          continue;
        }
      }

      try {
        const raw = await this.callGeminiModel({
          apiKey,
          model,
          text,
          timeoutMs: Math.min(remainingMs, PER_MODEL_TIMEOUT_MS),
        });
        const routines = normalizeImportedRoutines(raw);
        if (routines.length === 0) {
          throw new Error('IA não encontrou treinos no texto');
        }
        return routines;
      } catch (error) {
        lastErrorMessage = error instanceof Error ? error.message : String(error);
        failedModels.push(model);
        this.markModelCooldown(model, lastErrorMessage);
        this.logger.warn(
          `Falha no modelo ${model} (tentativa ${index + 1}/${models.length}): ${lastErrorMessage}`,
        );
      }
    }

    this.logger.error(
      `Importação de treino falhou. Último erro: ${lastErrorMessage}. Modelos: ${failedModels.join(', ')}`,
    );
    throw new ServiceUnavailableException(AI_OVERLOAD_MESSAGE);
  }

  private async callGeminiModel(params: {
    apiKey: string;
    model: string;
    text: string;
    timeoutMs: number;
  }): Promise<Record<string, unknown>> {
    const { apiKey, model, text, timeoutMs } = params;
    const fetchFn = globalThis.fetch as unknown as (
      input: string,
      init: Record<string, unknown>,
    ) => Promise<Response>;

    const controller = new AbortController();
    const timeoutHandle = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetchFn(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: controller.signal,
          body: JSON.stringify({
            systemInstruction: {
              parts: [{ text: WORKOUT_IMPORT_SYSTEM_PROMPT }],
            },
            contents: [
              {
                role: 'user',
                parts: [
                  {
                    text: [
                      'Organize o texto abaixo em treinos, exercícios e histórico de carga.',
                      'Retorne apenas o JSON solicitado.',
                      'Texto do usuário:',
                      text,
                    ].join('\n'),
                  },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.1,
              responseMimeType: 'application/json',
            },
          }),
        },
      );

      if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorBody.slice(0, 500)}`);
      }

      const responseBody = (await response.json()) as {
        candidates?: Array<{
          content?: { parts?: Array<{ text?: string }> };
        }>;
      };

      const rawText = responseBody.candidates?.[0]?.content?.parts
        ?.map((part) => part.text ?? '')
        .join('')
        .trim();

      if (!rawText) {
        throw new Error('Resposta vazia do provedor de IA');
      }

      return JSON.parse(extractJsonText(rawText)) as Record<string, unknown>;
    } catch (error) {
      if (error && typeof error === 'object' && 'name' in error) {
        const name = String((error as { name?: string }).name);
        if (name === 'AbortError' || name === 'TimeoutError') {
          throw new Error(`Timeout após ${timeoutMs}ms`);
        }
      }
      throw error;
    } finally {
      clearTimeout(timeoutHandle);
    }
  }

  private isModelInCooldown(model: string): boolean {
    const until = this.modelCooldownUntil.get(model) ?? 0;
    if (until <= Date.now()) {
      if (until > 0) {
        this.modelCooldownUntil.delete(model);
      }
      return false;
    }
    return true;
  }

  private markModelCooldown(model: string, errorMessage: string): void {
    const normalized = errorMessage.toLowerCase();
    const shouldCooldown =
      normalized.includes('timeout') ||
      normalized.includes('429') ||
      normalized.includes('rate') ||
      normalized.includes('quota') ||
      normalized.includes('resource_exhausted') ||
      normalized.includes('unavailable');
    if (!shouldCooldown) {
      return;
    }
    this.modelCooldownUntil.set(model, Date.now() + MODEL_COOLDOWN_MS);
  }

  private resolveModels(): string[] {
    const configuredChain = this.configService.get<string>('GEMINI_MODELS')?.trim();
    const source = configuredChain
      ? configuredChain
      : `${this.configService.get<string>('GEMINI_MODEL', DEFAULT_PRIMARY_MODEL)},${this.configService.get<string>('GEMINI_FALLBACK_MODELS', DEFAULT_FALLBACK_MODELS)}`;

    const models: string[] = [];
    const seen = new Set<string>();
    for (const part of source.split(',')) {
      const model = part.trim();
      if (!model || seen.has(model)) {
        continue;
      }
      seen.add(model);
      models.push(model);
      if (models.length >= MAX_MODELS) {
        break;
      }
    }
    return models.length > 0 ? models : [DEFAULT_PRIMARY_MODEL];
  }
}
