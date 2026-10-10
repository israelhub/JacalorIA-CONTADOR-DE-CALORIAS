import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Transaction } from 'sequelize';
import { Sequelize } from 'sequelize-typescript';
import { parseNumber } from '../shared/utils/number-parser.util';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { UpsertLoadDto } from './dto/upsert-load.dto';
import { WorkoutExercise } from './models/workout-exercise.model';
import { WorkoutLoadEntry } from './models/workout-load-entry.model';
import { WorkoutRoutine } from './models/workout-routine.model';
import { WorkoutImportProvider } from './workout-import.provider';
import {
  ImportedRoutine,
  normalizeRoutineName,
  toDateOnly,
} from './workout-import.util';

const LOAD_HISTORY_LIMIT = 12;

@Injectable()
export class WorkoutsService {
  constructor(
    @InjectModel(WorkoutRoutine)
    private readonly routineModel: typeof WorkoutRoutine,
    @InjectModel(WorkoutExercise)
    private readonly exerciseModel: typeof WorkoutExercise,
    @InjectModel(WorkoutLoadEntry)
    private readonly loadModel: typeof WorkoutLoadEntry,
    private readonly workoutImportProvider: WorkoutImportProvider,
    private readonly sequelize: Sequelize,
  ) {}

  async list(userId: string) {
    const routines = await this.routineModel.findAll({
      where: { userId },
      include: [
        {
          model: WorkoutExercise,
          include: [
            {
              model: WorkoutLoadEntry,
              separate: true,
              limit: LOAD_HISTORY_LIMIT,
              order: [
                ['recordedAt', 'DESC'],
                ['createdAt', 'DESC'],
              ],
            },
          ],
        },
      ],
      order: [
        ['sortOrder', 'ASC'],
        ['createdAt', 'ASC'],
        [{ model: WorkoutExercise, as: 'exercises' }, 'sortOrder', 'ASC'],
        [{ model: WorkoutExercise, as: 'exercises' }, 'createdAt', 'ASC'],
      ],
    });

    return {
      routines: routines.map((routine) => this.serializeRoutine(routine)),
    };
  }

  async createRoutine(userId: string, dto: CreateRoutineDto) {
    const name = this.requireRoutineName(dto.name);
    const maxSort = await this.routineModel.max('sortOrder', { where: { userId } });
    const routine = await this.routineModel.create({
      userId,
      name,
      sortOrder: (Number(maxSort) || 0) + 1,
    });
    return this.getRoutineOrThrow(userId, routine.id);
  }

  async updateRoutine(userId: string, routineId: string, dto: UpdateRoutineDto) {
    const routine = await this.findRoutineOrThrow(userId, routineId);
    if (dto.name !== undefined) {
      routine.name = this.requireRoutineName(dto.name);
    }
    await routine.save();
    return this.getRoutineOrThrow(userId, routineId);
  }

  async deleteRoutine(userId: string, routineId: string) {
    const routine = await this.findRoutineOrThrow(userId, routineId);
    await routine.destroy();
  }

  async createExercise(userId: string, routineId: string, dto: CreateExerciseDto) {
    await this.findRoutineOrThrow(userId, routineId);
    const maxSort = await this.exerciseModel.max('sortOrder', {
      where: { routineId },
    });
    const exercise = await this.exerciseModel.create({
      userId,
      routineId,
      name: this.requireExerciseName(dto.name),
      sets: dto.sets,
      reps: dto.reps,
      sortOrder: (Number(maxSort) || 0) + 1,
    });
    return this.serializeExercise(
      await this.findExerciseOrThrow(userId, exercise.id),
    );
  }

  async updateExercise(userId: string, exerciseId: string, dto: UpdateExerciseDto) {
    const exercise = await this.findExerciseOrThrow(userId, exerciseId);
    if (dto.name !== undefined) {
      exercise.name = this.requireExerciseName(dto.name);
    }
    if (dto.sets !== undefined) {
      exercise.sets = dto.sets;
    }
    if (dto.reps !== undefined) {
      exercise.reps = dto.reps;
    }
    await exercise.save();
    return this.serializeExercise(
      await this.findExerciseOrThrow(userId, exerciseId),
    );
  }

  async deleteExercise(userId: string, exerciseId: string) {
    const exercise = await this.findExerciseOrThrow(userId, exerciseId);
    await exercise.destroy();
  }

  async upsertLoad(userId: string, exerciseId: string, dto: UpsertLoadDto) {
    await this.findExerciseOrThrow(userId, exerciseId);
    const recordedAt = this.requireDate(dto.recordedAt);
    const weight = parseNumber(dto.weight, NaN);
    if (!Number.isFinite(weight)) {
      throw new BadRequestException('Peso inválido');
    }

    const existing = await this.loadModel.findOne({
      where: { userId, exerciseId, recordedAt },
    });

    if (existing) {
      existing.weight = weight;
      await existing.save();
    } else {
      await this.loadModel.create({
        userId,
        exerciseId,
        weight,
        recordedAt,
      });
    }

    return this.serializeExercise(
      await this.findExerciseOrThrow(userId, exerciseId),
    );
  }

  async deleteLoad(userId: string, loadId: string) {
    const load = await this.loadModel.findOne({
      where: { id: loadId, userId },
    });
    if (!load) {
      throw new NotFoundException('Registro de carga não encontrado');
    }
    await load.destroy();
  }

  async importFromText(userId: string, text: string) {
    const parsed = await this.workoutImportProvider.parseNotes(text);
    await this.sequelize.transaction(async (transaction) => {
      for (const [routineIndex, importedRoutine] of parsed.entries()) {
        await this.mergeImportedRoutine(
          userId,
          importedRoutine,
          routineIndex,
          transaction,
        );
      }
    });
    return this.list(userId);
  }

  private async mergeImportedRoutine(
    userId: string,
    imported: ImportedRoutine,
    fallbackSort: number,
    transaction: Transaction,
  ) {
    const existing = await this.routineModel.findAll({
      where: { userId },
      transaction,
    });
    let routine = existing.find(
      (item) => item.name.trim().toLowerCase() === imported.name.toLowerCase(),
    );
    if (!routine) {
      const maxSort = existing.reduce(
        (max, item) => Math.max(max, item.sortOrder ?? 0),
        0,
      );
      routine = await this.routineModel.create(
        {
          userId,
          name: imported.name,
          sortOrder: maxSort + 1 + fallbackSort,
        },
        { transaction },
      );
    }

    const exercises = await this.exerciseModel.findAll({
      where: { userId, routineId: routine.id },
      transaction,
    });

    for (const [exerciseIndex, importedExercise] of imported.exercises.entries()) {
      let exercise = exercises.find(
        (item) =>
          item.name.trim().toLowerCase() === importedExercise.name.toLowerCase(),
      );
      if (!exercise) {
        const maxSort = exercises.reduce(
          (max, item) => Math.max(max, item.sortOrder ?? 0),
          0,
        );
        exercise = await this.exerciseModel.create(
          {
            userId,
            routineId: routine.id,
            name: importedExercise.name,
            sets: importedExercise.sets,
            reps: importedExercise.reps,
            sortOrder: maxSort + 1 + exerciseIndex,
          },
          { transaction },
        );
        exercises.push(exercise);
      } else {
        exercise.sets = importedExercise.sets;
        exercise.reps = importedExercise.reps;
        await exercise.save({ transaction });
      }

      for (const load of importedExercise.loads) {
        const existingLoad = await this.loadModel.findOne({
          where: {
            userId,
            exerciseId: exercise.id,
            recordedAt: load.recordedAt,
          },
          transaction,
        });
        if (existingLoad) {
          existingLoad.weight = load.weight;
          await existingLoad.save({ transaction });
        } else {
          await this.loadModel.create(
            {
              userId,
              exerciseId: exercise.id,
              weight: load.weight,
              recordedAt: load.recordedAt,
            },
            { transaction },
          );
        }
      }
    }
  }

  private async getRoutineOrThrow(userId: string, routineId: string) {
    const routine = await this.routineModel.findOne({
      where: { id: routineId, userId },
      include: [
        {
          model: WorkoutExercise,
          include: [
            {
              model: WorkoutLoadEntry,
              separate: true,
              limit: LOAD_HISTORY_LIMIT,
              order: [
                ['recordedAt', 'DESC'],
                ['createdAt', 'DESC'],
              ],
            },
          ],
        },
      ],
      order: [
        [{ model: WorkoutExercise, as: 'exercises' }, 'sortOrder', 'ASC'],
        [{ model: WorkoutExercise, as: 'exercises' }, 'createdAt', 'ASC'],
      ],
    });
    if (!routine) {
      throw new NotFoundException('Treino não encontrado');
    }
    return this.serializeRoutine(routine);
  }

  private async findRoutineOrThrow(userId: string, routineId: string) {
    const routine = await this.routineModel.findOne({
      where: { id: routineId, userId },
    });
    if (!routine) {
      throw new NotFoundException('Treino não encontrado');
    }
    return routine;
  }

  private async findExerciseOrThrow(userId: string, exerciseId: string) {
    const exercise = await this.exerciseModel.findOne({
      where: { id: exerciseId, userId },
      include: [
        {
          model: WorkoutLoadEntry,
          separate: true,
          limit: LOAD_HISTORY_LIMIT,
          order: [
            ['recordedAt', 'DESC'],
            ['createdAt', 'DESC'],
          ],
        },
      ],
    });
    if (!exercise) {
      throw new NotFoundException('Exercício não encontrado');
    }
    return exercise;
  }

  private serializeRoutine(routine: WorkoutRoutine) {
    const exercises = [...(routine.exercises ?? [])].sort((a, b) => {
      const sort = (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
      if (sort !== 0) {
        return sort;
      }
      return a.createdAt.getTime() - b.createdAt.getTime();
    });

    return {
      id: routine.id,
      name: routine.name,
      sortOrder: routine.sortOrder,
      exercises: exercises.map((exercise) => this.serializeExercise(exercise)),
    };
  }

  private serializeExercise(exercise: WorkoutExercise) {
    const loads = [...(exercise.loads ?? [])]
      .map((load) => this.serializeLoad(load))
      .sort((a, b) => b.recordedAt.localeCompare(a.recordedAt));
    const lastLoad = loads[0] ?? null;
    const previousLoad = loads[1] ?? null;

    return {
      id: exercise.id,
      routineId: exercise.routineId,
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      sortOrder: exercise.sortOrder,
      lastLoad,
      previousLoad,
      loads,
    };
  }

  private serializeLoad(load: WorkoutLoadEntry) {
    return {
      id: load.id,
      weight: parseNumber(load.weight),
      recordedAt: String(load.recordedAt).slice(0, 10),
    };
  }

  private requireRoutineName(name: string) {
    const normalized = normalizeRoutineName(name);
    if (!normalized) {
      throw new BadRequestException('Dê um nome para o treino');
    }
    return normalized;
  }

  private requireExerciseName(name: string) {
    const normalized = name.replace(/\s+/g, ' ').trim().slice(0, 80);
    if (!normalized) {
      throw new BadRequestException('Dê um nome para o exercício');
    }
    return normalized;
  }

  private requireDate(value: string) {
    const date = toDateOnly(value, new Date().getFullYear());
    if (!date) {
      throw new BadRequestException('Data inválida');
    }
    return date;
  }
}
