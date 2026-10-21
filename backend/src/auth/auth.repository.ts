import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op, WhereOptions } from 'sequelize';
import { User } from './models/user.model';
import { UserWeightEntry } from '../performance/models/user-weight-entry.model';

@Injectable()
export class AuthRepository {
  constructor(
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(UserWeightEntry)
    private readonly userWeightEntryModel: typeof UserWeightEntry,
  ) {}

  findByEmail(email: string) {
    return this.userModel.findOne({
      where: { email: email.toLowerCase() },
      attributes: [
        'id',
        'name',
        'email',
        'passwordHash',
        'emailVerified',
      ],
    });
  }

  findByEmailFull(email: string) {
    return this.userModel.findOne({
      where: { email: email.toLowerCase() },
      attributes: [
        'id',
        'name',
        'email',
        'passwordHash',
        'emailVerified',
        'verificationCode',
        'verificationCodeExpiresAt',
      ],
    });
  }

  createUser(data: {
    name: string | null;
    email: string;
    passwordHash: string;
    verificationCode: string;
    verificationCodeExpiresAt: Date;
    termsAcceptedAt?: Date | null;
    privacyAcceptedAt?: Date | null;
    termsVersion?: string | null;
    privacyVersion?: string | null;
  }) {
    return this.userModel.create({
      ...data,
      email: data.email.toLowerCase(),
    });
  }

  createGoogleUser(data: {
    name: string | null;
    email: string;
    passwordHash: string;
    termsAcceptedAt?: Date | null;
    privacyAcceptedAt?: Date | null;
    termsVersion?: string | null;
    privacyVersion?: string | null;
  }) {
    return this.userModel.create({
      ...data,
      email: data.email.toLowerCase(),
      emailVerified: true,
      verificationCode: null,
      verificationCodeExpiresAt: null,
    });
  }

  stampLegalAcceptance(
    userId: string,
    data: {
      termsAcceptedAt: Date;
      privacyAcceptedAt: Date;
      termsVersion: string;
      privacyVersion: string;
    },
  ) {
    return this.userModel.update(data, { where: { id: userId } });
  }

  findByEmailAndValidVerificationCode(email: string, code: string) {
    const where: WhereOptions<User> = {
      email: email.toLowerCase(),
      verificationCode: code,
      verificationCodeExpiresAt: { [Op.gt]: new Date() },
    };

    return this.userModel.findOne({
      where,
      attributes: ['id', 'email'],
    });
  }

  findByEmailWithPassword(email: string) {
    return this.userModel.findOne({
      where: { email: email.toLowerCase() },
      attributes: [
        'id',
        'name',
        'email',
        'passwordHash',
        'emailVerified',
        'verificationCode',
        'verificationCodeExpiresAt',
      ],
    });
  }

  updateVerification(user: User, data: {
    emailVerified?: boolean;
    verificationCode?: string | null;
    verificationCodeExpiresAt?: Date | null;
  }) {
    return user.update(data);
  }

  findByEmailAndValidPasswordResetCode(email: string, code: string) {
    const where: WhereOptions<User> = {
      email: email.toLowerCase(),
      verificationCode: code,
      verificationCodeExpiresAt: { [Op.gt]: new Date() },
    };

    return this.userModel.findOne({
      where,
      attributes: [
        'id',
        'name',
        'email',
        'passwordHash',
        'emailVerified',
        'verificationCode',
        'verificationCodeExpiresAt',
      ],
    });
  }

  async updatePasswordAndClearResetCode(user: User, passwordHash: string) {
    await user.update({
      passwordHash,
      verificationCode: null,
      verificationCodeExpiresAt: null,
    });

    return this.userModel.findByPk(user.id, {
      attributes: ['id', 'email'],
    });
  }

  findProfileById(userId: string) {
    return this.userModel.findByPk(userId, {
      attributes: [
        'id',
        'name',
        'email',
        'dailyCalorieGoal',
        'dailyProteinGoal',
        'dailyCarbsGoal',
        'dailyFatGoal',
        'birthDate',
        'weight',
        'height',
        'weightUnit',
        'heightUnit',
        'sex',
        'objective',
        'activityLevel',
        'avatarUrl',
        'equippedAvatarFrameId',
        'purchasedAvatarFrameIds',
        'equippedAvatarBackgroundId',
        'purchasedAvatarBackgroundIds',
        'purchasedJacaEmojiIds',
        'equippedProfileReactionEmojiId',
        'equippedOffensiveBlockerId',
        'offensiveBlockerInventoryCount',
        'streakBlockerAppliedDayKeys',
        'homeProductTourCompleted',
        'hideMissionsGuideMe',
        'hideSocialGuideMe',
        'hideGuideMe',
        'hidePublicProfileMeals',
        'hidePublicProfileWorkouts',
        'termsAcceptedAt',
        'privacyAcceptedAt',
        'termsVersion',
        'privacyVersion',
        'analyticsOptOut',
        'createdAt',
        'updatedAt',
      ],
    });
  }

  async deleteAccountCompletely(userId: string): Promise<void> {
    const sequelize = this.userModel.sequelize;
    if (!sequelize) {
      throw new Error('Sequelize nao inicializado');
    }

    await sequelize.transaction(async (transaction) => {
      const run = (sql: string) =>
        sequelize.query(sql, {
          replacements: { userId },
          transaction,
        });

      await run(
        `DELETE FROM social_group_message_reactions WHERE user_id = :userId`,
      );
      await run(`DELETE FROM social_group_messages WHERE user_id = :userId`);
      await run(`DELETE FROM social_group_members WHERE user_id = :userId`);
      await run(`DELETE FROM social_group_activities WHERE user_id = :userId`);
      await run(`DELETE FROM social_groups WHERE owner_id = :userId`);
      await run(
        `DELETE FROM social_friend_requests
         WHERE requester_id = :userId OR recipient_id = :userId`,
      );
      await run(
        `DELETE FROM social_friendships
         WHERE user_low_id = :userId OR user_high_id = :userId`,
      );
      await run(`DELETE FROM social_friend_links WHERE user_id = :userId`);
      await run(
        `DELETE FROM social_user_blocks
         WHERE blocker_id = :userId OR blocked_id = :userId`,
      );
      await run(`DELETE FROM social_content_reports WHERE reporter_id = :userId`);
      await run(
        `UPDATE social_content_reports
         SET target_user_id = NULL
         WHERE target_user_id = :userId`,
      );
      await run(`DELETE FROM workout_load_entries WHERE user_id = :userId`);
      await run(`DELETE FROM workout_exercises WHERE user_id = :userId`);
      await run(`DELETE FROM workout_routines WHERE user_id = :userId`);
      await run(`DELETE FROM water_intake_entries WHERE user_id = :userId`);
      await run(`DELETE FROM user_weight_entries WHERE user_id = :userId`);
      await run(`DELETE FROM meal_templates WHERE user_id = :userId`);
      await run(`DELETE FROM meals WHERE user_id = :userId`);
      await run(`DELETE FROM user_missions WHERE user_id = :userId`);
      await run(`DELETE FROM store_purchases WHERE user_id = :userId`);
      await run(
        `DELETE FROM user_currency_transactions WHERE user_id = :userId`,
      );
      await run(`DELETE FROM analytics_events WHERE user_id = :userId`);
      await run(
        `UPDATE support_messages
         SET user_id = NULL, email = NULL
         WHERE user_id = :userId`,
      );
      await run(`DELETE FROM users WHERE id = :userId`);
    });
  }

  async updateProfile(userId: string, data: any) {
    const user = await this.userModel.findByPk(userId);
    if (!user) return null;

    const logWeightEntry = data?.logWeightEntry === true;
    const profileData = { ...data };
    delete profileData.logWeightEntry;

    const previousWeight = this.toNumber(user.weight);
    const nextWeight =
      this.toNumber(profileData.weight) ?? (logWeightEntry ? previousWeight : null);

    await user.update(profileData);

    if (
      Number.isFinite(nextWeight) &&
      nextWeight > 0 &&
      (logWeightEntry || previousWeight === null || previousWeight !== nextWeight)
    ) {
      await this.userWeightEntryModel.create({
        userId,
        weight: nextWeight,
        recordedAt: new Date(),
      });
    }

    return this.findProfileById(userId);
  }

  private toNumber(value: unknown): number | null {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : null;
    }

    if (typeof value === 'string') {
      const parsed = Number(value.replace(',', '.'));
      return Number.isFinite(parsed) ? parsed : null;
    }

    return null;
  }
}
