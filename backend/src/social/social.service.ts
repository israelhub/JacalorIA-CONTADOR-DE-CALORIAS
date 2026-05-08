import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { randomBytes } from 'crypto';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { AddFriendByEmailDto } from './dto/add-friend-by-email.dto';
import { AddGroupMembersDto } from './dto/add-group-members.dto';
import { CreateSocialGroupDto } from './dto/create-social-group.dto';
import { UpdateSocialGroupDto } from './dto/update-social-group.dto';
import { SocialFriendLink } from './models/social-friend-link.model';
import { SocialFriendRequest } from './models/social-friend-request.model';
import { SocialFriendship } from './models/social-friendship.model';
import { SocialGroupActivity } from './models/social-group-activity.model';
import { SocialGroupMember } from './models/social-group-member.model';
import { SocialGroup } from './models/social-group.model';
import { StreakService } from '../streak/streak.service';
import { parseNumber } from '../shared/utils/number-parser.util';

@Injectable()
export class SocialService {
  constructor(
    @InjectModel(SocialGroup)
    private readonly socialGroupModel: typeof SocialGroup,
    @InjectModel(SocialGroupMember)
    private readonly socialGroupMemberModel: typeof SocialGroupMember,
    @InjectModel(SocialGroupActivity)
    private readonly socialGroupActivityModel: typeof SocialGroupActivity,
    @InjectModel(SocialFriendship)
    private readonly socialFriendshipModel: typeof SocialFriendship,
    @InjectModel(SocialFriendLink)
    private readonly socialFriendLinkModel: typeof SocialFriendLink,
    @InjectModel(SocialFriendRequest)
    private readonly socialFriendRequestModel: typeof SocialFriendRequest,
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    private readonly streakService: StreakService,
  ) {}

  async listGroups(userId: string) {
    const groups = await this.socialGroupModel.findAll({
      include: [
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] }] },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          limit: 3,
          order: [['createdAt', 'DESC']],
          include: [{ model: User, as: 'user', attributes: ['id', 'name'] }],
        },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] },
      ],
      order: [['createdAt', 'DESC']],
    });

    const memberGroups = groups.filter((group) => this.isCurrentUserMember(group.members, userId));
    const streakByUserId = await this.streakService.buildStreakByUserIds(
      memberGroups.flatMap((group) => (group.members ?? []).map((member) => member.userId)),
    );

    return {
      groups: memberGroups.map((group) => this.toGroupSummary(group, userId, streakByUserId)),
    };
  }

  async listFriends(userId: string) {
    const friendships = await this.socialFriendshipModel.findAll({
      where: { [Op.or]: [{ userLowId: userId }, { userHighId: userId }] },
      order: [['createdAt', 'DESC']],
    });

    const friendIds = friendships.map((item) => (item.userLowId === userId ? item.userHighId : item.userLowId));
    const users = friendIds.length
      ? await this.userModel.findAll({ where: { id: { [Op.in]: friendIds } }, attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] })
      : [];

    const streakByUserId = await this.streakService.buildStreakByUserIds(friendIds);

    const userById = new Map(users.map((user) => [user.id, user]));
    const links = await this.ensureFriendLink(userId);
    const pendingRequests = await this.listPendingRequests(userId);

    return {
      friends: friendIds
        .map((friendId) => userById.get(friendId))
        .filter((user): user is User => Boolean(user))
        .map((user) => ({
          id: user.id,
          name: user.name ?? 'Sem nome',
          avatarUrl: user.avatarUrl ?? null,
          avatarFrameId: user.equippedAvatarFrameId ?? null,
          streakDays: streakByUserId.get(user.id) ?? 0,
        })),
      inviteCode: links.inviteCode,
      pendingRequests,
    };
  }

  async listPendingFriendRequests(userId: string) {
    return {
      requests: await this.listPendingRequests(userId),
    };
  }

  async addFriendByEmail(userId: string, dto: AddFriendByEmailDto) {
    const email = dto.email.trim().toLowerCase();
    const friend = await this.userModel.findOne({ where: { email }, attributes: ['id'] });
    if (!friend) {
      throw new NotFoundException('Nenhum usuário encontrado com esse e-mail');
    }
    await this.createFriendRequest(userId, friend.id);
    return {
      ...(await this.listFriends(userId)),
      message: 'Solicitação de amizade enviada.',
    };
  }

  async addFriendByLink(userId: string, inviteCode: string) {
    const link = await this.socialFriendLinkModel.findOne({ where: { inviteCode: inviteCode.trim().toUpperCase() } });
    if (!link) {
      throw new NotFoundException('Link de amizade inválido');
    }
    await this.createFriendRequest(userId, link.userId);
    return {
      ...(await this.listFriends(userId)),
      message: 'Solicitação de amizade enviada.',
    };
  }

  async addFriendById(userId: string, friendUserId: string) {
    await this.createFriendRequest(userId, friendUserId.trim());
    return {
      ...(await this.listFriends(userId)),
      message: 'Solicitação de amizade enviada.',
    };
  }

  async acceptFriendRequest(userId: string, requestId: string) {
    const request = await this.socialFriendRequestModel.findOne({
      where: {
        id: requestId.trim(),
        recipientId: userId,
        status: 'pending',
      },
      attributes: ['id', 'requesterId', 'recipientId'],
    });
    if (!request) {
      throw new NotFoundException('Solicitação de amizade não encontrada');
    }

    await this.createFriendship(userId, request.requesterId);
    await request.update({ status: 'accepted', respondedAt: new Date() } as never);
    await this.socialFriendRequestModel.update(
      { status: 'accepted', respondedAt: new Date() } as never,
      {
        where: {
          requesterId: userId,
          recipientId: request.requesterId,
          status: 'pending',
        },
      },
    );

    return this.listFriends(userId);
  }

  async rejectFriendRequest(userId: string, requestId: string) {
    const request = await this.socialFriendRequestModel.findOne({
      where: {
        id: requestId.trim(),
        recipientId: userId,
        status: 'pending',
      },
      attributes: ['id'],
    });
    if (!request) {
      throw new NotFoundException('Solicitação de amizade não encontrada');
    }

    await request.update({ status: 'rejected', respondedAt: new Date() } as never);
    return this.listFriends(userId);
  }

  async removeFriend(userId: string, friendUserId: string) {
    const [lowId, highId] = [userId, friendUserId.trim()].sort();
    const deleted = await this.socialFriendshipModel.destroy({
      where: { userLowId: lowId, userHighId: highId },
    });
    if (!deleted) {
      throw new NotFoundException('Amizade não encontrada');
    }
    return this.listFriends(userId);
  }

  async searchUsers(userId: string, query: string) {
    const normalizedQuery = query.trim();
    if (!normalizedQuery) {
      return { users: [] };
    }

    const friendships = await this.socialFriendshipModel.findAll({
      where: { [Op.or]: [{ userLowId: userId }, { userHighId: userId }] },
      attributes: ['userLowId', 'userHighId'],
    });

    const friendIds = new Set<string>();
    for (const friendship of friendships) {
      friendIds.add(friendship.userLowId === userId ? friendship.userHighId : friendship.userLowId);
    }

    const requests = await this.socialFriendRequestModel.findAll({
      where: {
        status: 'pending',
        [Op.or]: [{ requesterId: userId }, { recipientId: userId }],
      },
      attributes: ['requesterId', 'recipientId'],
    });
    const outgoingRequestIds = new Set<string>();
    const incomingRequestIds = new Set<string>();
    for (const request of requests) {
      if (request.requesterId === userId) {
        outgoingRequestIds.add(request.recipientId);
      }
      if (request.recipientId === userId) {
        incomingRequestIds.add(request.requesterId);
      }
    }

    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        normalizedQuery,
      );
    const queryClause = normalizedQuery.includes('@')
      ? { email: { [Op.iLike]: normalizedQuery } }
      : isUuid
      ? {
          [Op.or]: [
            { id: normalizedQuery },
            { name: { [Op.iLike]: `%${normalizedQuery}%` } },
            { email: { [Op.iLike]: `%${normalizedQuery}%` } },
          ],
        }
      : {
          [Op.or]: [
            { name: { [Op.iLike]: `%${normalizedQuery}%` } },
            { email: { [Op.iLike]: `%${normalizedQuery}%` } },
          ],
        };

    const users = await this.userModel.findAll({
      where: {
        [Op.and]: [{ id: { [Op.ne]: userId } }, queryClause],
      },
      attributes: ['id', 'name', 'email', 'avatarUrl', 'equippedAvatarFrameId'],
      limit: 20,
      order: [['name', 'ASC']],
    });

    return {
      users: users.map((user) => ({
        id: user.id,
        name: user.name ?? 'Sem nome',
        email: user.email,
        avatarUrl: user.avatarUrl ?? null,
        avatarFrameId: user.equippedAvatarFrameId ?? null,
        isFriend: friendIds.has(user.id),
        friendRequestStatus: friendIds.has(user.id)
          ? 'none'
          : outgoingRequestIds.has(user.id)
          ? 'outgoing'
          : incomingRequestIds.has(user.id)
          ? 'incoming'
          : 'none',
      })),
    };
  }

  async getFriendProfile(userId: string, friendUserId: string) {
    const friendId = friendUserId.trim();
    if (!(await this.areFriends(userId, friendId))) {
      throw new NotFoundException('Amigo não encontrado');
    }

    const friend = await this.userModel.findByPk(friendId, {
      attributes: [
        'id',
        'name',
        'avatarUrl',
        'equippedAvatarFrameId',
        'equippedAvatarBackgroundId',
        'birthDate',
        'objective',
        'sex',
      ],
    });
    if (!friend) {
      throw new NotFoundException('Amigo não encontrado');
    }

    const streakDays = await this.streakService.getUserStreak(friendId);

    const meals = await this.mealModel.findAll({
      where: { userId: friendId, status: MealStatus.Active },
      attributes: ['title', 'description', 'createdAt'],
      order: [['createdAt', 'DESC']],
    });

    const favoriteDish = this.getFavoriteDish(meals);
    const preferredPeriod = this.getPreferredPeriod(meals);
    const totalXp = await this.sumUserPoints(friend.id);

    return {
      id: friend.id,
      name: friend.name ?? 'Sem nome',
      avatarUrl: friend.avatarUrl ?? null,
      avatarFrameId: friend.equippedAvatarFrameId ?? null,
      avatarBackgroundId: friend.equippedAvatarBackgroundId ?? null,
      streakDays,
      friendCount: await this.countFriends(friend.id),
      totalXp,
      favoriteDish,
      preferredPeriod,
      birthDate: friend.birthDate ?? null,
      objective: friend.objective ?? null,
      sex: friend.sex ?? null,
    };
  }

  async createGroup(userId: string, dto: CreateSocialGroupDto) {
    const user = await this.userModel.findByPk(userId, { attributes: ['id', 'name'] });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const inviteCode = this.generateInviteCode();
    const now = new Date();
    const durationDays = dto.competitionType === 'group_streak' ? 0 : dto.durationDays ?? 7;
    const group = await this.socialGroupModel.create({
      ownerId: userId,
      name: dto.name.trim(),
      description: dto.description.trim(),
      competitionType: dto.competitionType,
      iconKey: dto.iconKey,
      durationDays,
      isPublic: dto.isPublic === true,
      startsAt: now,
      endsAt: this.addDays(now, durationDays),
      inviteCode,
    } as never);

    await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: true, points: 0 });

    const invitedIds = [...new Set((dto.memberUserIds ?? []).filter((id) => id !== userId))];
    for (const friendId of invitedIds) {
      const isFriend = await this.areFriends(userId, friendId);
      if (!isFriend) {
        throw new BadRequestException('Só é possível adicionar amigos ao criar grupo');
      }

      const exists = await this.socialGroupMemberModel.findOne({ where: { groupId: group.id, userId: friendId } });
      if (!exists) {
        await this.socialGroupMemberModel.create({ groupId: group.id, userId: friendId, isLeader: false, points: 0 });
      }
    }

    await this.socialGroupActivityModel.create({
      groupId: group.id,
      userId,
      activityType: 'created',
      message: `${user.name ?? 'Você'} criou o grupo`,
      metadata: { competitionType: dto.competitionType },
    });

    return this.getGroupDetail(group.id, userId);
  }

  async joinGroupByInviteCode(userId: string, inviteCode: string) {
    const code = inviteCode.trim().toUpperCase();
    const group = await this.socialGroupModel.findOne({ where: { inviteCode: code }, attributes: ['id', 'name'] });
    if (!group) throw new NotFoundException('Link de grupo inválido');

    const exists = await this.socialGroupMemberModel.findOne({ where: { groupId: group.id, userId } });
    if (!exists) {
      await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: false, points: 0 });
      const actor = await this.userModel.findByPk(userId, { attributes: ['name'] });
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'joined',
        message: `${actor?.name ?? 'Usuário'} entrou no grupo por link`,
        metadata: { inviteCode: code, actorName: actor?.name ?? 'Usuário' },
      });
    }

    return this.getGroupDetail(group.id, userId);
  }

  async listPublicGroups(
    userId: string,
    filters: { query?: string; durationDays?: number; competitionType?: string },
  ) {
    const where: any = { isPublic: true };
    if (filters.query?.trim()) {
      where.name = { [Op.iLike]: `%${filters.query.trim()}%` };
    }
    if (filters.durationDays && Number.isFinite(filters.durationDays)) {
      where.durationDays = filters.durationDays;
    }
    if (filters.competitionType?.trim()) {
      where.competitionType = filters.competitionType.trim();
    }

    const groups = await this.socialGroupModel.findAll({
      where,
      include: [
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] }] },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          limit: 3,
          order: [['createdAt', 'DESC']],
          include: [{ model: User, as: 'user', attributes: ['id', 'name'] }],
        },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] },
      ],
      order: [['createdAt', 'DESC']],
      limit: 100,
    });

    const publicGroups = groups.filter((group) => !this.isCurrentUserMember(group.members, userId));
    const streakByUserId = await this.streakService.buildStreakByUserIds(
      publicGroups.flatMap((group) => (group.members ?? []).map((member) => member.userId)),
    );

    return {
      groups: publicGroups.map((group) => this.toGroupSummary(group, userId, streakByUserId)),
    };
  }

  async joinPublicGroup(userId: string, groupId: string) {
    const group = await this.socialGroupModel.findByPk(groupId, { attributes: ['id', 'name', 'isPublic'] });
    if (!group || !group.isPublic) throw new NotFoundException('Grupo público não encontrado');

    const exists = await this.socialGroupMemberModel.findOne({ where: { groupId: group.id, userId } });
    if (!exists) {
      await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: false, points: 0 });
      const actor = await this.userModel.findByPk(userId, { attributes: ['name'] });
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'joined_public',
        message: `${actor?.name ?? 'Usuário'} entrou no grupo público`,
        metadata: { groupId: group.id, actorName: actor?.name ?? 'Usuário' },
      });
    }

    return this.getGroupDetail(group.id, userId);
  }

  async updateGroup(groupId: string, userId: string, dto: UpdateSocialGroupDto) {
    const group = await this.findGroupForMember(groupId, userId);
    const currentUser = this.findCurrentUserMember(group.members, userId);
    if (!currentUser?.isLeader && group.ownerId !== userId) throw new BadRequestException('Apenas o líder pode editar o grupo');

    const nextCompetitionType = dto.competitionType ?? group.competitionType;
    const durationDays = nextCompetitionType === 'group_streak' ? 0 : dto.durationDays ?? group.durationDays;
    await group.update({
      name: dto.name?.trim() ?? group.name,
      description: dto.description?.trim() ?? group.description,
      competitionType: nextCompetitionType,
      iconKey: dto.iconKey ?? group.iconKey,
      durationDays,
      isPublic: dto.isPublic ?? group.isPublic,
      endsAt: this.addDays(group.startsAt, durationDays),
    } as never);

    if (dto.durationDays != null || dto.competitionType || dto.iconKey) {
      const actor = await this.userModel.findByPk(userId, { attributes: ['name'] });
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'updated',
        message: `${actor?.name ?? 'Usuário'} atualizou as informações do grupo`,
        metadata: { durationDays, competitionType: nextCompetitionType, iconKey: dto.iconKey ?? group.iconKey, actorName: actor?.name ?? 'Usuário' },
      });
    }

    return this.getGroupDetail(group.id, userId);
  }

  async addGroupMembers(groupId: string, userId: string, dto: AddGroupMembersDto) {
    const group = await this.findGroupForMember(groupId, userId);
    const currentUser = this.findCurrentUserMember(group.members, userId);
    if (!currentUser?.isLeader && group.ownerId !== userId) {
      throw new BadRequestException('Apenas o líder pode convidar amigos para o grupo');
    }

    const invitedIds = [...new Set((dto.memberUserIds ?? []).map((id) => id.trim()).filter(Boolean))];
    if (!invitedIds.length) {
      throw new BadRequestException('Selecione ao menos um amigo para convidar');
    }

    for (const friendId of invitedIds) {
      if (friendId === userId) {
        continue;
      }

      const isFriend = await this.areFriends(userId, friendId);
      if (!isFriend) {
        throw new BadRequestException('Só é possível adicionar amigos ao grupo');
      }

      const exists = await this.socialGroupMemberModel.findOne({
        where: { groupId: group.id, userId: friendId },
      });
      if (!exists) {
        await this.socialGroupMemberModel.create({
          groupId: group.id,
          userId: friendId,
          isLeader: false,
          points: 0,
        });
      }
    }

    const actor = await this.userModel.findByPk(userId, { attributes: ['name'] });
    await this.socialGroupActivityModel.create({
      groupId: group.id,
      userId,
      activityType: 'updated',
      message: `${actor?.name ?? 'Usuário'} convidou amigos para o grupo`,
      metadata: { invitedCount: invitedIds.length, actorName: actor?.name ?? 'Usuário' },
    });

    return this.getGroupDetail(group.id, userId);
  }

  async leaveGroup(groupId: string, userId: string) {
    const group = await this.findGroupForMember(groupId, userId);
    const currentUser = this.findCurrentUserMember(group.members ?? [], userId);
    if (!currentUser) {
      throw new NotFoundException('Você não faz parte deste grupo');
    }

    if (currentUser.isLeader || group.ownerId === userId) {
      const nextLeader = [...(group.members ?? [])]
        .filter((member) => member.userId !== userId)
        .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())[0];

      if (!nextLeader) {
        throw new BadRequestException('Sem outro membro para assumir liderança. Exclua o grupo nas configurações.');
      }

      await this.socialGroupMemberModel.update(
        { isLeader: true },
        { where: { id: nextLeader.id } },
      );

      await group.update({ ownerId: nextLeader.userId } as never);
    }

    await this.socialGroupMemberModel.destroy({
      where: { groupId: group.id, userId },
    });

    const actor = await this.userModel.findByPk(userId, { attributes: ['name'] });
    await this.socialGroupActivityModel.create({
      groupId: group.id,
      userId,
      activityType: 'left',
      message: `${actor?.name ?? 'Usuário'} saiu do grupo`,
      metadata: { actorName: actor?.name ?? 'Usuário' },
    });

    return { success: true };
  }

  async deleteGroup(groupId: string, userId: string) {
    const group = await this.findGroupForMember(groupId, userId);
    const currentUser = this.findCurrentUserMember(group.members ?? [], userId);
    if (!currentUser?.isLeader && group.ownerId !== userId) {
      throw new BadRequestException('Apenas o líder pode excluir o grupo');
    }

    await this.socialGroupActivityModel.destroy({ where: { groupId: group.id } });
    await this.socialGroupMemberModel.destroy({ where: { groupId: group.id } });
    await this.socialGroupModel.destroy({ where: { id: group.id } });
    return { success: true };
  }

  async getGroupDetail(groupId: string, userId: string) {
    const group = await this.findGroupForMember(groupId, userId);
    const streakByUserId = await this.streakService.buildStreakByUserIds((group.members ?? []).map((member) => member.userId));
    return this.toGroupDetail(group, userId, streakByUserId);
  }

  private async findGroupForMember(groupId: string, userId: string) {
    const group = await this.socialGroupModel.findByPk(groupId, {
      include: [
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] }] },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          order: [['createdAt', 'DESC']],
          include: [{ model: User, as: 'user', attributes: ['id', 'name'] }],
        },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl', 'equippedAvatarFrameId'] },
      ],
    });

    if (!group || !this.isCurrentUserMember(group.members, userId)) throw new NotFoundException('Grupo não encontrado');
    return group;
  }

  private async ensureFriendLink(userId: string) {
    const existing = await this.socialFriendLinkModel.findOne({ where: { userId } });
    if (existing) return existing;

    return this.socialFriendLinkModel.create({ userId, inviteCode: this.generateInviteCode() } as never);
  }

  private async listPendingRequests(userId: string) {
    const requests = await this.socialFriendRequestModel.findAll({
      where: { recipientId: userId, status: 'pending' },
      include: [
        {
          model: User,
          as: 'requester',
          attributes: ['id', 'name', 'email', 'avatarUrl', 'equippedAvatarFrameId'],
        },
      ],
      order: [['createdAt', 'DESC']],
    });

    return requests.map((request) => ({
      id: request.id,
      requesterId: request.requesterId,
      requesterName: request.requester?.name ?? 'Sem nome',
      requesterEmail: request.requester?.email ?? '',
      requesterAvatarUrl: request.requester?.avatarUrl ?? null,
      requesterAvatarFrameId: request.requester?.equippedAvatarFrameId ?? null,
      createdAt: request.createdAt,
    }));
  }

  private async createFriendRequest(currentUserId: string, friendUserId: string) {
    const normalizedFriendId = friendUserId.trim();
    if (currentUserId === normalizedFriendId) {
      throw new BadRequestException('Não é possível adicionar você mesmo');
    }

    const friend = await this.userModel.findByPk(normalizedFriendId, { attributes: ['id'] });
    if (!friend) {
      throw new NotFoundException('Usuário não encontrado');
    }

    if (await this.areFriends(currentUserId, normalizedFriendId)) {
      throw new BadRequestException('Vocês já são amigos');
    }

    const incomingPending = await this.socialFriendRequestModel.findOne({
      where: {
        requesterId: normalizedFriendId,
        recipientId: currentUserId,
        status: 'pending',
      },
      attributes: ['id'],
    });
    if (incomingPending) {
      throw new BadRequestException('Esse usuário já enviou uma solicitação para você. Aceite na lista de solicitações.');
    }

    const existing = await this.socialFriendRequestModel.findOne({
      where: {
        requesterId: currentUserId,
        recipientId: normalizedFriendId,
      },
    });
    if (existing) {
      if (existing.status === 'pending') {
        return existing;
      }
      return existing.update({ status: 'pending', respondedAt: null } as never);
    }

    return this.socialFriendRequestModel.create({
      requesterId: currentUserId,
      recipientId: normalizedFriendId,
      status: 'pending',
      respondedAt: null,
    } as never);
  }

  private async createFriendship(currentUserId: string, friendUserId: string) {
    if (currentUserId === friendUserId) throw new BadRequestException('Não é possível adicionar você mesmo');

    const [lowId, highId] = [currentUserId, friendUserId].sort();
    const existing = await this.socialFriendshipModel.findOne({ where: { userLowId: lowId, userHighId: highId } });
    if (existing) return existing;

    const friend = await this.userModel.findByPk(friendUserId, { attributes: ['id'] });
    if (!friend) throw new NotFoundException('Usuário não encontrado');

    return this.socialFriendshipModel.create({ userLowId: lowId, userHighId: highId } as never);
  }

  private async areFriends(userA: string, userB: string) {
    const [lowId, highId] = [userA, userB].sort();
    const friendship = await this.socialFriendshipModel.findOne({ where: { userLowId: lowId, userHighId: highId }, attributes: ['id'] });
    return Boolean(friendship);
  }

  private async countFriends(userId: string) {
    return this.socialFriendshipModel.count({
      where: { [Op.or]: [{ userLowId: userId }, { userHighId: userId }] },
    });
  }

  private async sumUserPoints(userId: string) {
    const rows = await this.socialGroupMemberModel.findAll({
      where: { userId },
      attributes: ['points'],
    });

    return rows.reduce((sum, row) => sum + parseNumber(row.points), 0);
  }

  private toGroupSummary(group: SocialGroup, userId: string, streakByUserId?: Map<string, number>) {
    const members = this.sortMembers(this.withComputedStreaks(group.members ?? [], streakByUserId), group.competitionType);
    const currentUser = this.findCurrentUserMember(members, userId);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt, group.competitionType);
    const groupStreakDefeated = group.competitionType === 'group_streak' && members.some((member) => parseNumber(member.streakDays) <= 0);

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      iconKey: group.iconKey,
      competitionType: group.competitionType,
      durationDays: group.durationDays,
      memberCount: members.length,
      rankPosition: currentUser ? members.indexOf(currentUser) + 1 : members.length,
      points: currentUser?.points ?? 0,
      streakDays: currentUser?.streakDays ?? 0,
      leaderName: topMember?.user?.name ?? group.owner?.name ?? 'Líder do grupo',
      remainingDays,
      isDefeated: groupStreakDefeated,
      isPublic: group.isPublic,
      inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
      activities: this.mapActivities(group.activities ?? []),
    };
  }

  private toGroupDetail(group: SocialGroup, userId: string, streakByUserId?: Map<string, number>) {
    const members = this.sortMembers(this.withComputedStreaks(group.members ?? [], streakByUserId), group.competitionType);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt, group.competitionType);
    const groupStreakDefeated = group.competitionType === 'group_streak' && members.some((member) => parseNumber(member.streakDays) <= 0);

    return {
      group: {
        id: group.id,
        name: group.name,
        description: group.description,
        iconKey: group.iconKey,
        competitionType: group.competitionType,
        durationDays: group.durationDays,
        isPublic: group.isPublic,
        inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
        memberCount: members.length,
        remainingDays,
        isDefeated: groupStreakDefeated,
        rule: group.competitionType === 'group_streak'
          ? 'A sequência do grupo só aumenta se todos os membros estiverem ativos.'
          : null,
        leaderName: topMember?.user?.name ?? group.owner?.name ?? 'Líder do grupo',
      },
      ranking: members.map((member, index) => ({
        id: member.id,
        userId: member.userId,
        name: member.user?.name ?? 'Sem nome',
        avatarUrl: member.user?.avatarUrl ?? null,
        avatarFrameId: member.user?.equippedAvatarFrameId ?? null,
        points: member.points,
        streakDays: member.streakDays,
        isCurrentUser: member.userId === userId,
        isLeader: member.isLeader,
        position: index + 1,
        subtitle: member.isLeader ? 'Líder do grupo' : '',
      })),
      recentActivities: this.mapActivities(group.activities ?? []),
    };
  }

  private mapActivities(activities: SocialGroupActivity[]) {
    const asObject = (metadata: unknown): Record<string, unknown> =>
      metadata && typeof metadata === 'object' ? (metadata as Record<string, unknown>) : {};

    return activities.map((activity) => ({
      id: activity.id,
      message: this.buildActivityMessage(activity),
      activityType: activity.activityType,
      createdAt: activity.createdAt,
      metadata: { ...asObject(activity.metadata), actorName: activity.user?.name ?? asObject(activity.metadata).actorName ?? null },
    }));
  }

  private buildActivityMessage(activity: SocialGroupActivity) {
    const metadata = activity.metadata && typeof activity.metadata === 'object'
      ? (activity.metadata as Record<string, unknown>)
      : {};
    const actorName = activity.user?.name ?? (typeof metadata.actorName === 'string' ? metadata.actorName : null) ?? 'Usuário';

    if (activity.activityType === 'created') {
      return `${actorName} criou o grupo`;
    }
    if (activity.activityType === 'joined') {
      return `${actorName} entrou no grupo por link`;
    }
    if (activity.activityType === 'joined_public') {
      return `${actorName} entrou no grupo público`;
    }
    if (activity.activityType === 'updated') {
      return `${actorName} atualizou as informações do grupo`;
    }
    if (activity.activityType === 'left') {
      return `${actorName} saiu do grupo`;
    }

    const legacyMessage = activity.message?.trim() ?? '';
    if (!legacyMessage) {
      return `${actorName} realizou uma ação no grupo`;
    }
    return legacyMessage.replace(/^Você\b/i, actorName);
  }

  private withComputedStreaks(members: SocialGroupMember[], streakByUserId?: Map<string, number>) {
    if (!streakByUserId || streakByUserId.size === 0) {
      return members;
    }

    return members.map((member) => ({
      ...(member.toJSON() as Record<string, unknown>),
      streakDays: streakByUserId.get(member.userId) ?? 0,
    })) as SocialGroupMember[];
  }

  private sortMembers(members: SocialGroupMember[], competitionType: string) {
    return [...members].sort((left, right) => {
      if (competitionType === 'offensive' || competitionType === 'group_streak') {
        const streakDelta = parseNumber(right.streakDays) - parseNumber(left.streakDays);
        if (streakDelta !== 0) return streakDelta;

        const pointsDelta = parseNumber(right.points) - parseNumber(left.points);
        if (pointsDelta !== 0) return pointsDelta;

        return new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime();
      }

      const pointsDelta = parseNumber(right.points) - parseNumber(left.points);
      if (pointsDelta !== 0) return pointsDelta;

      const streakDelta = parseNumber(right.streakDays) - parseNumber(left.streakDays);
      if (streakDelta !== 0) return streakDelta;

      return new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime();
    });
  }

  private findCurrentUserMember(members: SocialGroupMember[], userId: string) {
    return members.find((member) => member.userId === userId);
  }

  private isCurrentUserMember(members: SocialGroupMember[] | undefined, userId: string) {
    return Boolean(members?.some((member) => member.userId === userId));
  }

  private getRemainingDays(endsAt: Date, competitionType: string) {
    if (competitionType === 'group_streak') {
      return 0;
    }
    const diff = new Date(endsAt).getTime() - Date.now();
    return Math.max(Math.ceil(diff / (24 * 60 * 60 * 1000)), 0);
  }

  private addDays(date: Date, days: number) {
    const next = new Date(date);
    next.setUTCDate(next.getUTCDate() + days);
    return next;
  }

  private generateInviteCode() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const bytes = randomBytes(6);
    let code = '';
    for (let index = 0; index < 6; index += 1) {
      code += alphabet[bytes[index] % alphabet.length];
    }
    return code;
  }

  private getFavoriteDish(meals: Array<Pick<Meal, 'title' | 'description'>>) {
    if (!meals.length) return null;

    const titleCounts = new Map<string, number>();
    for (const meal of meals) {
      const rawLabel = (meal.description ?? meal.title ?? '').trim();
      const normalized = rawLabel.toLowerCase();
      if (!normalized) continue;
      titleCounts.set(normalized, (titleCounts.get(normalized) ?? 0) + 1);
    }

    if (!titleCounts.size) return null;

    let bestTitle = '';
    let bestCount = 0;
    for (const [title, count] of titleCounts.entries()) {
      if (count > bestCount) {
        bestTitle = title;
        bestCount = count;
      }
    }

    return bestTitle
        .split(' ')
        .filter((part) => part.length > 0)
        .map((part) => part[0].toUpperCase() + part.slice(1))
        .join(' ');
  }

  private getPreferredPeriod(meals: Array<Pick<Meal, 'createdAt'>>) {
    if (!meals.length) return null;

    const periodCounts = { morning: 0, afternoon: 0, night: 0 };

    for (const meal of meals) {
      const hour = new Date(meal.createdAt).getHours();
      if (hour < 12) {
        periodCounts.morning += 1;
      } else if (hour < 18) {
        periodCounts.afternoon += 1;
      } else {
        periodCounts.night += 1;
      }
    }

    if (periodCounts.morning >= periodCounts.afternoon && periodCounts.morning >= periodCounts.night) {
      return 'morning';
    }
    if (periodCounts.afternoon >= periodCounts.night) {
      return 'afternoon';
    }
    return 'night';
  }
}
