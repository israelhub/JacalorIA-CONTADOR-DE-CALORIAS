import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import { json, urlencoded, static as expressStatic } from 'express';
import { existsSync } from 'fs';
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

  // Dashboard beta: GET /beta e /beta/* (fora do prefixo /api)
  const betaDir = join(process.cwd(), 'public', 'beta');
  if (existsSync(betaDir)) {
    const httpAdapter = app.getHttpAdapter().getInstance();
    // Express trata /beta e /beta/ iguais no get(); so match by raw URL.
    httpAdapter.use(
      (
        req: { method?: string; url?: string },
        res: { redirect: (code: number, url: string) => void },
        next: () => void,
      ) => {
        const pathOnly = (req.url ?? '').split('?')[0];
        if (req.method === 'GET' && pathOnly === '/beta') {
          res.redirect(301, '/beta/');
          return;
        }
        next();
      },
    );
    app.use(
      '/beta/',
      expressStatic(betaDir, {
        index: 'index.html',
        redirect: false,
        fallthrough: false,
      }),
    );
  } else {
    console.warn(`Dashboard beta: pasta nao encontrada em ${betaDir}`);
  }

  app.setGlobalPrefix('api');

  const port = configService.get<number>('PORT', 3000);
  await app.listen(port);
  console.log(`Backend rodando em http://localhost:${port}/api`);
  console.log(`Dashboard beta: http://localhost:${port}/beta/`);
}
bootstrap();
