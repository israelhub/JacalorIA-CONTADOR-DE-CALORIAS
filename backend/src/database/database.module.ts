import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { ConfigService } from '@nestjs/config';
import { User } from '../auth/models/user.model';

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

        const needsSsl =
          isProd ||
          isHml ||
          !!databaseUrl?.includes('supabase') ||
          !!dbHost?.includes('supabase');

        return {
          dialect: 'postgres',
          ...(dbHost && dbUser && dbName
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
          models: [User],
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
