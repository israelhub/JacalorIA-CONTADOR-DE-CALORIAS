import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import { json, urlencoded } from 'express';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  const configService = app.get(ConfigService);
  const bodyLimit = configService.get<string>('BODY_LIMIT', '10mb');

  app.use(json({ limit: bodyLimit }));
  app.use(urlencoded({ extended: true, limit: bodyLimit }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const corsOrigin = configService.get<string>('CORS_ORIGIN', '*');
  const allowedOrigins = corsOrigin
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin || corsOrigin === '*') {
        callback(null, true);
        return;
      }

      const isConfiguredOrigin = allowedOrigins.includes(origin);
      const isLocalDevOrigin = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(
        origin,
      );

      callback(null, isConfiguredOrigin || isLocalDevOrigin);
    },
    credentials: true,
  });

  // Dashboard estático em /beta (fora do prefixo /api)
  app.useStaticAssets(join(process.cwd(), 'public'), {
    index: false,
  });

  app.setGlobalPrefix('api');

  const port = configService.get<number>('PORT', 3000);
  await app.listen(port);
  console.log(`Backend rodando em http://localhost:${port}/api`);
  console.log(`Dashboard beta: http://localhost:${port}/beta/`);
}
bootstrap();
