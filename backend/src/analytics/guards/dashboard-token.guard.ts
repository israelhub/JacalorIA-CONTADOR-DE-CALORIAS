import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class DashboardTokenGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const expected = this.configService
      .get<string>('BETA_DASHBOARD_TOKEN', '')
      .trim();

    if (!expected) {
      throw new UnauthorizedException(
        'BETA_DASHBOARD_TOKEN não configurado no servidor',
      );
    }

    const request = context.switchToHttp().getRequest();
    const headerToken =
      (request.headers['x-dashboard-token'] as string | undefined)?.trim() ??
      '';
    const queryToken =
      typeof request.query?.token === 'string'
        ? request.query.token.trim()
        : '';
    const provided = headerToken || queryToken;

    if (!provided || provided !== expected) {
      throw new UnauthorizedException('Token do dashboard inválido');
    }

    return true;
  }
}
