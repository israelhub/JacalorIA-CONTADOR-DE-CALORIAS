import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op, WhereOptions } from 'sequelize';
import { User } from './models/user.model';

@Injectable()
export class AuthRepository {
  constructor(
    @InjectModel(User)
    private readonly userModel: typeof User,
  ) {}

  findByEmail(email: string) {
    return this.userModel.findOne({
      where: { email: email.toLowerCase() },
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

  findByEmailAndValidVerificationCode(email: string, code: string) {
    const where: WhereOptions<User> = {
      email: email.toLowerCase(),
      verificationCode: code,
      verificationCodeExpiresAt: { [Op.gt]: new Date() },
    };

    return this.userModel.findOne({ where });
  }

  updateVerification(user: User, data: {
    emailVerified?: boolean;
    verificationCode?: string | null;
    verificationCodeExpiresAt?: Date | null;
  }) {
    return user.update(data);
  }

  findProfileById(userId: string) {
    return this.userModel.findByPk(userId, {
      attributes: {
        exclude: ['passwordHash', 'verificationCode', 'verificationCodeExpiresAt'],
      },
    });
  }
}