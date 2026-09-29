import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { SupportService } from './support.service';

@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('messages')
  @UseGuards(OptionalJwtAuthGuard)
  createMessage(@Body() dto: CreateSupportMessageDto, @Req() req: any) {
    const user = req.user as { sub: string; email: string } | undefined;
    return this.supportService.createMessage(dto, user);
  }
}
