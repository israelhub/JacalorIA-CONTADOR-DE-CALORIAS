import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Req,
  Param,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MealTemplatesService } from './meal-templates.service';
import { CreateMealTemplateDto } from './dto/create-meal-template.dto';

@Controller('meal-templates')
@UseGuards(JwtAuthGuard)
export class MealTemplatesController {
  constructor(private readonly mealTemplatesService: MealTemplatesService) {}

  @Post()
  async create(@Body() createDto: CreateMealTemplateDto, @Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealTemplatesService.create(createDto, userId);
  }

  @Get()
  async findAll(@Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.mealTemplatesService.findAll(userId);
  }

  @Patch(':id/delete')
  @HttpCode(HttpStatus.NO_CONTENT)
  async softDelete(@Param('id') id: string, @Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    await this.mealTemplatesService.softDelete(id, userId);
  }
}
