import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { ConfigService } from '@nestjs/config';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { UserWeightEntry } from '../performance/models/user-weight-entry.model';
import { Mission } from '../missions/models/mission.model';
import { UserCurrencyTransaction } from '../missions/models/user-currency-transaction.model';
import { SocialFriendLink } from '../social/models/social-friend-link.model';
import { SocialFriendRequest } from '../social/models/social-friend-request.model';
import { SocialFriendship } from '../social/models/social-friendship.model';
import { SocialGroup } from '../social/models/social-group.model';
import { SocialGroupActivity } from '../social/models/social-group-activity.model';
import { SocialGroupMember } from '../social/models/social-group-member.model';

@Module({
  imports: [
    SequelizeModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const databaseUrl = configService.get<string>('DATABASE_URL');
        const dbHost = configService.get<string>('DB_HOST');
        const dbPort = Number(configService.get<string>('DB_PORT', '5432'));
        const dbUser = configService.get<string>('DB_USER');
        const dbPassword = configService.get<string>('DB_PASSWORD');
        const dbName = configService.get<string>('DB_NAME');
        const nodeEnv = configService.get<string>('NODE_ENV', 'development');
        const isDev = nodeEnv === 'development';
        const isProd = nodeEnv === 'production';
        const isHml = nodeEnv === 'homologation';
        const useDatabaseUrl = !!databaseUrl?.trim();

        const needsSsl =
          isProd ||
          isHml ||
          !!databaseUrl?.includes('supabase') ||
          !!dbHost?.includes('supabase');

        return {
          dialect: 'postgres',
          ...(useDatabaseUrl
            ? {
                uri: databaseUrl,
              }
            : dbHost && dbUser && dbName
            ? {
                host: dbHost,
                port: dbPort,
                username: dbUser,
                password: dbPassword,
                database: dbName,
              }
            : {
                uri: databaseUrl,
              }),
          models: [
            User,
            Meal,
            UserWeightEntry,
            Mission,
            UserCurrencyTransaction,
            SocialGroup,
            SocialGroupMember,
            SocialGroupActivity,
            SocialFriendship,
            SocialFriendLink,
            SocialFriendRequest,
          ],
          autoLoadModels: true,
          synchronize: !isProd,
          sync: { alter: isDev },
          logging: isDev ? console.log : false,
          dialectOptions: {
            ssl: needsSsl
              ? { require: true, rejectUnauthorized: false }
              : false,
          },
          pool: {
            max: isProd ? 10 : 5,
            min: isProd ? 2 : 0,
            acquire: 30000,
            idle: 10000,
          },
        };
      },
    }),
  ],
})
export class DatabaseModule {}
