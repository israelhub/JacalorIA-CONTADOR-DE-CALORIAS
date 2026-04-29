import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateSocialGroupDto } from './dto/create-social-group.dto';
import { UpdateSocialGroupDto } from './dto/update-social-group.dto';
import { SocialService } from './social.service';

@Controller('social')
@UseGuards(JwtAuthGuard)
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Get('groups')
  listGroups(@Req() req: any) {
    return this.socialService.listGroups(req.user.sub);
  }

  @Post('groups')
  createGroup(@Req() req: any, @Body() dto: CreateSocialGroupDto) {
    return this.socialService.createGroup(req.user.sub, dto);
  }

  @Patch('groups/:groupId')
  updateGroup(
    @Req() req: any,
    @Param('groupId') groupId: string,
    @Body() dto: UpdateSocialGroupDto,
  ) {
    return this.socialService.updateGroup(groupId, req.user.sub, dto);
  }

  @Get('groups/:groupId')
  getGroupDetail(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.getGroupDetail(groupId, req.user.sub);
  }
}