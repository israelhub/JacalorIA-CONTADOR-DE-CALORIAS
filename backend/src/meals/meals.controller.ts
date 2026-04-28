import {
  Controller,
  Get,
  Post,
  Body,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MealsService } from './meals.service';
import { CreateMealDto } from './dto/create-meal.dto';

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
  async findAll(@Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealsService.findAll(userId);
  }
}
