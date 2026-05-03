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
  }) {
    return this.userModel.create({
      ...data,
      email: data.email.toLowerCase(),
      emailVerified: true,
      verificationCode: null,
      verificationCodeExpiresAt: null,
    });
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
        'createdAt',
        'updatedAt',
      ],
    });
  }

  async updateProfile(userId: string, data: any) {
    const user = await this.userModel.findByPk(userId);
    if (!user) return null;

    const previousWeight = this.toNumber(user.weight);
    const nextWeight = this.toNumber(data.weight);

    await user.update(data);

    if (
      Number.isFinite(nextWeight) &&
      nextWeight > 0 &&
      (previousWeight === null || previousWeight !== nextWeight)
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
