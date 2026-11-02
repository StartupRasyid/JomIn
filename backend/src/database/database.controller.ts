import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';


@Controller('database')
export class DatabaseController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('health')
  async checkDatabase() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;

      return {
        status: 'success',
        database: 'connected',
        message: 'PostgreSQL connection is working!',
      };
    } catch (error) {
      return {
        status: 'error',
        database: 'disconnected',
        message: 'Could not connect to PostgreSQL.',
      };
    }
  }
}