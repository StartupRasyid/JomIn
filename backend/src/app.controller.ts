
import { Controller, Get, UseGuards } from '@nestjs/common';
import { AppService } from './app.service.js';

import { RolesGuard } from './common/guards/roles.guard.js';
import { Roles } from './common/decorators/roles.decorator.js';
import { user_role } from './generated/prisma/enums.js';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }

  @UseGuards(RolesGuard)
  @Roles(user_role.admin)
  @Get('test-admin')
  testAdmin() {
    return { message: 'Admin access granted!' };
  }
}
