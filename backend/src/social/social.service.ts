import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { randomBytes } from 'crypto';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { AddFriendByEmailDto } from './dto/add-friend-by-email.dto';
import { CreateSocialGroupDto } from './dto/create-social-group.dto';
import { UpdateSocialGroupDto } from './dto/update-social-group.dto';
import { SocialFriendLink } from './models/social-friend-link.model';
import { SocialFriendship } from './models/social-friendship.model';
import { SocialGroupActivity } from './models/social-group-activity.model';
import { SocialGroupMember } from './models/social-group-member.model';
import { SocialGroup } from './models/social-group.model';

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
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
  ) {}

  async listGroups(userId: string) {
    const groups = await this.socialGroupModel.findAll({
      include: [
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl'] }] },
        { model: SocialGroupActivity, as: 'activities', separate: true, limit: 3, order: [['createdAt', 'DESC']] },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl'] },
      ],
      order: [['createdAt', 'DESC']],
    });

    return {
      groups: groups.filter((group) => this.isCurrentUserMember(group.members, userId)).map((group) => this.toGroupSummary(group, userId)),
    };
  }

  async listFriends(userId: string) {
    const friendships = await this.socialFriendshipModel.findAll({
      where: { [Op.or]: [{ userLowId: userId }, { userHighId: userId }] },
      order: [['createdAt', 'DESC']],
    });

    const friendIds = friendships.map((item) => (item.userLowId === userId ? item.userHighId : item.userLowId));
    const users = friendIds.length
      ? await this.userModel.findAll({ where: { id: { [Op.in]: friendIds } }, attributes: ['id', 'name', 'avatarUrl'] })
      : [];

    const streakRows = friendIds.length
      ? await this.socialGroupMemberModel.findAll({ where: { userId: { [Op.in]: friendIds } }, attributes: ['userId', 'streakDays'] })
      : [];

    const streakByUserId = new Map<string, number>();
    for (const row of streakRows) {
      const current = streakByUserId.get(row.userId) ?? 0;
      const value = this.toNumber(row.streakDays);
      if (value > current) {
        streakByUserId.set(row.userId, value);
      }
    }

    const userById = new Map(users.map((user) => [user.id, user]));
    const links = await this.ensureFriendLink(userId);

    return {
      friends: friendIds
        .map((friendId) => userById.get(friendId))
        .filter((user): user is User => Boolean(user))
        .map((user) => ({
          id: user.id,
          name: user.name ?? 'Sem nome',
          avatarUrl: user.avatarUrl ?? null,
          streakDays: streakByUserId.get(user.id) ?? 0,
        })),
      inviteCode: links.inviteCode,
    };
  }

  async addFriendByEmail(userId: string, dto: AddFriendByEmailDto) {
    const email = dto.email.trim().toLowerCase();
    const friend = await this.userModel.findOne({ where: { email }, attributes: ['id'] });
    if (!friend) {
      throw new NotFoundException('Nenhum usuário encontrado com esse e-mail');
    }
    await this.createFriendship(userId, friend.id);
    return this.listFriends(userId);
  }

  async addFriendByLink(userId: string, inviteCode: string) {
    const link = await this.socialFriendLinkModel.findOne({ where: { inviteCode: inviteCode.trim().toUpperCase() } });
    if (!link) {
      throw new NotFoundException('Link de amizade inválido');
    }
    await this.createFriendship(userId, link.userId);
    return this.listFriends(userId);
  }

  async addFriendById(userId: string, friendUserId: string) {
    await this.createFriendship(userId, friendUserId.trim());
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
      attributes: ['id', 'name', 'email', 'avatarUrl'],
      limit: 20,
      order: [['name', 'ASC']],
    });

    return {
      users: users.map((user) => ({
        id: user.id,
        name: user.name ?? 'Sem nome',
        email: user.email,
        avatarUrl: user.avatarUrl ?? null,
        isFriend: friendIds.has(user.id),
      })),
    };
  }

  async getFriendProfile(userId: string, friendUserId: string) {
    const friendId = friendUserId.trim();
    if (!(await this.areFriends(userId, friendId))) {
      throw new NotFoundException('Amigo não encontrado');
    }

    const friend = await this.userModel.findByPk(friendId, {
      attributes: ['id', 'name', 'avatarUrl', 'birthDate', 'objective', 'sex'],
    });
    if (!friend) {
      throw new NotFoundException('Amigo não encontrado');
    }

    const streakRows = await this.socialGroupMemberModel.findAll({
      where: { userId: friendId },
      attributes: ['streakDays'],
    });
    let streakDays = 0;
    for (const row of streakRows) {
      streakDays = Math.max(streakDays, this.toNumber(row.streakDays));
    }

    const meals = await this.mealModel.findAll({
      where: { userId: friendId, status: MealStatus.Active },
      attributes: ['title', 'createdAt'],
      order: [['createdAt', 'DESC']],
    });

    const favoriteDish = this.getFavoriteDish(meals);
    const preferredPeriod = this.getPreferredPeriod(meals);
    const totalXp = await this.sumUserPoints(friend.id);

    return {
      id: friend.id,
      name: friend.name ?? 'Sem nome',
      avatarUrl: friend.avatarUrl ?? null,
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

    await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: true, points: 0, streakDays: 0 });

    const invitedIds = [...new Set((dto.memberUserIds ?? []).filter((id) => id !== userId))];
    for (const friendId of invitedIds) {
      const isFriend = await this.areFriends(userId, friendId);
      if (!isFriend) {
        throw new BadRequestException('Só é possível adicionar amigos ao criar grupo');
      }

      const exists = await this.socialGroupMemberModel.findOne({ where: { groupId: group.id, userId: friendId } });
      if (!exists) {
        await this.socialGroupMemberModel.create({ groupId: group.id, userId: friendId, isLeader: false, points: 0, streakDays: 0 });
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
      await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: false, points: 0, streakDays: 0 });
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'joined',
        message: 'Entrou no grupo por link',
        metadata: { inviteCode: code },
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
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl'] }] },
        { model: SocialGroupActivity, as: 'activities', separate: true, limit: 3, order: [['createdAt', 'DESC']] },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl'] },
      ],
      order: [['createdAt', 'DESC']],
      limit: 100,
    });

    return {
      groups: groups
        .filter((group) => !this.isCurrentUserMember(group.members, userId))
        .map((group) => this.toGroupSummary(group, userId)),
    };
  }

  async joinPublicGroup(userId: string, groupId: string) {
    const group = await this.socialGroupModel.findByPk(groupId, { attributes: ['id', 'name', 'isPublic'] });
    if (!group || !group.isPublic) throw new NotFoundException('Grupo público não encontrado');

    const exists = await this.socialGroupMemberModel.findOne({ where: { groupId: group.id, userId } });
    if (!exists) {
      await this.socialGroupMemberModel.create({ groupId: group.id, userId, isLeader: false, points: 0, streakDays: 0 });
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'joined_public',
        message: 'Entrou no grupo público',
        metadata: { groupId: group.id },
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
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'updated',
        message: 'Você atualizou as informações do grupo',
        metadata: { durationDays, competitionType: nextCompetitionType, iconKey: dto.iconKey ?? group.iconKey },
      });
    }

    return this.getGroupDetail(group.id, userId);
  }

  async getGroupDetail(groupId: string, userId: string) {
    const group = await this.findGroupForMember(groupId, userId);
    return this.toGroupDetail(group, userId);
  }

  private async findGroupForMember(groupId: string, userId: string) {
    const group = await this.socialGroupModel.findByPk(groupId, {
      include: [
        { model: SocialGroupMember, as: 'members', include: [{ model: User, as: 'user', attributes: ['id', 'name', 'avatarUrl'] }] },
        { model: SocialGroupActivity, as: 'activities', separate: true, order: [['createdAt', 'DESC']] },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatarUrl'] },
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

    return rows.reduce((sum, row) => sum + this.toNumber(row.points), 0);
  }

  private toGroupSummary(group: SocialGroup, userId: string) {
    const members = this.sortMembers(group.members ?? []);
    const currentUser = this.findCurrentUserMember(members, userId);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt, group.competitionType);
    const groupStreakDefeated = group.competitionType === 'group_streak' && members.some((member) => this.toNumber(member.streakDays) <= 0);

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      iconKey: group.iconKey,
      competitionType: group.competitionType,
      competitionLabel: this.competitionLabel(group.competitionType),
      durationDays: group.durationDays,
      durationDaysLabel: group.competitionType === 'group_streak' ? 'Infinito' : `${group.durationDays} dias`,
      memberCount: members.length,
      rankPosition: currentUser ? members.indexOf(currentUser) + 1 : members.length,
      points: currentUser?.points ?? 0,
      streakDays: currentUser?.streakDays ?? 0,
      leaderName: topMember?.user?.name ?? group.owner?.name ?? 'Líder do grupo',
      leaderLabel: currentUser?.isLeader || topMember?.userId === userId ? 'Você lidera' : `${topMember?.user?.name ?? 'Líder'} lidera`,
      remainingDays,
      remainingDaysLabel: group.competitionType === 'group_streak'
        ? (groupStreakDefeated ? 'Sequência quebrada' : 'Infinito')
        : `${remainingDays} dias restantes`,
      isDefeated: groupStreakDefeated,
      isPublic: group.isPublic,
      inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
      activities: this.mapActivities(group.activities ?? []),
    };
  }

  private toGroupDetail(group: SocialGroup, userId: string) {
    const members = this.sortMembers(group.members ?? []);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt, group.competitionType);
    const groupStreakDefeated = group.competitionType === 'group_streak' && members.some((member) => this.toNumber(member.streakDays) <= 0);

    return {
      group: {
        id: group.id,
        name: group.name,
        description: group.description,
        iconKey: group.iconKey,
        competitionType: group.competitionType,
        competitionLabel: this.competitionLabel(group.competitionType),
        durationDays: group.durationDays,
        durationDaysLabel: group.competitionType === 'group_streak' ? 'Infinito' : `${group.durationDays} dias`,
        isPublic: group.isPublic,
        inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
        memberCount: members.length,
        remainingDays,
        remainingDaysLabel: group.competitionType === 'group_streak'
          ? (groupStreakDefeated ? 'Sequência quebrada' : 'Infinito')
          : `${remainingDays} dias restantes`,
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
        points: member.points,
        streakDays: member.streakDays,
        isCurrentUser: member.userId === userId,
        isLeader: member.isLeader,
        position: index + 1,
        subtitle: member.isLeader ? 'Líder do grupo' : member.streakDays > 0 ? `${member.streakDays} dias de sequência` : 'Sequência',
      })),
      recentActivities: this.mapActivities(group.activities ?? []),
    };
  }

  private mapActivities(activities: SocialGroupActivity[]) {
    return activities.map((activity) => ({
      id: activity.id,
      message: activity.message,
      activityType: activity.activityType,
      createdAt: activity.createdAt,
      metadata: activity.metadata ?? null,
    }));
  }

  private sortMembers(members: SocialGroupMember[]) {
    return [...members].sort((left, right) => {
      const pointsDelta = this.toNumber(right.points) - this.toNumber(left.points);
      if (pointsDelta !== 0) return pointsDelta;

      const streakDelta = this.toNumber(right.streakDays) - this.toNumber(left.streakDays);
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

  private competitionLabel(competitionType: string) {
    return ({ offensive: 'Ofensiva', daily_goal: 'Meta diária', xp: 'XP', group_streak: 'Sequência dos amigos' }[competitionType] ?? 'Ofensiva');
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
    return randomBytes(4).toString('hex').toUpperCase();
  }

  private toNumber(value: unknown) {
    if (typeof value === 'number') return Number.isFinite(value) ? value : 0;
    if (typeof value === 'string') {
      const parsed = Number(value.replace(',', '.'));
      return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
  }

  private getFavoriteDish(meals: Array<Pick<Meal, 'title'>>) {
    if (!meals.length) return null;

    const titleCounts = new Map<string, number>();
    for (const meal of meals) {
      const normalized = meal.title.trim().toLowerCase();
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
