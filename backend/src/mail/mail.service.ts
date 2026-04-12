import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { buildVerificationEmailHtml } from './verification-email.template';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly configService: ConfigService) {}

  private isMailEnabled(): boolean {
    return (
      this.configService.get<string>('MAIL_ENABLED', 'false').toLowerCase() ===
      'true'
    );
  }

  private getTransporter() {
    const host = this.configService.get<string>('MAIL_HOST');
    const port = Number(this.configService.get<string>('MAIL_PORT', '587'));
    const secure =
      this.configService.get<string>('MAIL_SECURE', 'false').toLowerCase() ===
      'true';
    const user = this.configService.get<string>('MAIL_USER');
    const pass = this.configService.get<string>('MAIL_PASSWORD');

    return nodemailer.createTransport({
      host,
      port,
      secure,
      auth: user && pass ? { user, pass } : undefined,
    });
  }

  async sendVerificationCode(email: string, code: string): Promise<boolean> {
    if (!this.isMailEnabled()) {
      this.logger.warn('MAIL_ENABLED=false. Email não enviado.');
      return false;
    }

    const from = this.configService.get<string>('MAIL_FROM');
    if (!from) {
      this.logger.error('MAIL_FROM não configurado.');
      return false;
    }

    try {
      const transporter = this.getTransporter();
      const logoPath = path.resolve(
        process.cwd(),
        'assets/logo_horizontal.png',
      );
      const hasLogo = fs.existsSync(logoPath);
      const emailHtml = buildVerificationEmailHtml({
        code,
        logoCid: 'jacaloria-logo',
      });

      await transporter.sendMail({
        from,
        to: email,
        subject: 'Código de verificação - Jacaloria',
        text: `Seu código de verificação é: ${code}`,
        html: emailHtml,
        attachments: hasLogo
          ? [
              {
                filename: 'logo_horizontal.png',
                path: logoPath,
                cid: 'jacaloria-logo',
              },
            ]
          : undefined,
      });
      return true;
    } catch (error) {
      this.logger.error(
        `Falha ao enviar email para ${email}: ${(error as Error).message}`,
      );
      return false;
    }
  }
}
