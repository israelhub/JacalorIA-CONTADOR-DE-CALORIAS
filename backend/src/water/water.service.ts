import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { toDateOnly } from '../workouts/workout-import.util';
import { AddWaterDto } from './dto/add-water.dto';
import { WaterIntakeEntry } from './models/water-intake-entry.model';
import {
  MAX_DAILY_WATER_ML,
  resolveDailyWaterGoalMl,
  shiftDateOnly,
  toDateOnlyOrToday,
} from './water.util';

@Injectable()
export class WaterService {
  constructor(
    @InjectModel(WaterIntakeEntry)
    private readonly waterModel: typeof WaterIntakeEntry,
    @InjectModel(User)
    private readonly userModel: typeof User,
  ) {}

  async list(userId: string, startDate?: string, endDate?: string) {
    const end = toDateOnlyOrToday(endDate);
    const start = startDate
      ? this.requireDate(startDate)
      : shiftDateOnly(end, -6);
    if (start > end) {
      throw new BadRequestException('Intervalo de datas inválido');
    }

    const [user, entries] = await Promise.all([
      this.userModel.findByPk(userId, { attributes: ['weight'] }),
      this.waterModel.findAll({
        where: {
          userId,
          recordedAt: { [Op.between]: [start, end] },
        },
        order: [['recordedAt', 'ASC']],
      }),
    ]);

    return {
      goalMl: resolveDailyWaterGoalMl(user?.weight),
      startDate: start,
      endDate: end,
      days: entries.map((entry) => this.serialize(entry)),
    };
  }

  async add(userId: string, dto: AddWaterDto) {
    const recordedAt = this.requireDate(dto.recordedAt);
    const increment = Math.round(dto.milliliters);
    const [entry] = await this.waterModel.findOrCreate({
      where: { userId, recordedAt },
      defaults: {
        userId,
        recordedAt,
        milliliters: 0,
      },
    });

    const next = Math.min(MAX_DAILY_WATER_ML, entry.milliliters + increment);
    if (next !== entry.milliliters) {
      entry.milliliters = next;
      await entry.save();
    }

    const user = await this.userModel.findByPk(userId, { attributes: ['weight'] });
    return {
      goalMl: resolveDailyWaterGoalMl(user?.weight),
      day: this.serialize(entry),
    };
  }

  private serialize(entry: WaterIntakeEntry) {
    return {
      id: entry.id,
      recordedAt: String(entry.recordedAt).slice(0, 10),
      milliliters: entry.milliliters,
    };
  }

  private requireDate(value: string) {
    const date = toDateOnly(value, new Date().getFullYear());
    if (!date) {
      throw new BadRequestException('Data inválida');
    }
    return date;
  }
}
