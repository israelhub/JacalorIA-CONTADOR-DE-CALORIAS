import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Transaction } from 'sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { StreakService } from '../streak/streak.service';
import { parseNumber } from '../shared/utils/number-parser.util';
import { hasReachedCalorieGoal } from '../shared/utils/calorie-goal.util';
import {
  AVATAR_BACKGROUND_NONE_ID,
  AVATAR_FRAME_NONE_ID,
  OFFENSIVE_BLOCKER_DEFAULT_ID,
} from './constants/avatar-frame-store';
import { Mission, MissionType } from './models/mission.model';
import {
  CurrencyCode,
  UserCurrencyTransaction,
} from './models/user-currency-transaction.model';
import { StoreCatalogService } from './store-catalog.service';

type DailyTotals = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  meals: number;
  foods: Set<string>;
};

type MissionProgress = {
  progressCurrent: number;
};

type MissionItemPayload = {
  id: string;
  key: string;
  type: MissionType;
  title: string;
  description: string;
  accent: string;
  progressCurrent: number;
  progressTarget: number;
  progressLabel: string;
  progressPercent: number;
  rewardGold: number;
  rewardXp: number;
};

type WalletSnapshot = {
  gold: number;
  xp: number;
  goldLifetimeEarned: number;
  goldLifetimeSpent: number;
  xpLifetimeEarned: number;
  xpLifetimeSpent: number;
};

type StoreItem = {
  id: string;
  name: string;
  priceGold: number;
  owned: boolean;
  equipped: boolean;
  quantityOwned?: number;
  quantityPerPurchase?: number;
};

type BlockerRecoverySummary = {
  missingDaysUntilToday: number;
  requiredBlockersTotal: number;
  inventoryAvailable: number;
  requiredPurchaseQuantity: number;
  requiredPurchaseCostGold: number;
  canAffordRecoveryPurchase: boolean;
};

@Injectable()
export class MissionsService {
  constructor(
    @InjectModel(Mission)
    private readonly missionModel: typeof Mission,
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(UserCurrencyTransaction)
    private readonly userCurrencyTransactionModel: typeof UserCurrencyTransaction,
    private readonly streakService: StreakService,
    private readonly storeCatalogService: StoreCatalogService,
  ) {}

  async getMissions(userId: string) {
    const now = new Date();
    const todayStart = this.streakService.getDayStartInAppTimeZone(now);
    const weekStart = this.streakService.getWeekStartInAppTimeZone(now);
    const nowParts = this.streakService.getDatePartsInAppTimeZone(now);
    const monthStart = new Date(Date.UTC(nowParts.year, nowParts.month - 1, 1));

    const [user, missions, meals] = await Promise.all([
      this.userModel.findByPk(userId, {
        attributes: [
          'dailyCalorieGoal',
          'dailyProteinGoal',
          'dailyCarbsGoal',
          'dailyFatGoal',
          'objective',
        ],
      }),
      this.missionModel.findAll({
        where: { isActive: true },
        order: [
          ['type', 'ASC'],
          ['sortOrder', 'ASC'],
          ['createdAt', 'ASC'],
        ],
      }),
      this.mealModel.findAll({
        where: {
          userId,
          status: MealStatus.Active,
          createdAt: {
            [Op.gte]: monthStart,
            [Op.lt]: now,
          },
        },
        attributes: ['createdAt', 'calories', 'protein', 'carbs', 'fat', 'analysisItems'],
      }),
    ]);

    const dailyCalorieGoal = parseNumber(user?.dailyCalorieGoal, 2000);
    const dailyProteinGoal = parseNumber(user?.dailyProteinGoal, 120);
    const dailyCarbsGoal = parseNumber(user?.dailyCarbsGoal, 200);
    const dailyFatGoal = parseNumber(user?.dailyFatGoal, 60);

    const totalsByDay = new Map<string, DailyTotals>();

    for (const meal of meals) {
      const mealDate = new Date(meal.createdAt);
      const dayKey = this.streakService.toDayKeyInAppTimeZone(mealDate);
      const dayTotals = totalsByDay.get(dayKey) ?? {
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        meals: 0,
        foods: new Set<string>(),
      };

      dayTotals.calories += parseNumber(meal.calories);
      dayTotals.protein += parseNumber(meal.protein);
      dayTotals.carbs += parseNumber(meal.carbs);
      dayTotals.fat += parseNumber(meal.fat);
      dayTotals.meals += 1;

      const items = Array.isArray(meal.analysisItems) ? meal.analysisItems : [];
      for (const item of items) {
        const name = typeof item?.name === 'string' ? item.name.trim().toLowerCase() : '';
        if (name) {
          dayTotals.foods.add(name);
        }
      }

      totalsByDay.set(dayKey, dayTotals);
    }

    const todayTotals = totalsByDay.get(this.streakService.toDayKeyInAppTimeZone(todayStart));
    const weeklyEntries = this.collectDayTotalsInRange(totalsByDay, weekStart, now);
    const monthlyEntries = this.collectDayTotalsInRange(totalsByDay, monthStart, now);

    const metGoalToday = todayTotals
      ? hasReachedCalorieGoal({
        consumedCalories: todayTotals.calories,
        dailyCalorieGoal,
        objective: user?.objective,
      })
      : false;
    const metAllMacrosToday = todayTotals
      ? todayTotals.protein >= dailyProteinGoal &&
        todayTotals.carbs >= dailyCarbsGoal &&
        todayTotals.fat >= dailyFatGoal
      : false;

    const consecutiveDaysInWeek = this.calculateConsecutiveDays(
      totalsByDay,
      weekStart,
      this.streakService.getDayStartInAppTimeZone(now),
    );
    const weeklyGoalDays = weeklyEntries.filter((entry) =>
      hasReachedCalorieGoal({
        consumedCalories: entry.calories,
        dailyCalorieGoal,
        objective: user?.objective,
      })).length;
    const weeklyFoods = new Set<string>();
    for (const entry of weeklyEntries) {
      for (const food of entry.foods) {
        weeklyFoods.add(food);
      }
    }

    const monthlyGoalDays = monthlyEntries.filter((entry) =>
      hasReachedCalorieGoal({
        consumedCalories: entry.calories,
        dailyCalorieGoal,
        objective: user?.objective,
      })).length;
    const monthlyRegisteredDays = monthlyEntries.length;
    const monthlyMacroDays = monthlyEntries.filter(
      (entry) =>
        entry.protein >= dailyProteinGoal &&
        entry.carbs >= dailyCarbsGoal &&
        entry.fat >= dailyFatGoal,
    ).length;

    const missionByKey = new Map<string, MissionProgress>([
      [
        'daily_protein_goal',
        {
          progressCurrent: Math.round(todayTotals?.protein ?? 0),
        },
      ],
      [
        'daily_three_meals',
        {
          progressCurrent: todayTotals?.meals ?? 0,
        },
      ],
      [
        'weekly_streak_5_days',
        {
          progressCurrent: consecutiveDaysInWeek,
        },
      ],
      [
        'weekly_goal_4_times',
        {
          progressCurrent: weeklyGoalDays,
        },
      ],
      [
        'weekly_variety_15_foods',
        {
          progressCurrent: weeklyFoods.size,
        },
      ],
      [
        'monthly_master_consistency',
        {
          progressCurrent: monthlyGoalDays,
        },
      ],
      [
        'monthly_objective_focus',
        {
          progressCurrent: monthlyRegisteredDays,
        },
      ],
      [
        'monthly_macro_hunter',
        {
          progressCurrent: monthlyMacroDays,
        },
      ],
    ]);

    const missionItems: MissionItemPayload[] = missions.map((mission) => {
      const mapped = missionByKey.get(mission.key) ?? {
        progressCurrent: metGoalToday || metAllMacrosToday ? mission.targetValue : 0,
      };
      const progressTarget = Math.max(1, mission.targetValue || 1);
      const progressCurrent = Math.max(0, Math.min(mapped.progressCurrent, progressTarget));
      const percent = Math.round((progressCurrent / progressTarget) * 100);

      return {
        id: mission.id,
        key: mission.key,
        type: mission.type,
        title: mission.title,
        description: mission.description,
        accent: mission.accent,
        progressCurrent,
        progressTarget,
        progressLabel: `${progressCurrent}/${progressTarget}`,
        progressPercent: Math.max(0, Math.min(100, percent)),
        rewardGold: mission.rewardGold,
        rewardXp: mission.rewardXp,
      };
    });

    const sections = this.sectionOrder().map((section) => ({
      id: section.id,
      title: section.title,
      subtitle: section.subtitle,
      missions: missionItems.filter((mission) => mission.type === section.id),
    }));

    const completedMissions = missionItems.filter(
      (mission) => mission.progressCurrent >= mission.progressTarget,
    );

    await this.awardMissionCompletions(userId, completedMissions, now);
    const wallet = await this.getWalletSnapshot(userId);

    return {
      summary: {
        gold: wallet.gold,
        xp: wallet.xp,
        goldLifetimeEarned: wallet.goldLifetimeEarned,
        goldLifetimeSpent: wallet.goldLifetimeSpent,
        xpLifetimeEarned: wallet.xpLifetimeEarned,
        xpLifetimeSpent: wallet.xpLifetimeSpent,
      },
      intro: {
        title: 'Bem-vindo às Missões!',
        description:
          'Complete missões diárias, semanais e desafios mensais para ganhar ouro e XP. Suba de nível e desbloqueie recompensas com o Jaca!',
      },
      sections,
    };
  }

  async getStore(userId: string) {
    await Promise.all([
      this.ensurePurchasedAvatarFramesSynced(userId),
      this.ensurePurchasedAvatarBackgroundsSynced(userId),
    ]);

    const [user, wallet] = await Promise.all([
      this.userModel.findByPk(userId, {
        attributes: [
          'equippedAvatarFrameId',
          'purchasedAvatarFrameIds',
          'equippedAvatarBackgroundId',
          'purchasedAvatarBackgroundIds',
          'equippedOffensiveBlockerId',
          'offensiveBlockerInventoryCount',
        ],
      }),
      this.getWalletSnapshot(userId),
    ]);

    if (!user) {
      throw new BadRequestException('Usuário não encontrado.');
    }

    const purchasedFrames = new Set(this.normalizeIdList(user.purchasedAvatarFrameIds));
    const purchasedBackgrounds = new Set(this.normalizeIdList(user.purchasedAvatarBackgroundIds));
    const equippedFrameId = this.normalizeOptionalId(user.equippedAvatarFrameId);
    const equippedBackgroundId = this.normalizeOptionalId(user.equippedAvatarBackgroundId);
    const equippedBlockerId =
      this.normalizeOptionalId(user.equippedOffensiveBlockerId) ?? OFFENSIVE_BLOCKER_DEFAULT_ID;
    const blockerInventoryCount = Math.max(0, parseNumber(user.offensiveBlockerInventoryCount));
    const currentGold = wallet.gold;
    const blockerRecovery = await this.buildBlockerRecoverySummary({
      userId,
      inventoryCount: blockerInventoryCount,
      currentGold,
    });

    const [frameCatalog, backgroundCatalog, blockerCatalog] = await Promise.all([
      this.storeCatalogService.listActiveByCategory('avatar_frame'),
      this.storeCatalogService.listActiveByCategory('avatar_background'),
      this.storeCatalogService.listActiveByCategory('offensive_blocker'),
    ]);

    const frameItems: StoreItem[] = frameCatalog.map((entry) => ({
      id: entry.itemKey,
      name: entry.name,
      priceGold: entry.priceGold,
      owned: purchasedFrames.has(entry.itemKey),
      equipped: equippedFrameId === entry.itemKey,
    }));

    const backgroundItems: StoreItem[] = backgroundCatalog.map((entry) => ({
      id: entry.itemKey,
      name: entry.name,
      priceGold: entry.priceGold,
      owned: purchasedBackgrounds.has(entry.itemKey),
      equipped: equippedBackgroundId === entry.itemKey,
    }));

    const defaultBlocker = blockerCatalog.find(
      (entry) => entry.itemKey === OFFENSIVE_BLOCKER_DEFAULT_ID,
    );
    const blockerPriceGold = defaultBlocker?.priceGold ?? 0;
    const blockerItems: StoreItem[] = defaultBlocker
      ? [
          {
            id: defaultBlocker.itemKey,
            name: defaultBlocker.name,
            priceGold: blockerPriceGold,
            owned: blockerInventoryCount > 0,
            equipped: equippedBlockerId === defaultBlocker.itemKey,
            quantityOwned: blockerInventoryCount,
            quantityPerPurchase: 1,
          },
        ]
      : [];

    return {
      summary: {
        gold: wallet.gold,
        xp: wallet.xp,
        goldLifetimeEarned: wallet.goldLifetimeEarned,
        goldLifetimeSpent: wallet.goldLifetimeSpent,
        xpLifetimeEarned: wallet.xpLifetimeEarned,
        xpLifetimeSpent: wallet.xpLifetimeSpent,
      },
      categories: [
        {
          id: 'avatar_frames',
          title: 'Molduras',
          items: frameItems,
        },
        {
          id: 'avatar_backgrounds',
          title: 'Fundos',
          items: backgroundItems,
        },
        {
          id: 'offensive_blockers',
          title: 'Bloqueadores de ofensiva',
          items: blockerItems,
        },
      ],
      profile: {
        equippedAvatarFrameId: equippedFrameId,
        purchasedAvatarFrameIds: Array.from(purchasedFrames).sort(),
        equippedAvatarBackgroundId: equippedBackgroundId ?? AVATAR_BACKGROUND_NONE_ID,
        purchasedAvatarBackgroundIds: Array.from(purchasedBackgrounds).sort(),
        equippedOffensiveBlockerId: equippedBlockerId,
        offensiveBlockerInventoryCount: blockerInventoryCount,
      },
      blockerRecovery,
    };
  }

  async purchaseAvatarFrame(userId: string, frameId: string) {
    await this.ensurePurchasedAvatarFramesSynced(userId);

    const normalizedFrameId = frameId.trim();
    const catalogItem = await this.storeCatalogService.findActiveByKey(normalizedFrameId);
    if (!catalogItem || catalogItem.category !== 'avatar_frame') {
      throw new BadRequestException('Moldura inválida.');
    }
    const priceGold = catalogItem.priceGold;

    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      throw new BadRequestException('Serviço indisponível no momento.');
    }

    return sequelize.transaction(async (transaction) => {
      const user = await this.userModel.findByPk(userId, {
        attributes: ['id', 'equippedAvatarFrameId', 'purchasedAvatarFrameIds'],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });

      if (!user) {
        throw new BadRequestException('Usuário não encontrado.');
      }

      const purchased = await this.syncUserPurchasedAvatarFrames(user, transaction);

      if (purchased.has(normalizedFrameId)) {
        if (user.equippedAvatarFrameId !== normalizedFrameId) {
          await user.update({ equippedAvatarFrameId: normalizedFrameId }, { transaction });
        }

        const wallet = await this.getWalletSnapshot(userId, transaction);
        return {
          message: 'Moldura equipada.',
          profile: {
            equippedAvatarFrameId: normalizedFrameId,
            purchasedAvatarFrameIds: Array.from(purchased).sort(),
          },
          summary: {
            gold: wallet.gold,
            xp: wallet.xp,
            goldLifetimeEarned: wallet.goldLifetimeEarned,
            goldLifetimeSpent: wallet.goldLifetimeSpent,
            xpLifetimeEarned: wallet.xpLifetimeEarned,
            xpLifetimeSpent: wallet.xpLifetimeSpent,
          },
        };
      }

      const currentGold = await this.getBalanceByCurrency(userId, 'gold', transaction);
      if (currentGold < priceGold) {
        throw new BadRequestException('Ouro insuficiente para comprar essa moldura.');
      }

      await this.userCurrencyTransactionModel.create(
        {
          userId,
          currency: 'gold',
          amountSigned: -priceGold,
          type: 'debit',
          sourceType: 'avatar_frame_purchase',
          sourceId: normalizedFrameId,
          referenceKey: `avatar_frame_purchase:${normalizedFrameId}`,
          metadata: {
            frameId: normalizedFrameId,
            priceGold,
          },
        },
        { transaction },
      );

      purchased.add(normalizedFrameId);
      await user.update(
        {
          purchasedAvatarFrameIds: Array.from(purchased).sort(),
          equippedAvatarFrameId: normalizedFrameId,
        },
        { transaction },
      );

      const wallet = await this.getWalletSnapshot(userId, transaction);
      return {
        message: 'Moldura comprada e equipada.',
        profile: {
          equippedAvatarFrameId: normalizedFrameId,
          purchasedAvatarFrameIds: Array.from(purchased).sort(),
        },
        summary: {
          gold: wallet.gold,
          xp: wallet.xp,
          goldLifetimeEarned: wallet.goldLifetimeEarned,
          goldLifetimeSpent: wallet.goldLifetimeSpent,
          xpLifetimeEarned: wallet.xpLifetimeEarned,
          xpLifetimeSpent: wallet.xpLifetimeSpent,
        },
      };
    });
  }

  async purchaseAvatarBackground(userId: string, backgroundId: string) {
    const normalizedBackgroundId = backgroundId.trim();
    const catalogItem = await this.storeCatalogService.findActiveByKey(
      normalizedBackgroundId,
    );
    if (!catalogItem || catalogItem.category !== 'avatar_background') {
      throw new BadRequestException('Fundo inválido.');
    }
    const priceGold = catalogItem.priceGold;

    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      throw new BadRequestException('Serviço indisponível no momento.');
    }

    return sequelize.transaction(async (transaction) => {
      const user = await this.userModel.findByPk(userId, {
        attributes: ['id', 'equippedAvatarBackgroundId', 'purchasedAvatarBackgroundIds'],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });

      if (!user) {
        throw new BadRequestException('Usuário não encontrado.');
      }

      const purchased = await this.syncUserPurchasedAvatarBackgrounds(user, transaction);

      if (purchased.has(normalizedBackgroundId)) {
        if (user.equippedAvatarBackgroundId !== normalizedBackgroundId) {
          await user.update({ equippedAvatarBackgroundId: normalizedBackgroundId }, { transaction });
        }

        const wallet = await this.getWalletSnapshot(userId, transaction);
        return {
          message: 'Fundo equipado.',
          profile: {
            equippedAvatarBackgroundId: normalizedBackgroundId,
            purchasedAvatarBackgroundIds: Array.from(purchased).sort(),
          },
          summary: {
            gold: wallet.gold,
            xp: wallet.xp,
            goldLifetimeEarned: wallet.goldLifetimeEarned,
            goldLifetimeSpent: wallet.goldLifetimeSpent,
            xpLifetimeEarned: wallet.xpLifetimeEarned,
            xpLifetimeSpent: wallet.xpLifetimeSpent,
          },
        };
      }

      const currentGold = await this.getBalanceByCurrency(userId, 'gold', transaction);
      if (currentGold < priceGold) {
        throw new BadRequestException('Ouro insuficiente para comprar esse fundo.');
      }

      await this.userCurrencyTransactionModel.create(
        {
          userId,
          currency: 'gold',
          amountSigned: -priceGold,
          type: 'debit',
          sourceType: 'avatar_background_purchase',
          sourceId: normalizedBackgroundId,
          referenceKey: `avatar_background_purchase:${normalizedBackgroundId}`,
          metadata: {
            backgroundId: normalizedBackgroundId,
            priceGold,
          },
        },
        { transaction },
      );

      purchased.add(normalizedBackgroundId);
      await user.update(
        {
          purchasedAvatarBackgroundIds: Array.from(purchased).sort(),
          equippedAvatarBackgroundId: normalizedBackgroundId,
        },
        { transaction },
      );

      const wallet = await this.getWalletSnapshot(userId, transaction);
      return {
        message: 'Fundo comprado e equipado.',
        profile: {
          equippedAvatarBackgroundId: normalizedBackgroundId,
          purchasedAvatarBackgroundIds: Array.from(purchased).sort(),
        },
        summary: {
          gold: wallet.gold,
          xp: wallet.xp,
          goldLifetimeEarned: wallet.goldLifetimeEarned,
          goldLifetimeSpent: wallet.goldLifetimeSpent,
          xpLifetimeEarned: wallet.xpLifetimeEarned,
          xpLifetimeSpent: wallet.xpLifetimeSpent,
        },
      };
    });
  }

  async purchaseOffensiveBlocker(userId: string, blockerId: string, quantity = 1) {
    const normalizedBlockerId = blockerId.trim();
    if (normalizedBlockerId !== OFFENSIVE_BLOCKER_DEFAULT_ID) {
      throw new BadRequestException('Bloqueador inválido.');
    }

    const blockerCatalogItem = await this.storeCatalogService.findActiveByKey(
      normalizedBlockerId,
    );
    if (!blockerCatalogItem || blockerCatalogItem.category !== 'offensive_blocker') {
      throw new BadRequestException('Bloqueador inválido.');
    }
    const blockerPriceGold = blockerCatalogItem.priceGold;

    let normalizedQuantity = Number.isFinite(quantity) ? Math.floor(quantity) : 1;
    if (normalizedQuantity <= 0) {
      throw new BadRequestException('Quantidade inválida para compra de bloqueador.');
    }
    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      throw new BadRequestException('Serviço indisponível no momento.');
    }

    return sequelize.transaction(async (transaction) => {
      const user = await this.userModel.findByPk(userId, {
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
        throw new BadRequestException('Usuário não encontrado.');
      }

      const currentInventory = Math.max(0, parseNumber(user.offensiveBlockerInventoryCount));
      const currentGold = await this.getBalanceByCurrency(userId, 'gold', transaction);
      const blockerRecovery = await this.buildBlockerRecoverySummary({
        userId,
        inventoryCount: currentInventory,
        currentGold,
        transaction,
      });

      if (blockerRecovery.requiredPurchaseQuantity > 0) {
        if (!blockerRecovery.canAffordRecoveryPurchase) {
          throw new BadRequestException(
            `Você precisa de ${blockerRecovery.requiredPurchaseQuantity} bloqueadores para recuperar sua sequência até hoje (custo: ${blockerRecovery.requiredPurchaseCostGold} ouro).`,
          );
        }
        normalizedQuantity = blockerRecovery.requiredPurchaseQuantity;
      }

      const totalPriceGold = normalizedQuantity * blockerPriceGold;

      if (currentGold < totalPriceGold) {
        throw new BadRequestException('Ouro insuficiente para comprar bloqueadores.');
      }

      await this.userCurrencyTransactionModel.create(
        {
          userId,
          currency: 'gold',
          amountSigned: -totalPriceGold,
          type: 'debit',
          sourceType: 'offensive_blocker_purchase',
          sourceId: normalizedBlockerId,
          referenceKey: null,
          metadata: {
            blockerId: normalizedBlockerId,
            quantity: normalizedQuantity,
            priceGoldPerUnit: blockerPriceGold,
            totalPriceGold,
          },
        },
        { transaction },
      );

      const nextInventoryRaw = currentInventory + normalizedQuantity;
      const now = new Date();
      const todayStart = this.streakService.getDayStartInAppTimeZone(now);
      const appliedKeys = new Set(
        this.normalizeIdList(user.streakBlockerAppliedDayKeys).filter((key) =>
          /^\d{4}-\d{2}-\d{2}$/.test(key),
        ),
      );
      const mealDayKeys = await this.getMealDayKeysUntilNow(userId, now, transaction);
      const missingDayKeys = this.buildTrailingMissingDayKeys(
        mealDayKeys,
        appliedKeys,
        todayStart,
      );

      let nextInventory = nextInventoryRaw;
      if (missingDayKeys.length > 0 && nextInventoryRaw >= missingDayKeys.length) {
        for (const key of missingDayKeys) {
          appliedKeys.add(key);
        }
        nextInventory = nextInventoryRaw - missingDayKeys.length;
      }

      await user.update(
        {
          offensiveBlockerInventoryCount: nextInventory,
          equippedOffensiveBlockerId:
            this.normalizeOptionalId(user.equippedOffensiveBlockerId) ??
            OFFENSIVE_BLOCKER_DEFAULT_ID,
          streakBlockerAppliedDayKeys: Array.from(appliedKeys).sort(),
        },
        { transaction },
      );

      const wallet = await this.getWalletSnapshot(userId, transaction);
      return {
        message: `Bloqueador${normalizedQuantity > 1 ? 'es' : ''} comprado${
          normalizedQuantity > 1 ? 's' : ''
        } com sucesso.`,
        profile: {
          equippedOffensiveBlockerId:
            this.normalizeOptionalId(user.equippedOffensiveBlockerId) ??
            OFFENSIVE_BLOCKER_DEFAULT_ID,
          offensiveBlockerInventoryCount: nextInventory,
        },
        summary: {
          gold: wallet.gold,
          xp: wallet.xp,
          goldLifetimeEarned: wallet.goldLifetimeEarned,
          goldLifetimeSpent: wallet.goldLifetimeSpent,
          xpLifetimeEarned: wallet.xpLifetimeEarned,
          xpLifetimeSpent: wallet.xpLifetimeSpent,
        },
      };
    });
  }

  async getGoldStatement(userId: string) {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: {
        userId,
        currency: 'gold',
      },
      order: [['createdAt', 'DESC']],
      limit: 100,
      attributes: [
        'id',
        'amountSigned',
        'type',
        'sourceType',
        'sourceId',
        'referenceKey',
        'metadata',
        'createdAt',
      ],
    });

    return {
      currency: 'gold',
      transactions: rows.map((row) => ({
        id: row.id,
        amountSigned: parseNumber(row.amountSigned),
        type: row.type,
        sourceType: row.sourceType,
        sourceId: row.sourceId,
        referenceKey: row.referenceKey,
        metadata: row.metadata ?? null,
        createdAt: row.createdAt,
      })),
    };
  }

  private sectionOrder(): Array<{ id: MissionType; title: string; subtitle: string }> {
    return [
      {
        id: 'daily',
        title: 'Missões diárias',
        subtitle: 'Renovam à meia-noite',
      },
      {
        id: 'weekly',
        title: 'Missões semanais',
        subtitle: 'Renovam toda segunda-feira',
      },
      {
        id: 'monthly',
        title: 'Desafios do mês',
        subtitle: 'Renovam no início de cada mês',
      },
    ];
  }

  private collectDayTotalsInRange(
    totalsByDay: Map<string, DailyTotals>,
    start: Date,
    end: Date,
  ): DailyTotals[] {
    const entries: DailyTotals[] = [];
    const cursor = new Date(start);

    while (cursor <= end) {
      const value = totalsByDay.get(this.streakService.toDayKeyInAppTimeZone(cursor));
      if (value && value.meals > 0) {
        entries.push(value);
      }

      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }

    return entries;
  }

  private calculateConsecutiveDays(
    totalsByDay: Map<string, DailyTotals>,
    rangeStart: Date,
    rangeEnd: Date,
  ): number {
    let streak = 0;
    const cursor = new Date(rangeEnd);

    while (cursor >= rangeStart) {
      const totals = totalsByDay.get(this.streakService.toDayKeyInAppTimeZone(cursor));
      if (!totals || totals.meals <= 0) {
        break;
      }

      streak += 1;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }

    return streak;
  }

  private async awardMissionCompletions(
    userId: string,
    completedMissions: MissionItemPayload[],
    referenceDate: Date,
  ) {
    if (completedMissions.length === 0) {
      return;
    }

    const transactions: Array<{
      userId: string;
      currency: CurrencyCode;
      amountSigned: number;
      type: 'credit';
      sourceType: 'mission_reward';
      sourceId: string;
      referenceKey: string;
      metadata: Record<string, unknown>;
    }> = [];

    for (const mission of completedMissions) {
      const periodKey = this.buildMissionPeriodKey(mission.type, referenceDate);
      const referenceKey = `mission_reward:${mission.key}:${periodKey}`;
      const sourceId = mission.key;

      if (parseNumber(mission.rewardGold) > 0) {
        transactions.push({
          userId,
          currency: 'gold',
          amountSigned: parseNumber(mission.rewardGold),
          type: 'credit',
          sourceType: 'mission_reward',
          sourceId,
          referenceKey,
          metadata: {
            missionId: mission.id,
            missionKey: mission.key,
            missionType: mission.type,
            periodKey,
          },
        });
      }

      if (parseNumber(mission.rewardXp) > 0) {
        transactions.push({
          userId,
          currency: 'xp',
          amountSigned: parseNumber(mission.rewardXp),
          type: 'credit',
          sourceType: 'mission_reward',
          sourceId,
          referenceKey,
          metadata: {
            missionId: mission.id,
            missionKey: mission.key,
            missionType: mission.type,
            periodKey,
          },
        });
      }
    }

    if (transactions.length === 0) {
      return;
    }

    await this.userCurrencyTransactionModel.bulkCreate(transactions, {
      ignoreDuplicates: true,
    });
  }

  private buildMissionPeriodKey(missionType: MissionType, referenceDate: Date): string {
    if (missionType === 'daily') {
      return this.streakService.toDayKeyInAppTimeZone(referenceDate);
    }

    if (missionType === 'weekly') {
      const weekStart = this.streakService.getWeekStartInAppTimeZone(referenceDate);
      return this.streakService.toDayKeyInAppTimeZone(weekStart);
    }

    const parts = this.streakService.getDatePartsInAppTimeZone(referenceDate);
    return `${parts.year}-${String(parts.month).padStart(2, '0')}`;
  }

  private normalizeIdList(rawList: unknown): string[] {
    if (!Array.isArray(rawList)) {
      return [];
    }

    return rawList
      .map((value) => value?.toString().trim() ?? '')
      .filter((value) => value.length > 0);
  }

  private async ensurePurchasedAvatarFramesSynced(userId: string): Promise<void> {
    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      return;
    }

    await sequelize.transaction(async (transaction) => {
      const user = await this.userModel.findByPk(userId, {
        attributes: ['id', 'equippedAvatarFrameId', 'purchasedAvatarFrameIds'],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });

      if (!user) {
        return;
      }

      await this.syncUserPurchasedAvatarFrames(user, transaction);
    });
  }

  private async ensurePurchasedAvatarBackgroundsSynced(userId: string): Promise<void> {
    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      return;
    }

    await sequelize.transaction(async (transaction) => {
      const user = await this.userModel.findByPk(userId, {
        attributes: ['id', 'equippedAvatarBackgroundId', 'purchasedAvatarBackgroundIds'],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });

      if (!user) {
        return;
      }

      await this.syncUserPurchasedAvatarBackgrounds(user, transaction);
    });
  }

  private async loadPurchasedAvatarFrameIdsFromTransactions(
    userId: string,
    transaction?: Transaction,
  ): Promise<string[]> {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: {
        userId,
        currency: 'gold',
        sourceType: 'avatar_frame_purchase',
      },
      attributes: ['sourceId'],
      transaction,
    });
    const activeKeys = new Set(await this.storeCatalogService.listActiveFrameKeys());

    return rows
      .map((row) => row.sourceId?.trim() ?? '')
      .filter((id) => id.length > 0 && activeKeys.has(id));
  }

  private buildPurchasedAvatarFrameSet(
    storedIds: unknown,
    transactionOwnedIds: string[],
  ): Set<string> {
    const purchased = new Set(this.normalizeIdList(storedIds));

    for (const id of transactionOwnedIds) {
      purchased.add(id);
    }

    return purchased;
  }

  private async syncUserPurchasedAvatarFrames(
    user: User,
    transaction?: Transaction,
  ): Promise<Set<string>> {
    const transactionOwnedIds = await this.loadPurchasedAvatarFrameIdsFromTransactions(
      user.id,
      transaction,
    );
    const purchased = this.buildPurchasedAvatarFrameSet(
      user.purchasedAvatarFrameIds,
      transactionOwnedIds,
    );
    const equippedId = this.normalizeOptionalId(user.equippedAvatarFrameId);
    const sanitizedEquipped =
      equippedId && purchased.has(equippedId) ? equippedId : null;
    const sortedPurchased = Array.from(purchased).sort();
    const storedPurchased = this.normalizeIdList(user.purchasedAvatarFrameIds).sort();
    const needsUpdate =
      sortedPurchased.join(',') !== storedPurchased.join(',') ||
      sanitizedEquipped !== equippedId;

    if (needsUpdate) {
      await user.update(
        {
          purchasedAvatarFrameIds: sortedPurchased,
          equippedAvatarFrameId: sanitizedEquipped,
        },
        { transaction },
      );
      user.purchasedAvatarFrameIds = sortedPurchased;
      user.equippedAvatarFrameId = sanitizedEquipped;
    }

    return purchased;
  }

  private async loadPurchasedAvatarBackgroundIdsFromTransactions(
    userId: string,
    transaction?: Transaction,
  ): Promise<string[]> {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: {
        userId,
        currency: 'gold',
        sourceType: 'avatar_background_purchase',
      },
      attributes: ['sourceId'],
      transaction,
    });
    const activeKeys = new Set(
      await this.storeCatalogService.listActiveBackgroundKeys(),
    );

    return rows
      .map((row) => row.sourceId?.trim() ?? '')
      .filter((id) => id.length > 0 && activeKeys.has(id));
  }

  private buildPurchasedAvatarBackgroundSet(
    storedIds: unknown,
    transactionOwnedIds: string[],
  ): Set<string> {
    const purchased = new Set(this.normalizeIdList(storedIds));

    for (const id of transactionOwnedIds) {
      purchased.add(id);
    }

    return purchased;
  }

  private async syncUserPurchasedAvatarBackgrounds(
    user: User,
    transaction?: Transaction,
  ): Promise<Set<string>> {
    const transactionOwnedIds = await this.loadPurchasedAvatarBackgroundIdsFromTransactions(
      user.id,
      transaction,
    );
    const purchased = this.buildPurchasedAvatarBackgroundSet(
      user.purchasedAvatarBackgroundIds,
      transactionOwnedIds,
    );
    const equippedId = this.normalizeOptionalId(user.equippedAvatarBackgroundId);
    const sanitizedEquipped =
      equippedId && purchased.has(equippedId) ? equippedId : null;
    const sortedPurchased = Array.from(purchased).sort();
    const storedPurchased = this.normalizeIdList(user.purchasedAvatarBackgroundIds).sort();
    const needsUpdate =
      sortedPurchased.join(',') !== storedPurchased.join(',') ||
      sanitizedEquipped !== equippedId;

    if (needsUpdate) {
      await user.update(
        {
          purchasedAvatarBackgroundIds: sortedPurchased,
          equippedAvatarBackgroundId: sanitizedEquipped,
        },
        { transaction },
      );
      user.purchasedAvatarBackgroundIds = sortedPurchased;
      user.equippedAvatarBackgroundId = sanitizedEquipped;
    }

    return purchased;
  }

  private normalizeOptionalId(value: unknown): string | null {
    if (typeof value !== 'string') {
      return null;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : null;
  }

  private async buildBlockerRecoverySummary({
    userId,
    inventoryCount,
    currentGold,
    transaction,
  }: {
    userId: string;
    inventoryCount: number;
    currentGold: number;
    transaction?: Transaction;
  }): Promise<BlockerRecoverySummary> {
    const now = new Date();
    const todayStart = this.streakService.getDayStartInAppTimeZone(now);
    const user = await this.userModel.findByPk(userId, {
      attributes: ['streakBlockerAppliedDayKeys'],
      transaction,
    });
    const appliedKeys = new Set(
      this.normalizeIdList(user?.streakBlockerAppliedDayKeys).filter((key) =>
        /^\d{4}-\d{2}-\d{2}$/.test(key),
      ),
    );
    const mealDayKeys = await this.getMealDayKeysUntilNow(userId, now, transaction);
    const missingDayKeys = this.buildTrailingMissingDayKeys(
      mealDayKeys,
      appliedKeys,
      todayStart,
    );

    const missingDays = missingDayKeys.length;
    const requiredPurchaseQuantity = Math.max(0, missingDays - inventoryCount);
    const blockerPriceGold =
      (await this.storeCatalogService.getActivePriceGold(OFFENSIVE_BLOCKER_DEFAULT_ID)) ??
      0;
    const requiredPurchaseCostGold = requiredPurchaseQuantity * blockerPriceGold;

    return {
      missingDaysUntilToday: missingDays,
      requiredBlockersTotal: missingDays,
      inventoryAvailable: inventoryCount,
      requiredPurchaseQuantity,
      requiredPurchaseCostGold,
      canAffordRecoveryPurchase: currentGold >= requiredPurchaseCostGold,
    };
  }

  private async getMealDayKeysUntilNow(
    userId: string,
    now: Date,
    transaction?: Transaction,
  ): Promise<Set<string>> {
    const meals = await this.mealModel.findAll({
      where: {
        userId,
        status: MealStatus.Active,
        createdAt: { [Op.lte]: now },
      },
      attributes: ['createdAt'],
      transaction,
    });

    const mealDayKeys = new Set<string>();
    for (const meal of meals) {
      mealDayKeys.add(this.streakService.toDayKeyInAppTimeZone(new Date(meal.createdAt)));
    }

    return mealDayKeys;
  }

  private buildTrailingMissingDayKeys(
    mealDayKeys: Set<string>,
    appliedDayKeys: Set<string>,
    todayStart: Date,
  ): string[] {
    const anchors = new Set<string>(mealDayKeys);
    for (const key of appliedDayKeys) {
      anchors.add(key);
    }

    if (anchors.size === 0) {
      return [];
    }

    let latestAnchorDate: Date | null = null;
    for (const key of anchors) {
      const parsed = this.dayKeyToDate(key);
      if (!parsed || parsed > todayStart) {
        continue;
      }

      if (!latestAnchorDate || parsed > latestAnchorDate) {
        latestAnchorDate = parsed;
      }
    }

    if (!latestAnchorDate || latestAnchorDate >= todayStart) {
      return [];
    }

    const missing: string[] = [];
    const cursor = new Date(latestAnchorDate);
    cursor.setUTCDate(cursor.getUTCDate() + 1);
    while (cursor <= todayStart) {
      missing.push(this.streakService.toDayKeyInAppTimeZone(cursor));
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }

    return missing;
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

  private async getWalletSnapshot(userId: string, transaction?: Transaction): Promise<WalletSnapshot> {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: { userId },
      attributes: ['currency', 'amountSigned'],
      transaction,
    });

    let gold = 0;
    let xp = 0;
    let goldLifetimeEarned = 0;
    let goldLifetimeSpent = 0;
    let xpLifetimeEarned = 0;
    let xpLifetimeSpent = 0;

    for (const row of rows) {
      const amount = parseNumber(row.amountSigned);
      if (row.currency === 'gold') {
        gold += amount;
        if (amount > 0) {
          goldLifetimeEarned += amount;
        } else if (amount < 0) {
          goldLifetimeSpent += Math.abs(amount);
        }
      } else if (row.currency === 'xp') {
        xp += amount;
        if (amount > 0) {
          xpLifetimeEarned += amount;
        } else if (amount < 0) {
          xpLifetimeSpent += Math.abs(amount);
        }
      }
    }

    return {
      gold,
      xp,
      goldLifetimeEarned,
      goldLifetimeSpent,
      xpLifetimeEarned,
      xpLifetimeSpent,
    };
  }

  private async getBalanceByCurrency(
    userId: string,
    currency: CurrencyCode,
    transaction?: Transaction,
  ): Promise<number> {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: { userId, currency },
      attributes: ['amountSigned'],
      transaction,
    });

    return rows.reduce((sum, row) => sum + parseNumber(row.amountSigned), 0);
  }
}
