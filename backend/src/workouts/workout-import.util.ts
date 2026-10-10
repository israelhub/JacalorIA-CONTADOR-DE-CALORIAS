import { parseNumber } from '../shared/utils/number-parser.util';

export type ImportedLoad = {
  weight: number;
  recordedAt: string;
};

export type ImportedExercise = {
  name: string;
  sets: number;
  reps: number;
  loads: ImportedLoad[];
};

export type ImportedRoutine = {
  name: string;
  exercises: ImportedExercise[];
};

const MAX_ROUTINES = 12;
const MAX_EXERCISES = 30;
const MAX_LOADS = 40;

export const clampInt = (value: unknown, fallback: number, min: number, max: number): number => {
  const parsed = Math.round(parseNumber(value, fallback));
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, parsed));
};

export const normalizeRoutineName = (value: unknown): string => {
  const name = String(value ?? '')
    .replace(/\s+/g, ' ')
    .trim();
  return name.slice(0, 40);
};

export const normalizeExerciseName = (value: unknown): string => {
  const name = String(value ?? '')
    .replace(/\s+/g, ' ')
    .trim();
  return name.slice(0, 80);
};

export const parseReps = (value: unknown, fallback = 10): number => {
  if (typeof value === 'number') {
    return clampInt(value, fallback, 1, 100);
  }

  const text = String(value ?? '');
  const range = text.match(/(\d+(?:[.,]\d+)?)\s*[-–]\s*(\d+(?:[.,]\d+)?)/);
  if (range) {
    const low = parseNumber(range[1], fallback);
    const high = parseNumber(range[2], fallback);
    return clampInt((low + high) / 2, fallback, 1, 100);
  }

  const first = text.match(/(\d+(?:[.,]\d+)?)/);
  return clampInt(first?.[1] ?? fallback, fallback, 1, 100);
};

export const toDateOnly = (value: unknown, fallbackYear: number): string | null => {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    const month = String(value.getUTCMonth() + 1).padStart(2, '0');
    const day = String(value.getUTCDate()).padStart(2, '0');
    return `${value.getUTCFullYear()}-${month}-${day}`;
  }

  const text = String(value ?? '').trim();
  if (!text) {
    return null;
  }

  const iso = text.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (iso) {
    return `${iso[1]}-${iso[2]}-${iso[3]}`;
  }

  const br = text.match(/^(\d{1,2})[\/\-.](\d{1,2})(?:[\/\-.](\d{2,4}))?/);
  if (!br) {
    return null;
  }

  const day = String(Number(br[1])).padStart(2, '0');
  const month = String(Number(br[2])).padStart(2, '0');
  let year = br[3] ? Number(br[3]) : fallbackYear;
  if (year < 100) {
    year += 2000;
  }

  if (Number(month) < 1 || Number(month) > 12 || Number(day) < 1 || Number(day) > 31) {
    return null;
  }

  return `${year}-${month}-${day}`;
};

export const normalizeImportedLoads = (
  raw: unknown,
  fallbackYear = new Date().getFullYear(),
): ImportedLoad[] => {
  if (!Array.isArray(raw)) {
    return [];
  }

  const loads: ImportedLoad[] = [];
  const seen = new Set<string>();

  for (const item of raw) {
    if (loads.length >= MAX_LOADS) {
      break;
    }

    const record = item && typeof item === 'object' ? (item as Record<string, unknown>) : {};
    const recordedAt = toDateOnly(
      record.recordedAt ?? record.date ?? record.dia ?? record.data,
      fallbackYear,
    );
    const weight = parseNumber(record.weight ?? record.peso ?? record.carga, NaN);
    if (!recordedAt || !Number.isFinite(weight) || weight < 0 || weight > 1000) {
      continue;
    }

    if (seen.has(recordedAt)) {
      const index = loads.findIndex((load) => load.recordedAt === recordedAt);
      if (index >= 0) {
        loads[index] = { weight, recordedAt };
      }
      continue;
    }

    seen.add(recordedAt);
    loads.push({ weight, recordedAt });
  }

  loads.sort((a, b) => a.recordedAt.localeCompare(b.recordedAt));
  return loads;
};

export const normalizeImportedExercises = (
  raw: unknown,
  fallbackYear = new Date().getFullYear(),
): ImportedExercise[] => {
  if (!Array.isArray(raw)) {
    return [];
  }

  const exercises: ImportedExercise[] = [];
  const seen = new Set<string>();

  for (const item of raw) {
    if (exercises.length >= MAX_EXERCISES) {
      break;
    }

    const record = item && typeof item === 'object' ? (item as Record<string, unknown>) : {};
    const name = normalizeExerciseName(record.name ?? record.nome ?? record.exercise);
    if (!name) {
      continue;
    }

    const key = name.toLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);

    exercises.push({
      name,
      sets: clampInt(record.sets ?? record.series ?? record.séries, 3, 1, 20),
      reps: parseReps(record.reps ?? record.repeticoes ?? record.repetições, 10),
      loads: normalizeImportedLoads(record.loads ?? record.cargas ?? record.historico, fallbackYear),
    });
  }

  return exercises;
};

export const normalizeImportedRoutines = (
  raw: unknown,
  fallbackYear = new Date().getFullYear(),
): ImportedRoutine[] => {
  const source =
    raw && typeof raw === 'object' && !Array.isArray(raw)
      ? (raw as Record<string, unknown>).routines ??
        (raw as Record<string, unknown>).treinos ??
        raw
      : raw;

  if (!Array.isArray(source)) {
    return [];
  }

  const routines: ImportedRoutine[] = [];
  const seen = new Set<string>();

  for (const item of source) {
    if (routines.length >= MAX_ROUTINES) {
      break;
    }

    const record = item && typeof item === 'object' ? (item as Record<string, unknown>) : {};
    const name = normalizeRoutineName(record.name ?? record.nome ?? record.treino);
    if (!name) {
      continue;
    }

    const key = name.toLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);

    const exercises = normalizeImportedExercises(
      record.exercises ?? record.exercicios ?? record.exercícios,
      fallbackYear,
    );
    if (exercises.length === 0) {
      continue;
    }

    routines.push({ name, exercises });
  }

  return routines;
};

export const extractJsonText = (text: string): string => {
  const trimmed = text.trim();
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  return (fenced?.[1] ?? trimmed).trim();
};
