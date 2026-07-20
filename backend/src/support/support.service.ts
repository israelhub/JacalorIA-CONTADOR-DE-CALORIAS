import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { MailService } from '../mail/mail.service';
import {
  CreateSupportMessageDto,
  SupportSubjectType,
} from './dto/create-support-message.dto';

interface AuthenticatedUser {
  sub: string;
  email: string;
}

@Injectable()
export class SupportService {
  constructor(
    private readonly mailService: MailService,
    @InjectModel(User) private readonly userModel: typeof User,
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

    const sent = await this.mailService.sendSupportMessage({
      subjectType: dto.subjectType,
      description: dto.description.trim(),
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
