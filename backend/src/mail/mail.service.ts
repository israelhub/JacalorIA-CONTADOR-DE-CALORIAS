import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { buildVerificationEmailHtml } from './verification-email.template';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly logoCid = 'jacaloria-logo@jacaloria.app';

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
        'assets/logo_horizontal.webp',
      );
      const hasLogo = fs.existsSync(logoPath);
      const emailHtml = buildVerificationEmailHtml({
        code,
        logoCid: this.logoCid,
        title: 'Codigo de verificacao - Jacaloria',
        heading: 'Ola! Seu codigo de verificacao e:',
        instruction: 'Digite o codigo no aplicativo para confirmar seu e-mail.',
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
                filename: 'logo_horizontal.webp',
                path: logoPath,
                cid: this.logoCid,
                contentType: 'image/webp',
                contentDisposition: 'inline',
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

  async sendPasswordResetCode(email: string, code: string): Promise<boolean> {
    if (!this.isMailEnabled()) {
      this.logger.warn('MAIL_ENABLED=false. Email nÃ£o enviado.');
      return false;
    }

    const from = this.configService.get<string>('MAIL_FROM');
    if (!from) {
      this.logger.error('MAIL_FROM nÃ£o configurado.');
      return false;
    }

    try {
      const transporter = this.getTransporter();
      const logoPath = path.resolve(
        process.cwd(),
        'assets/logo_horizontal.webp',
      );
      const hasLogo = fs.existsSync(logoPath);
      const emailHtml = buildVerificationEmailHtml({
        code,
        logoCid: this.logoCid,
        title: 'Codigo de redefinicao de senha - Jacaloria',
        heading: 'Ola! Seu codigo de redefinicao de senha e:',
        instruction:
          'Digite o codigo no aplicativo para confirmar a troca de senha.',
      });

      await transporter.sendMail({
        from,
        to: email,
        subject: 'Codigo de redefinicao de senha - Jacaloria',
        text: `Seu codigo de redefinicao de senha e: ${code}`,
        html: emailHtml,
        attachments: hasLogo
          ? [
              {
                filename: 'logo_horizontal.webp',
                path: logoPath,
                cid: this.logoCid,
                contentType: 'image/webp',
                contentDisposition: 'inline',
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

  async sendSupportMessage(params: {
    subjectType: 'bug' | 'suggestion';
    description: string;
    userId?: string;
    userEmail?: string;
    contactEmail?: string;
  }): Promise<boolean> {
    if (!this.isMailEnabled()) {
      this.logger.warn('MAIL_ENABLED=false. Email de suporte nao enviado.');
      return false;
    }

    const from = this.configService.get<string>('MAIL_FROM');
    const to = this.configService.get<string>('MAIL_SUPPORT_TO');

    if (!from) {
      this.logger.error('MAIL_FROM nao configurado.');
      return false;
    }

    if (!to) {
      this.logger.error('MAIL_SUPPORT_TO nao configurado.');
      return false;
    }

    const subjectLabel = params.subjectType === 'bug' ? 'Bug' : 'Sugestao';
    const replyTo = params.contactEmail ?? params.userEmail;
    const textLines = [
      `Tipo: ${subjectLabel}`,
      '',
      'Descricao:',
      params.description,
      '',
      '---',
      params.userId ? `User ID: ${params.userId}` : 'User ID: (nao autenticado)',
      params.userEmail
        ? `E-mail da conta: ${params.userEmail}`
        : 'E-mail da conta: (nao autenticado)',
      replyTo ? `Contato para resposta: ${replyTo}` : 'Contato para resposta: (nao informado)',
    ];

    const htmlBody = textLines
      .map((line) => `<p>${line.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</p>`)
      .join('');

    try {
      const transporter = this.getTransporter();
      await transporter.sendMail({
        from,
        to,
        ...(replyTo ? { replyTo } : {}),
        subject: `[Jacaloria Suporte] ${subjectLabel}`,
        text: textLines.join('\n'),
        html: htmlBody,
      });
      return true;
    } catch (error) {
      this.logger.error(
        `Falha ao enviar email de suporte: ${(error as Error).message}`,
      );
      return false;
    }
  }
}
