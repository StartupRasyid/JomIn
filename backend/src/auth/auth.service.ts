import { ConflictException, Injectable } from '@nestjs/common';
import bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { LoginDto } from './dto/login.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();

    const existing = await this.prisma.users.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.users.create({
      data: {
        email,
        password_hash: passwordHash,
        full_name: dto.fullName.trim(),
        faculty: dto.faculty,
        year_of_study: dto.yearOfStudy,
      },
      select: {
        user_id: true,
        email: true,
        full_name: true,
        role: true,
        faculty: true,
        year_of_study: true,
        created_at: true,
      },
    });

    return {
      id: user.user_id,
      email: user.email,
      fullName: user.full_name,
      role: user.role,
      faculty: user.faculty,
      yearOfStudy: user.year_of_study,
      createdAt: user.created_at,
    };
  }

  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();

    const user = await this.prisma.users.findUnique({ where: { email } });
    const passwordOk = user
      ? await bcrypt.compare(dto.password, user.password_hash)
      : false;

    // Same message for "no such email" and "wrong password"
    if (!user || !passwordOk) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const accessToken = await this.jwtService.signAsync({
      sub: user.user_id,
      role: user.role,
    });

    return {
      accessToken,
      user: {
        id: user.user_id,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
      },
    };
  }

  async getMe(userId: string) {
    const user = await this.prisma.users.findUnique({ where: { user_id: userId } });
    if (!user) throw new UnauthorizedException('Account no longer exists.');
    return {
      id: user.user_id,
      email: user.email,
      fullName: user.full_name,
      role: user.role,
      faculty: user.faculty,
      yearOfStudy: user.year_of_study,
      createdAt: user.created_at,
    };
  }
  
}