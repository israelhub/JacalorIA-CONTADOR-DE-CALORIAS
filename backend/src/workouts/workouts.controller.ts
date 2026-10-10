import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { ImportWorkoutsDto } from './dto/import-workouts.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { UpsertLoadDto } from './dto/upsert-load.dto';
import { WorkoutsService } from './workouts.service';

@Controller('workouts')
@UseGuards(JwtAuthGuard)
export class WorkoutsController {
  constructor(private readonly workoutsService: WorkoutsService) {}

  @Get()
  list(@Req() req: any) {
    return this.workoutsService.list(this.requireUserId(req));
  }

  @Post('import')
  importFromText(@Body() dto: ImportWorkoutsDto, @Req() req: any) {
    return this.workoutsService.importFromText(this.requireUserId(req), dto.text);
  }

  @Post('routines')
  createRoutine(@Body() dto: CreateRoutineDto, @Req() req: any) {
    return this.workoutsService.createRoutine(this.requireUserId(req), dto);
  }

  @Patch('routines/:id')
  updateRoutine(
    @Param('id') id: string,
    @Body() dto: UpdateRoutineDto,
    @Req() req: any,
  ) {
    return this.workoutsService.updateRoutine(this.requireUserId(req), id, dto);
  }

  @Delete('routines/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteRoutine(@Param('id') id: string, @Req() req: any) {
    return this.workoutsService.deleteRoutine(this.requireUserId(req), id);
  }

  @Post('routines/:id/exercises')
  createExercise(
    @Param('id') id: string,
    @Body() dto: CreateExerciseDto,
    @Req() req: any,
  ) {
    return this.workoutsService.createExercise(this.requireUserId(req), id, dto);
  }

  @Patch('exercises/:id')
  updateExercise(
    @Param('id') id: string,
    @Body() dto: UpdateExerciseDto,
    @Req() req: any,
  ) {
    return this.workoutsService.updateExercise(this.requireUserId(req), id, dto);
  }

  @Delete('exercises/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteExercise(@Param('id') id: string, @Req() req: any) {
    return this.workoutsService.deleteExercise(this.requireUserId(req), id);
  }

  @Post('exercises/:id/loads')
  upsertLoad(
    @Param('id') id: string,
    @Body() dto: UpsertLoadDto,
    @Req() req: any,
  ) {
    return this.workoutsService.upsertLoad(this.requireUserId(req), id, dto);
  }

  @Delete('loads/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteLoad(@Param('id') id: string, @Req() req: any) {
    return this.workoutsService.deleteLoad(this.requireUserId(req), id);
  }

  private requireUserId(req: any): string {
    const userId = req.user?.sub as string | undefined;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }
    return userId;
  }
}
