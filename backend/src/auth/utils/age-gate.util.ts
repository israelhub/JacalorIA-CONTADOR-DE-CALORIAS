import { BadRequestException } from '@nestjs/common';
import { MIN_USER_AGE_YEARS } from '../constants/legal-documents';

export function assertMinimumAge(
  birthDate: string | null | undefined,
  minYears: number = MIN_USER_AGE_YEARS,
): void {
  if (birthDate == null || String(birthDate).trim().length === 0) {
    return;
  }

  const raw = String(birthDate).trim();
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})/.exec(raw);
  let year: number;
  let month: number;
  let day: number;

  if (isoMatch) {
    year = Number(isoMatch[1]);
    month = Number(isoMatch[2]);
    day = Number(isoMatch[3]);
  } else {
    const brMatch = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(raw);
    if (!brMatch) {
      throw new BadRequestException('Data de nascimento invalida.');
    }
    day = Number(brMatch[1]);
    month = Number(brMatch[2]);
    year = Number(brMatch[3]);
  }

  const birth = new Date(Date.UTC(year, month - 1, day));
  if (
    Number.isNaN(birth.getTime()) ||
    birth.getUTCFullYear() !== year ||
    birth.getUTCMonth() !== month - 1 ||
    birth.getUTCDate() !== day
  ) {
    throw new BadRequestException('Data de nascimento invalida.');
  }

  const today = new Date();
  let age = today.getUTCFullYear() - year;
  const monthDiff = today.getUTCMonth() - (month - 1);
  const dayDiff = today.getUTCDate() - day;
  if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
    age -= 1;
  }

  if (age < minYears) {
    throw new BadRequestException(
      `O JacalorIA e destinado a maiores de ${minYears} anos.`,
    );
  }
}
