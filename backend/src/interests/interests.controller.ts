import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, type AuthUser } from '../auth/current-user.decorator.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { SaveOnboardingDto } from './dto/save-onboarding.dto.js';
import { InterestsService } from './interests.service.js';

@ApiTags('Interests')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('interests')
export class InterestsController {
  constructor(private readonly interestsService: InterestsService) {}

  @Get()
  getOnboardingOptions(@CurrentUser() user: AuthUser) {
    return this.interestsService.getOnboardingOptions(user.userId);
  }

  @Post('me')
  saveUserOnboarding(
    @CurrentUser() user: AuthUser,
    @Body() dto: SaveOnboardingDto,
  ) {
    return this.interestsService.saveUserOnboarding(user.userId, dto);
  }
}