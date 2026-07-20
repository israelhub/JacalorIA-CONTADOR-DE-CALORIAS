import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
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
  constructor(private readonly mailService: MailService) {}

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

    const sent = await this.mailService.sendSupportMessage({
      subjectType: dto.subjectType,
      description: dto.description.trim(),
      userId: user?.sub,
      userEmail: user?.email,
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
