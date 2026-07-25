import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DashboardTokenGuard } from '../analytics/guards/dashboard-token.guard';
import { CreateBroadcastDto } from './dto/create-broadcast.dto';
import { SaveReminderSettingsDto } from './dto/save-reminder-settings.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('broadcasts')
  @UseGuards(DashboardTokenGuard)
  createBroadcast(@Body() dto: CreateBroadcastDto) {
    return this.notificationsService.createBroadcast(dto);
  }

  @Get('broadcasts')
  @UseGuards(DashboardTokenGuard)
  listBroadcasts(@Query('limit') limit?: string) {
    const parsed = limit ? Number(limit) : 50;
    return this.notificationsService.listBroadcasts(
      Number.isFinite(parsed) ? parsed : 50,
    );
  }

  @Get('inbox')
  @UseGuards(JwtAuthGuard)
  getInbox(@Req() req: any) {
    const userId = req.user?.sub as string;
    return this.notificationsService.getInbox(userId);
  }

  @Get('reminder-settings')
  @UseGuards(JwtAuthGuard)
  getReminderSettings(@Req() req: any) {
    const userId = req.user?.sub as string;
    return this.notificationsService.getReminderSettings(userId);
  }

  @Put('reminder-settings')
  @UseGuards(JwtAuthGuard)
  saveReminderSettings(@Req() req: any, @Body() dto: SaveReminderSettingsDto) {
    const userId = req.user?.sub as string;
    return this.notificationsService.saveReminderSettings(userId, dto);
  }

  @Post(':id/read')
  @UseGuards(JwtAuthGuard)
  markRead(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub as string;
    return this.notificationsService.markRead(userId, id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  dismiss(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ) {
    const userId = req.user?.sub as string;
    return this.notificationsService.dismiss(userId, id);
  }
}
