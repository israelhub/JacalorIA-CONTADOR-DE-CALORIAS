import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { parseNumber } from '../shared/utils/number-parser.util';

const FALLBACK_TIME_ZONE = 'America/Sao_Paulo';

type CoveragePlan = { missingDayKeys: string[] };

@Injectable()
export class StreakService {
  private readonly appTimeZone = this.resolveAppTimeZone();

  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
  ) {}

  async getUserStreak(userId: string): Promise<number> {
    await this.applyStreakBlockersIfNeeded(userId);
    const map = await this.buildStreakByUserIds([userId]);
    return map.get(userId) ?? 0;
  }

  async buildStreakByUserIds(userIds: string[]): Promise<Map<string, number>> {
    const dayKeysByUser = await this.buildEffectiveDayKeysByUserIds(userIds);
    return this.buildStreakMapFromDayKeys(dayKeysByUser);
  }

  buildStreakMapFromDayKeys(dayKeysByUser: Map<string, Set<string>>): Map<string, number> {
    const streakByUserId = new Map<string, number>();
    for (const [userId, dayKeys] of dayKeysByUser) {
      streakByUserId.set(userId, this.calculateStreakFromDayKeys(dayKeys));
    }
    return streakByUserId;
  }

  /**
   * Sequência contada só a partir de `windowStart` (ex.: criação do grupo / entrada do membro).
   * Ignora ofensivas anteriores à janela.
   * `windowStart` deve ser um instante real (createdAt/startsAt), não um token getDayStart.
   */
  calculateScopedStreakFromDayKeys(dayKeys: Set<string>, windowStart: Date): number {
    return this.calculateScopedStreakFromDayKey(
      dayKeys,
      this.toDayKeyInAppTimeZone(windowStart),
    );
  }

  calculateScopedStreakFromDayKey(dayKeys: Set<string>, windowStartKey: string): number {
    let streak = 0;
    let cursorKey = this.toDayKeyInAppTimeZone(new Date());

    // Dia atual ainda está em aberto: sem registro hoje, conta a partir de ontem.
    if (!dayKeys.has(cursorKey)) {
      const previous = this.shiftDayKey(cursorKey, -1);
      if (!previous) return 0;
      cursorKey = previous;
    }

    while (cursorKey >= windowStartKey) {
      if (!dayKeys.has(cursorKey)) break;
      streak += 1;
      const previous = this.shiftDayKey(cursorKey, -1);
      if (!previous) break;
      cursorKey = previous;
    }

    return streak;
  }

  /** Soma/subtrai dias em uma chave `YYYY-MM-DD` (calendário civil, sem fuso). */
  shiftDayKey(dayKey: string, deltaDays: number): string | null {
    const parsed = this.dayKeyToDate(dayKey);
    if (!parsed) return null;
    parsed.setUTCDate(parsed.getUTCDate() + deltaDays);
    return this.toDayKeyFromAppDayStart(parsed);
  }

  /**
   * Dias com ofensiva efetiva (refeição ativa ou bloqueador aplicado), por usuário.
   * Usado para streaks individuais e para fechar a sequência coletiva do grupo após 00:00.
   */
  async buildEffectiveDayKeysByUserIds(userIds: string[]): Promise<Map<string, Set<string>>> {
    const uniqueUserIds = [...new Set(userIds.filter((id) => id.trim().length > 0))];
    const effectiveByUserId = new Map<string, Set<string>>();
    if (uniqueUserIds.length === 0) return effectiveByUserId;

    const [meals, users] = await Promise.all([
      this.mealModel.findAll({
        where: {
          userId: { [Op.in]: uniqueUserIds },
          status: MealStatus.Active,
        },
        attributes: ['userId', 'createdAt'],
        order: [
          ['userId', 'ASC'],
          ['createdAt', 'DESC'],
        ],
      }),
      User.findAll({
        where: { id: { [Op.in]: uniqueUserIds } },
        attributes: ['id', 'streakBlockerAppliedDayKeys'],
      }),
    ]);

    const mealDayKeysByUser = new Map<string, Set<string>>();
    for (const meal of meals) {
      const userId = meal.userId;
      const key = this.toDayKeyInAppTimeZone(new Date(meal.createdAt));
      if (!mealDayKeysByUser.has(userId)) {
        mealDayKeysByUser.set(userId, new Set<string>());
      }
      mealDayKeysByUser.get(userId)!.add(key);
    }

    const appliedKeysByUser = new Map<string, Set<string>>();
    for (const user of users) {
      appliedKeysByUser.set(
        user.id,
        this.normalizeDayKeySet(user.streakBlockerAppliedDayKeys),
      );
    }

    const todayKey = this.toDayKeyInAppTimeZone(new Date());
    for (const userId of uniqueUserIds) {
      const mealDayKeys = mealDayKeysByUser.get(userId) ?? new Set<string>();
      const appliedDayKeys = appliedKeysByUser.get(userId) ?? new Set<string>();
      const effectiveDayKeys = new Set<string>(mealDayKeys);
      for (const key of appliedDayKeys) {
        if (key <= todayKey) {
          effectiveDayKeys.add(key);
        }
      }
      effectiveByUserId.set(userId, effectiveDayKeys);
    }

    return effectiveByUserId;
  }

  async getAppliedStreakBlockerDayKeys(userId: string): Promise<Set<string>> {
    await this.applyStreakBlockersIfNeeded(userId);

    const user = await User.findByPk(userId, {
      attributes: ['streakBlockerAppliedDayKeys'],
    });

    return this.normalizeDayKeySet(user?.streakBlockerAppliedDayKeys);
  }

  /**
   * Token de dia civil: meia-noite UTC com Y-M-D do calendário no fuso do app.
   * NÃO passe esse Date em toDayKeyInAppTimeZone — use toDayKeyFromAppDayStart.
   */
  getDayStartInAppTimeZone(date: Date): Date {
    const parts = this.getDatePartsInAppTimeZone(date);
    return new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
  }

  getWeekStartInAppTimeZone(date: Date): Date {
    const dayStart = this.getDayStartInAppTimeZone(date);
    const day = dayStart.getUTCDay();
    const offset = day === 0 ? 6 : day - 1;
    dayStart.setUTCDate(dayStart.getUTCDate() - offset);
    return dayStart;
  }

  /** Day key a partir de um instante real (ex.: createdAt da refeição). */
  toDayKeyInAppTimeZone(date: Date): string {
    const parts = this.getDatePartsInAppTimeZone(date);
    return `${parts.year}-${String(parts.month).padStart(2, '0')}-${String(parts.day).padStart(2, '0')}`;
  }

  /**
   * Day key a partir de um token retornado por getDayStartInAppTimeZone /
   * getWeekStartInAppTimeZone / dayKeyToDate. Usa componentes UTC do token
   * (não reinterpretar no fuso — em America/Sao_Paulo isso deslocaria 1 dia).
   */
  toDayKeyFromAppDayStart(dayStart: Date): string {
    const year = dayStart.getUTCFullYear();
    const month = String(dayStart.getUTCMonth() + 1).padStart(2, '0');
    const day = String(dayStart.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  getDatePartsInAppTimeZone(date: Date): {
    year: number;
    month: number;
    day: number;
  } {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: this.appTimeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });

    const pieces = formatter.formatToParts(date);
    const year = Number(pieces.find((piece) => piece.type === 'year')?.value ?? 0);
    const month = Number(pieces.find((piece) => piece.type === 'month')?.value ?? 0);
    const day = Number(pieces.find((piece) => piece.type === 'day')?.value ?? 0);
    return { year, month, day };
  }

  private calculateStreakFromDayKeys(dayKeys: Set<string>): number {
    let streak = 0;
    const cursor = this.getDayStartInAppTimeZone(new Date());
    const todayKey = this.toDayKeyFromAppDayStart(cursor);

    // Dia atual ainda está em aberto: se não houver registro hoje,
    // a sequência segue a partir de ontem (ainda não foi quebrada).
    if (!dayKeys.has(todayKey)) {
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }

    while (true) {
      const key = this.toDayKeyFromAppDayStart(cursor);
      if (!dayKeys.has(key)) break;
      streak += 1;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }

    return streak;
  }

  private async applyStreakBlockersIfNeeded(userId: string): Promise<void> {
    const sequelize = this.mealModel.sequelize;
    if (!sequelize) {
      return;
    }

    const now = new Date();
    const todayStart = this.getDayStartInAppTimeZone(now);
    const todayKey = this.toDayKeyFromAppDayStart(todayStart);

    await sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, {
        attributes: [
          'id',
          'equippedOffensiveBlockerId',
          'offensiveBlockerInventoryCount',
          'streakBlockerAppliedDayKeys',
        ],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });

      if (!user) {
        return;
      }

      const meals = await this.mealModel.findAll({
        where: {
          userId,
          status: MealStatus.Active,
          createdAt: {
            [Op.lte]: now,
          },
        },
        attributes: ['createdAt'],
        transaction,
      });

      const mealDayKeys = new Set<string>();
      for (const meal of meals) {
        mealDayKeys.add(this.toDayKeyInAppTimeZone(new Date(meal.createdAt)));
      }

      const existingApplied = this.normalizeDayKeySet(user.streakBlockerAppliedDayKeys);
      const plan = this.buildCoveragePlan(mealDayKeys, existingApplied, todayStart);
      // Never auto-consume blockers for "today" (day still in progress).
      // Only protect the single most recent completed miss (yesterday).
      // Multi-day historical gaps are recovered via the store "Restaurar" item.
      const completedMissing = plan.missingDayKeys.filter((key) => key < todayKey);
      if (completedMissing.length === 0) {
        return;
      }

      const yesterdayDate = new Date(todayStart);
      yesterdayDate.setUTCDate(yesterdayDate.getUTCDate() - 1);
      const yesterdayKey = this.toDayKeyFromAppDayStart(yesterdayDate);
      const onlyYesterdayMissed =
        completedMissing.length === 1 && completedMissing[0] === yesterdayKey;
      if (!onlyYesterdayMissed) {
        return;
      }

      const currentInventory = Math.max(
        0,
        parseNumber(user.offensiveBlockerInventoryCount),
      );
      if (currentInventory < 1) {
        return;
      }
      const nextInventory = currentInventory - 1;
      const nextApplied = new Set<string>(existingApplied);
      nextApplied.add(yesterdayKey);

      await user.update(
        {
          offensiveBlockerInventoryCount: Math.max(0, nextInventory),
          streakBlockerAppliedDayKeys: Array.from(nextApplied).sort(),
        },
        { transaction },
      );
    });
  }

  private buildCoveragePlan(
    mealDayKeys: Set<string>,
    existingAppliedKeys: Set<string>,
    todayStart: Date,
  ): CoveragePlan {
    const anchors = new Set<string>(mealDayKeys);
    for (const key of existingAppliedKeys) {
      anchors.add(key);
    }

    if (anchors.size === 0) {
      return { missingDayKeys: [] };
    }

    let latestAnchorDate: Date | null = null;
    for (const key of anchors) {
      const parsed = this.dayKeyToDate(key);
      if (!parsed) {
        continue;
      }

      if (parsed > todayStart) {
        continue;
      }

      if (!latestAnchorDate || parsed > latestAnchorDate) {
        latestAnchorDate = parsed;
      }
    }

    if (!latestAnchorDate || latestAnchorDate >= todayStart) {
      return { missingDayKeys: [] };
    }

    const missingDayKeys: string[] = [];
    const cursor = new Date(latestAnchorDate);
    cursor.setUTCDate(cursor.getUTCDate() + 1);

    while (cursor <= todayStart) {
      const key = this.toDayKeyFromAppDayStart(cursor);
      missingDayKeys.push(key);
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }

    return { missingDayKeys };
  }

  private normalizeDayKeySet(raw: unknown): Set<string> {
    if (!Array.isArray(raw)) {
      return new Set<string>();
    }

    const normalized = raw
      .map((value) => value?.toString().trim() ?? '')
      .filter((value) => /^\d{4}-\d{2}-\d{2}$/.test(value));

    return new Set<string>(normalized);
  }

  private dayKeyToDate(dayKey: string): Date | null {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dayKey)) {
      return null;
    }

    const [yearText, monthText, dayText] = dayKey.split('-');
    const year = Number(yearText);
    const month = Number(monthText);
    const day = Number(dayText);

    if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
      return null;
    }

    return new Date(Date.UTC(year, month - 1, day));
  }

  private resolveAppTimeZone(): string {
    const fromEnv = process.env.APP_TIME_ZONE?.trim();
    if (fromEnv) return fromEnv;

    // Não usar o timezone do host (ex.: UTC em cloud) — isso desloca o dia
    // do calendário/streaks em relação ao fuso local do usuário (Brasil).
    return FALLBACK_TIME_ZONE;
  }
}
