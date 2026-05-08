import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { SocialController } from './social.controller';
import { SocialFriendLink } from './models/social-friend-link.model';
import { SocialFriendRequest } from './models/social-friend-request.model';
import { SocialFriendship } from './models/social-friendship.model';
import { SocialGroupActivity } from './models/social-group-activity.model';
import { SocialGroupMember } from './models/social-group-member.model';
import { SocialGroup } from './models/social-group.model';
import { SocialService } from './social.service';
import { StreakModule } from '../streak/streak.module';

@Module({
  imports: [
    StreakModule,
    SequelizeModule.forFeature([
      SocialGroup,
      SocialGroupMember,
      SocialGroupActivity,
      SocialFriendship,
      SocialFriendLink,
      SocialFriendRequest,
      User,
      Meal,
    ]),
  ],
  controllers: [SocialController],
  providers: [SocialService],
})
export class SocialModule {}
