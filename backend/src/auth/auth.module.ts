
import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { EmailService } from './email.service.js';
import { VerificationTokenCleanupService } from './verification-token-cleanup.service.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, EmailService, VerificationTokenCleanupService],
})
export class AuthModule {}
