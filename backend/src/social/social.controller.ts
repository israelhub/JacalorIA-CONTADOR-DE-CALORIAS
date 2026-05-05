import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AddFriendByEmailDto } from './dto/add-friend-by-email.dto';
import { CreateSocialGroupDto } from './dto/create-social-group.dto';
import { UpdateSocialGroupDto } from './dto/update-social-group.dto';
import { SocialService } from './social.service';

@Controller('social')
@UseGuards(JwtAuthGuard)
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Get('friends')
  listFriends(@Req() req: any) {
    return this.socialService.listFriends(req.user.sub);
  }

  @Post('friends/by-email')
  addFriendByEmail(@Req() req: any, @Body() dto: AddFriendByEmailDto) {
    return this.socialService.addFriendByEmail(req.user.sub, dto);
  }

  @Post('friends/by-link/:inviteCode')
  addFriendByLink(@Req() req: any, @Param('inviteCode') inviteCode: string) {
    return this.socialService.addFriendByLink(req.user.sub, inviteCode);
  }

  @Post('friends/by-id/:friendUserId')
  addFriendById(@Req() req: any, @Param('friendUserId') friendUserId: string) {
    return this.socialService.addFriendById(req.user.sub, friendUserId);
  }

  @Post('friends/:friendUserId/remove')
  removeFriend(@Req() req: any, @Param('friendUserId') friendUserId: string) {
    return this.socialService.removeFriend(req.user.sub, friendUserId);
  }

  @Get('friends/:friendUserId/profile')
  getFriendProfile(@Req() req: any, @Param('friendUserId') friendUserId: string) {
    return this.socialService.getFriendProfile(req.user.sub, friendUserId);
  }

  @Get('users/search')
  searchUsers(@Req() req: any, @Query('q') query: string) {
    return this.socialService.searchUsers(req.user.sub, query);
  }

  @Get('groups')
  listGroups(@Req() req: any) {
    return this.socialService.listGroups(req.user.sub);
  }

  @Post('groups')
  createGroup(@Req() req: any, @Body() dto: CreateSocialGroupDto) {
    return this.socialService.createGroup(req.user.sub, dto);
  }

  @Post('groups/join/:inviteCode')
  joinGroupByInviteCode(@Req() req: any, @Param('inviteCode') inviteCode: string) {
    return this.socialService.joinGroupByInviteCode(req.user.sub, inviteCode);
  }

  @Get('groups/public')
  listPublicGroups(
    @Req() req: any,
    @Query('q') query?: string,
    @Query('durationDays') durationDays?: string,
    @Query('competitionType') competitionType?: string,
  ) {
    return this.socialService.listPublicGroups(req.user.sub, {
      query,
      durationDays: durationDays ? Number(durationDays) : undefined,
      competitionType,
    });
  }

  @Post('groups/public/:groupId/join')
  joinPublicGroup(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.joinPublicGroup(req.user.sub, groupId);
  }

  @Patch('groups/:groupId')
  updateGroup(@Req() req: any, @Param('groupId') groupId: string, @Body() dto: UpdateSocialGroupDto) {
    return this.socialService.updateGroup(groupId, req.user.sub, dto);
  }

  @Get('groups/:groupId')
  getGroupDetail(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.getGroupDetail(groupId, req.user.sub);
  }
}
