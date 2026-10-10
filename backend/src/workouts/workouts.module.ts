import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { WorkoutExercise } from './models/workout-exercise.model';
import { WorkoutLoadEntry } from './models/workout-load-entry.model';
import { WorkoutRoutine } from './models/workout-routine.model';
import { WorkoutImportProvider } from './workout-import.provider';
import { WorkoutsController } from './workouts.controller';
import { WorkoutsService } from './workouts.service';

@Module({
  imports: [
    SequelizeModule.forFeature([
      WorkoutRoutine,
      WorkoutExercise,
      WorkoutLoadEntry,
    ]),
  ],
  controllers: [WorkoutsController],
  providers: [WorkoutsService, WorkoutImportProvider],
})
export class WorkoutsModule {}
