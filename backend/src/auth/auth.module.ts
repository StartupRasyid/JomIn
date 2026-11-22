
import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { EmailService } from './email.service.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, EmailService],
})
export class AuthModule {}
