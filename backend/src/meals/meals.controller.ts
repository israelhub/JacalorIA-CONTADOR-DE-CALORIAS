import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Req,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MealsService } from './meals.service';
import { CreateMealDto } from './dto/create-meal.dto';
import { UpdateMealDto } from './dto/update-meal.dto';

@Controller('meals')
@UseGuards(JwtAuthGuard)
export class MealsController {
  constructor(private readonly mealsService: MealsService) {}

  @Post()
  async create(@Body() createMealDto: CreateMealDto, @Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealsService.create(createMealDto, userId);
  }

  @Get()
  async findAll(
    @Req() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealsService.findAll(userId, {
      startDate,
      endDate,
    });
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateMealDto: UpdateMealDto,
    @Req() req: any,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealsService.update(id, updateMealDto, userId);
  }

  @Patch(':id/delete')
  @HttpCode(HttpStatus.NO_CONTENT)
  async softDelete(@Param('id') id: string, @Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    await this.mealsService.softDelete(id, userId);
  }
}
