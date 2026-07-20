import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { AnalyticsEvent } from './models/analytics-event.model';
import { AnalyticsEventItemDto } from './dto/track-events.dto';
import { User } from '../auth/models/user.model';

export type TrackEventInput = {
  eventName: string;
  occurredAt?: Date | string;
  platform?: string | null;
  sessionId?: string | null;
  properties?: Record<string, unknown>;
};

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    @InjectModel(AnalyticsEvent)
    private readonly analyticsEventModel: typeof AnalyticsEvent,
    @InjectModel(User)
    private readonly userModel: typeof User,
  ) {}

  async trackMany(
    userId: string,
    events: AnalyticsEventItemDto[] | TrackEventInput[],
  ): Promise<{ accepted: number }> {
    if (!events.length) {
      return { accepted: 0 };
    }

    const rows = events.map((event) => ({
      userId,
      eventName: event.eventName,
      occurredAt: event.occurredAt
        ? new Date(event.occurredAt)
        : new Date(),
      platform: event.platform ?? null,
      sessionId: event.sessionId ?? null,
      properties: event.properties ?? {},
    }));

    await this.analyticsEventModel.bulkCreate(rows);

    const shouldTouchActive = events.some(
      (event) =>
        event.eventName === 'app_open' || event.eventName === 'meal_saved',
    );
    if (shouldTouchActive) {
      await this.userModel.update(
        { lastActiveAt: new Date() },
        { where: { id: userId } },
      );
    }

    return { accepted: rows.length };
  }

  async trackOne(userId: string, event: TrackEventInput): Promise<void> {
    await this.trackMany(userId, [event]);
  }

  /** Never throws — domain flows must not fail because of analytics. */
  async trackSafe(userId: string, event: TrackEventInput): Promise<void> {
    try {
      await this.trackOne(userId, event);
    } catch (error) {
      this.logger.warn(
        `Failed to track ${event.eventName} for ${userId}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }
}
