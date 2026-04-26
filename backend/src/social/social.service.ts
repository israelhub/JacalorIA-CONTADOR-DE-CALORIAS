import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { randomBytes } from 'crypto';
import { User } from '../auth/models/user.model';
import { CreateSocialGroupDto } from './dto/create-social-group.dto';
import { UpdateSocialGroupDto } from './dto/update-social-group.dto';
import { SocialGroupActivity } from './models/social-group-activity.model';
import { SocialGroupMember } from './models/social-group-member.model';
import { SocialGroup } from './models/social-group.model';

type SocialGroupMemberWithUser = SocialGroupMember & { user?: User | null };

@Injectable()
export class SocialService {
  constructor(
    @InjectModel(SocialGroup)
    private readonly socialGroupModel: typeof SocialGroup,
    @InjectModel(SocialGroupMember)
    private readonly socialGroupMemberModel: typeof SocialGroupMember,
    @InjectModel(SocialGroupActivity)
    private readonly socialGroupActivityModel: typeof SocialGroupActivity,
    @InjectModel(User)
    private readonly userModel: typeof User,
  ) {}

  async listGroups(userId: string) {
    const groups = await this.socialGroupModel.findAll({
      include: [
        {
          model: SocialGroupMember,
          as: 'members',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'name', 'avatarUrl'],
            },
          ],
        },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          limit: 3,
          order: [['createdAt', 'DESC']],
        },
        {
          model: User,
          as: 'owner',
          attributes: ['id', 'name', 'avatarUrl'],
        },
      ],
      order: [['createdAt', 'DESC']],
    });

    const summaries = groups
      .filter((group) => this.isCurrentUserMember(group.members, userId))
      .map((group) => this.toGroupSummary(group, userId));

    return { groups: summaries };
  }

  async createGroup(userId: string, dto: CreateSocialGroupDto) {
    const user = await this.userModel.findByPk(userId, {
      attributes: ['id', 'name'],
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    const inviteCode = this.generateInviteCode();
    const now = new Date();
    const durationDays = dto.durationDays ?? 7;
    const endsAt = this.addDays(now, durationDays);

    const group = await this.socialGroupModel.create({
      ownerId: userId,
      name: dto.name.trim(),
      description: dto.description.trim(),
      competitionType: dto.competitionType,
      iconKey: dto.iconKey,
      durationDays,
      startsAt: now,
      endsAt,
      inviteCode,
    } as never);

    await this.socialGroupMemberModel.create({
      groupId: group.id,
      userId,
      isLeader: true,
      points: 0,
      streakDays: 0,
    });

    await this.socialGroupActivityModel.create({
      groupId: group.id,
      userId,
      activityType: 'created',
      message: `${user.name ?? 'Você'} criou o grupo`,
      metadata: { competitionType: dto.competitionType },
    });

    return this.getGroupDetail(group.id, userId);
  }

  async updateGroup(groupId: string, userId: string, dto: UpdateSocialGroupDto) {
    const group = await this.socialGroupModel.findByPk(groupId, {
      include: [
        {
          model: SocialGroupMember,
          as: 'members',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'name', 'avatarUrl'],
            },
          ],
        },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          order: [['createdAt', 'DESC']],
        },
        {
          model: User,
          as: 'owner',
          attributes: ['id', 'name', 'avatarUrl'],
        },
      ],
    });

    if (!group || !this.isCurrentUserMember(group.members, userId)) {
      throw new NotFoundException('Grupo não encontrado');
    }

    const currentUser = this.findCurrentUserMember(group.members, userId);
    if (!currentUser?.isLeader && group.ownerId !== userId) {
      throw new BadRequestException('Apenas o líder pode editar o grupo');
    }

    const durationDays = dto.durationDays ?? group.durationDays;
    await group.update({
      name: dto.name?.trim() ?? group.name,
      description: dto.description?.trim() ?? group.description,
      competitionType: dto.competitionType ?? group.competitionType,
      iconKey: dto.iconKey ?? group.iconKey,
      durationDays,
      endsAt: this.addDays(group.startsAt, durationDays),
    } as never);

    if (dto.durationDays != null || dto.competitionType || dto.iconKey) {
      await this.socialGroupActivityModel.create({
        groupId: group.id,
        userId,
        activityType: 'updated',
        message: 'Você atualizou as informações do grupo',
        metadata: {
          durationDays,
          competitionType: dto.competitionType ?? group.competitionType,
          iconKey: dto.iconKey ?? group.iconKey,
        },
      });
    }

    return this.getGroupDetail(group.id, userId);
  }

  async getGroupDetail(groupId: string, userId: string) {
    const group = await this.socialGroupModel.findByPk(groupId, {
      include: [
        {
          model: SocialGroupMember,
          as: 'members',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'name', 'avatarUrl'],
            },
          ],
        },
        {
          model: SocialGroupActivity,
          as: 'activities',
          separate: true,
          order: [['createdAt', 'DESC']],
        },
        {
          model: User,
          as: 'owner',
          attributes: ['id', 'name', 'avatarUrl'],
        },
      ],
    });

    if (!group || !this.isCurrentUserMember(group.members, userId)) {
      throw new NotFoundException('Grupo não encontrado');
    }

    return this.toGroupDetail(group, userId);
  }

  private toGroupSummary(group: SocialGroup, userId: string) {
    const members = this.sortMembers(group.members ?? []);
    const currentUser = this.findCurrentUserMember(members, userId);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt);

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      iconKey: group.iconKey,
      competitionType: group.competitionType,
      competitionLabel: this.competitionLabel(group.competitionType),
      durationDays: group.durationDays,
      durationDaysLabel: `${group.durationDays} dias`,
      memberCount: members.length,
      rankPosition: currentUser ? members.indexOf(currentUser) + 1 : members.length,
      points: currentUser?.points ?? 0,
      streakDays: currentUser?.streakDays ?? 0,
      leaderName: topMember?.user?.name ?? group.owner?.name ?? 'Líder do grupo',
      leaderLabel:
        currentUser?.isLeader || topMember?.userId === userId
          ? 'Você lidera'
          : `${topMember?.user?.name ?? 'Líder'} lidera`,
      remainingDays,
      remainingDaysLabel: `${remainingDays} dias restantes`,
      inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
      activities: this.mapActivities(group.activities ?? []),
    };
  }

  private toGroupDetail(group: SocialGroup, userId: string) {
    const members = this.sortMembers(group.members ?? []);
    const currentUser = this.findCurrentUserMember(members, userId);
    const topMember = members[0];
    const remainingDays = this.getRemainingDays(group.endsAt);

    return {
      group: {
        id: group.id,
        name: group.name,
        description: group.description,
        iconKey: group.iconKey,
        competitionType: group.competitionType,
        competitionLabel: this.competitionLabel(group.competitionType),
        durationDays: group.durationDays,
        durationDaysLabel: `${group.durationDays} dias`,
        inviteCode: (group as SocialGroup & { inviteCode?: string }).inviteCode ?? null,
        memberCount: members.length,
        remainingDays,
        remainingDaysLabel: `${remainingDays} dias restantes`,
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
        subtitle: member.isLeader
          ? 'Líder do grupo'
          : member.streakDays > 0
          ? `${member.streakDays} dias de sequência`
          : 'Sequência',
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
      if (pointsDelta !== 0) {
        return pointsDelta;
      }

      const streakDelta = this.toNumber(right.streakDays) - this.toNumber(left.streakDays);
      if (streakDelta !== 0) {
        return streakDelta;
      }

      return new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime();
    });
  }

  private findCurrentUserMember(
    members: SocialGroupMember[],
    userId: string,
  ): SocialGroupMember | undefined {
    return members.find((member) => member.userId === userId);
  }

  private isCurrentUserMember(members: SocialGroupMember[] | undefined, userId: string) {
    return Boolean(members?.some((member) => member.userId === userId));
  }

  private competitionLabel(competitionType: string) {
    return (
      {
        offensive: 'Ofensiva',
        daily_goal: 'Meta diária',
        calories: 'Calorias',
        xp: 'XP',
      }[competitionType] ?? 'Ofensiva'
    );
  }

  private getRemainingDays(endsAt: Date) {
    const diff = new Date(endsAt).getTime() - Date.now();
    const days = Math.ceil(diff / (24 * 60 * 60 * 1000));
    return Math.max(days, 0);
  }

  private addDays(date: Date, days: number) {
    const next = new Date(date);
    next.setUTCDate(next.getUTCDate() + days);
    return next;
  }

  private generateInviteCode() {
    return randomBytes(3).toString('hex').toUpperCase();
  }

  private toNumber(value: unknown) {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : 0;
    }

    if (typeof value === 'string') {
      const parsed = Number(value.replace(',', '.'));
      return Number.isFinite(parsed) ? parsed : 0;
    }

    return 0;
  }
}