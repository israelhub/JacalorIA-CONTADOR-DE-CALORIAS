/**
 * Espelho das cotas do Google AI Studio (RPM / TPM / RPD).
 * RPD no Google reseta à meia-noite Pacific Time.
 *
 * Só modelos de texto com cota > 0 (úteis como fallback de análise).
 * Atualize via GEMINI_QUOTA_LIMITS (JSON) se o tier mudar.
 */

export type GeminiQuotaLimit = {
  model: string;
  label: string;
  rpm: number;
  tpm: number;
  rpd: number;
};

/** Modelos de saída de texto com cota utilizável no AI Studio. */
export const DEFAULT_GEMINI_QUOTA_LIMITS: GeminiQuotaLimit[] = [
  {
    model: 'gemini-3.5-flash-lite',
    label: 'Gemini 3.5 Flash Lite',
    rpm: 15,
    tpm: 250_000,
    rpd: 500,
  },
  {
    model: 'gemini-3.1-flash-lite',
    label: 'Gemini 3.1 Flash Lite',
    rpm: 15,
    tpm: 250_000,
    rpd: 500,
  },
  {
    model: 'gemini-2.5-flash-lite',
    label: 'Gemini 2.5 Flash Lite',
    rpm: 10,
    tpm: 250_000,
    rpd: 20,
  },
  {
    model: 'gemini-3-flash',
    label: 'Gemini 3 Flash',
    rpm: 5,
    tpm: 250_000,
    rpd: 20,
  },
];

export function resolveGeminiQuotaLimits(
  rawEnv?: string | null,
): GeminiQuotaLimit[] {
  const trimmed = rawEnv?.trim();
  if (!trimmed) {
    return DEFAULT_GEMINI_QUOTA_LIMITS;
  }

  try {
    const parsed = JSON.parse(trimmed) as Array<Partial<GeminiQuotaLimit>>;
    if (!Array.isArray(parsed) || parsed.length === 0) {
      return DEFAULT_GEMINI_QUOTA_LIMITS;
    }

    const defaultsByModel = new Map(
      DEFAULT_GEMINI_QUOTA_LIMITS.map((row) => [row.model, row]),
    );

    return parsed
      .map((row) => {
        const model = String(row.model || '').trim();
        if (!model) return null;
        const fallback = defaultsByModel.get(model);
        return {
          model,
          label: String(row.label || fallback?.label || model),
          rpm: Number(row.rpm ?? fallback?.rpm ?? 0),
          tpm: Number(row.tpm ?? fallback?.tpm ?? 0),
          rpd: Number(row.rpd ?? fallback?.rpd ?? 0),
        } satisfies GeminiQuotaLimit;
      })
      .filter((row): row is GeminiQuotaLimit => row != null);
  } catch {
    return DEFAULT_GEMINI_QUOTA_LIMITS;
  }
}
