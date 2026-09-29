import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { AnalyticsService } from '../analytics/analytics.service';
import { MailService } from '../mail/mail.service';
import {
  CreateSupportMessageDto,
  SupportSubjectType,
} from './dto/create-support-message.dto';
import { SupportMessage } from './models/support-message.model';

interface AuthenticatedUser {
  sub: string;
  email: string;
}

@Injectable()
export class SupportService {
  constructor(
    private readonly mailService: MailService,
    private readonly analyticsService: AnalyticsService,
    @InjectModel(User) private readonly userModel: typeof User,
    @InjectModel(SupportMessage)
    private readonly supportMessageModel: typeof SupportMessage,
  ) {}

  async createMessage(
    dto: CreateSupportMessageDto,
    user?: AuthenticatedUser,
  ): Promise<{ success: true }> {
    const contactEmail = user?.email ?? dto.email?.trim();

    if (!user && !contactEmail) {
      throw new BadRequestException(
        'Informe um e-mail para que possamos responder.',
      );
    }

    let userId = user?.sub;
    let userEmail = user?.email;
    let userName: string | undefined;

    if (user?.sub) {
      const profile = await this.userModel.findByPk(user.sub, {
        attributes: ['id', 'name', 'email'],
      });
      if (profile) {
        userId = profile.id;
        userEmail = profile.email ?? userEmail;
        userName = profile.name?.trim() || undefined;
      }
    }

    const description = dto.description.trim();

    const saved = await this.supportMessageModel.create({
      userId: userId ?? null,
      subjectType: dto.subjectType,
      description,
      contactEmail: contactEmail ?? null,
      userEmail: userEmail ?? null,
      userName: userName ?? null,
    });

    await this.analyticsService.trackSafe(userId ?? null, {
      eventName: 'support_message_created',
      properties: {
        subject_type: dto.subjectType,
        support_message_id: saved.id,
        has_user: Boolean(userId),
      },
    });

    const sent = await this.mailService.sendSupportMessage({
      subjectType: dto.subjectType,
      description,
      userId,
      userName,
      userEmail,
      contactEmail,
    });

    if (!sent) {
      throw new ServiceUnavailableException(
        'Nao foi possivel enviar sua mensagem. Tente novamente mais tarde.',
      );
    }

    return { success: true };
  }

  static subjectTypeLabel(subjectType: SupportSubjectType): string {
    return subjectType === 'bug' ? 'Bug' : 'Sugestao';
  }
}
