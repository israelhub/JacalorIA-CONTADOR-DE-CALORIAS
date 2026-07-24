import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AddGroupMembersDto } from './dto/add-group-members.dto';
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

  @Get('friends/requests')
  listPendingFriendRequests(@Req() req: any) {
    return this.socialService.listPendingFriendRequests(req.user.sub);
  }

  @Post('friends/requests/:requestId/accept')
  acceptFriendRequest(@Req() req: any, @Param('requestId') requestId: string) {
    return this.socialService.acceptFriendRequest(req.user.sub, requestId);
  }

  @Post('friends/requests/:requestId/reject')
  rejectFriendRequest(@Req() req: any, @Param('requestId') requestId: string) {
    return this.socialService.rejectFriendRequest(req.user.sub, requestId);
  }

  @Post('friends/:friendUserId/remove')
  removeFriend(@Req() req: any, @Param('friendUserId') friendUserId: string) {
    return this.socialService.removeFriend(req.user.sub, friendUserId);
  }

  @Get('friends/:friendUserId/profile')
  getFriendProfile(
    @Req() req: any,
    @Param('friendUserId') friendUserId: string,
    @Query('groupId') groupId?: string,
    @Query('viaUserId') viaUserId?: string,
  ) {
    return this.socialService.getFriendProfile(req.user.sub, friendUserId, {
      groupId,
      viaUserId,
    });
  }

  @Get('friends/:userId/list')
  listUserFriends(
    @Req() req: any,
    @Param('userId') userId: string,
    @Query('groupId') groupId?: string,
    @Query('viaUserId') viaUserId?: string,
  ) {
    return this.socialService.listUserFriends(req.user.sub, userId, {
      groupId,
      viaUserId,
    });
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

  @Post('groups/:groupId/members')
  addGroupMembers(@Req() req: any, @Param('groupId') groupId: string, @Body() dto: AddGroupMembersDto) {
    return this.socialService.addGroupMembers(groupId, req.user.sub, dto);
  }

  @Post('groups/:groupId/members/:memberUserId/remove')
  removeGroupMember(
    @Req() req: any,
    @Param('groupId') groupId: string,
    @Param('memberUserId') memberUserId: string,
  ) {
    return this.socialService.removeGroupMember(groupId, req.user.sub, memberUserId);
  }

  @Post('groups/:groupId/leave')
  leaveGroup(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.leaveGroup(groupId, req.user.sub);
  }

  @Delete('groups/:groupId')
  deleteGroup(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.deleteGroup(groupId, req.user.sub);
  }

  @Get('groups/:groupId')
  getGroupDetail(@Req() req: any, @Param('groupId') groupId: string) {
    return this.socialService.getGroupDetail(groupId, req.user.sub);
  }

  @Get('groups/:groupId/members/:memberUserId/daily-meals')
  getGroupMemberDailyMeals(
    @Req() req: any,
    @Param('groupId') groupId: string,
    @Param('memberUserId') memberUserId: string,
    @Query('date') date?: string,
  ) {
    return this.socialService.getGroupMemberDailyMeals(
      req.user.sub,
      groupId,
      memberUserId,
      date,
    );
  }
}
