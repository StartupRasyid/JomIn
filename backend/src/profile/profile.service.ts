import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js'; 

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}

  async getMyProfile(userId: string) {
    // Notice we use 'users' (lowercase) because that's what's in your schema
    const user = await this.prisma.users.findUnique({
      where: { user_id: userId }, // using user_id
      select: {
        user_id: true,
        full_name: true,   // using full_name
        faculty: true,
        year_of_study: true, // using year_of_study
        student_profiles: true, // using student_profiles (it's a 1-to-1 relation so it returns an object)
        events: { 
          orderBy: { created_at: 'desc' },
          select: {
            event_id: true,
            title: true,
            media_url: true,
          }
        },
        _count: {
          select: {
            events: true, 
          }
        }
      }
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }
}