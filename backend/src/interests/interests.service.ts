import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CommitteeUnitDto, SaveOnboardingDto } from './dto/save-onboarding.dto.js';

const DEFAULT_INTERESTS = [
  'Hackathon',
  'Technical Workshop',
  'Fun Run',
  'Talk / Seminar',
  'Cultural Exhibition',
  'Sports Competition',
];

@Injectable()
export class InterestsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOnboardingOptions(userId: string) {
    let interests = await this.prisma.interests.findMany({
      orderBy: { name: 'asc' },
    });

    // Ensure baseline interests exist if table is empty
    if (interests.length === 0) {
      await this.prisma.interests.createMany({
        data: DEFAULT_INTERESTS.map((name) => ({ name })),
        skipDuplicates: true,
      });
      interests = await this.prisma.interests.findMany({
        orderBy: { name: 'asc' },
      });
    }

    const existingSelections = await this.prisma.student_interests.findMany({
      where: { user_id: userId },
      select: { interest_id: true },
    });

    const profile = await this.prisma.student_profiles.findUnique({
      where: { user_id: userId },
      select: { personality_summary: true },
    });

    const selectedInterestIds = existingSelections.map((s) => s.interest_id);
    const hasCompletedOnboarding =
      selectedInterestIds.length > 0 || Boolean(profile?.personality_summary);

    return {
      hasCompletedOnboarding,
      interests: interests.map((i) => ({
        id: i.interest_id,
        name: i.name,
      })),
      roles: Object.values(CommitteeUnitDto),
      selectedInterestIds,
    };
  }

  async saveUserOnboarding(userId: string, dto: SaveOnboardingDto) {
    const validInterests = await this.prisma.interests.findMany({
      where: { interest_id: { in: dto.interestIds } },
      select: { interest_id: true },
    });

    if (validInterests.length !== dto.interestIds.length) {
      throw new BadRequestException('One or more selected interests are invalid.');
    }

    const rolesSummary = `Preferred roles: ${dto.roles.join(', ')}`;

    await this.prisma.$transaction([
      this.prisma.student_interests.deleteMany({
        where: { user_id: userId },
      }),
      this.prisma.student_interests.createMany({
        data: dto.interestIds.map((interestId) => ({
          user_id: userId,
          interest_id: interestId,
        })),
        skipDuplicates: true,
      }),
      this.prisma.student_profiles.upsert({
        where: { user_id: userId },
        update: { personality_summary: rolesSummary },
        create: {
          user_id: userId,
          personality_summary: rolesSummary,
        },
      }),
    ]);

    return {
      message: 'Preferences saved.',
      interestIds: dto.interestIds,
      roles: dto.roles,
    };
  }
}