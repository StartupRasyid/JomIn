import { Controller, Get, Req } from '@nestjs/common';
import { ProfileService } from './profile.service.js'; 

@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get('me')
  async getMyProfile(@Req() req: any) {
    // You need to put a REAL user_id from your Supabase database here for testing!
    // Go to Supabase Table Editor -> users -> copy a UUID.
    const testUserId = 'PUT-A-REAL-UUID-FROM-YOUR-SUPABASE-HERE'; 
    
    return this.profileService.getMyProfile(testUserId);
  }
}