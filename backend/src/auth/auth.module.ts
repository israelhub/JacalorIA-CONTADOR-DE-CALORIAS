import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { SequelizeModule } from '@nestjs/sequelize';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthRepository } from './auth.repository';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { OptionalJwtAuthGuard } from './guards/optional-jwt-auth.guard';
import { User } from './models/user.model';
import { MailModule } from '../mail/mail.module';
import { UserWeightEntry } from '../performance/models/user-weight-entry.model';
import { SocialFriendship } from '../social/models/social-friendship.model';
import { UserCurrencyTransaction } from '../missions/models/user-currency-transaction.model';
import { Meal } from '../meals/models/meal.model';
import { StreakModule } from '../streak/streak.module';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET')!,
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRATION', '7d') as any,
        },
      }),
    }),
    SequelizeModule.forFeature([
      User,
      UserWeightEntry,
      SocialFriendship,
      UserCurrencyTransaction,
      Meal,
    ]),
    StreakModule,
    MailModule,
  ],
  controllers: [AuthController],
  providers: [AuthRepository, AuthService, JwtStrategy, OptionalJwtAuthGuard],
  exports: [AuthService, OptionalJwtAuthGuard, PassportModule, JwtModule],
})
export class AuthModule {}
