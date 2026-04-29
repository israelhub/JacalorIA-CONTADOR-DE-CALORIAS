import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { SocialController } from './social.controller';
import { SocialGroupActivity } from './models/social-group-activity.model';
import { SocialGroupMember } from './models/social-group-member.model';
import { SocialGroup } from './models/social-group.model';
import { SocialService } from './social.service';

@Module({
  imports: [SequelizeModule.forFeature([SocialGroup, SocialGroupMember, SocialGroupActivity, User])],
  controllers: [SocialController],
  providers: [SocialService],
})
export class SocialModule {}