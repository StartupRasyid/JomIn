
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class VerificationTokenCleanupService {
  private readonly logger = new Logger(
    VerificationTokenCleanupService.name,
  );

  constructor(private readonly prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_HOUR)
  async handleExpiredTokens() {
    const result = await this.prisma.email_verification_tokens.deleteMany({
      where: {
        expires_at: {
          lt: new Date(),
        },
      },
    });

    if (result.count > 0) {
      this.logger.log(
        `Deleted ${result.count} expired verification token(s).`,
      );
    }
  }
}
