
import {
  ConflictException,
  Injectable,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';

import bcrypt from 'bcryptjs';
import { randomBytes, createHash } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { JwtService } from '@nestjs/jwt';
import { EmailService } from './email.service.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
  ) {}

  // Generate a secure email verification token
  private generateVerificationToken() {
    const token = randomBytes(32).toString('hex');

    const tokenHash = createHash('sha256')
      .update(token)
      .digest('hex');

    return { token, tokenHash };
  }

  // Register a new user
  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();

    const existing = await this.prisma.users.findUnique({
      where: { email },
    });

    // Avoid revealing whether an email is already registered
    if (existing) {
      return {
        message:
          'If registration is possible, please check your email for further instructions.',
      };
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, 10);

    // Create user
    let user;

    try {
      user = await this.prisma.users.create({
        data: {
          email,
          password_hash: passwordHash,
          full_name: dto.fullName.trim(),
          faculty: dto.faculty,
          year_of_study: dto.yearOfStudy,
        },
      });
    } catch (error) {
      // Handle duplicate email during simultaneous registrations
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2002'
      ) {
        return {
          message:
            'If registration is possible, please check your email for further instructions.',
        };
      }

      throw error;
    }

    // Generate verification token
    const { token, tokenHash } = this.generateVerificationToken();

    // Token expires after 15 minutes
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Store hashed token in database
    await this.prisma.email_verification_tokens.create({
      data: {
        user_id: user.user_id,
        token_hash: tokenHash,
        expires_at: expiresAt,
      },
    });

    // Send verification email
    await this.emailService.sendVerificationEmail(email, token);

    return {
      message:
        'If registration is possible, please check your email for further instructions.',
    };
  }

  // Verify user's email address
  async verifyEmail(token: string) {
    const tokenHash = createHash('sha256')
      .update(token)
      .digest('hex');

    // Find matching verification token
    const verificationToken =
      await this.prisma.email_verification_tokens.findUnique({
        where: { token_hash: tokenHash },
      });

    if (!verificationToken) {
      throw new ConflictException(
        'Invalid or expired verification link.',
      );
    }

    // Check expiration
    if (verificationToken.expires_at <= new Date()) {
      await this.prisma.email_verification_tokens.delete({
        where: { token_id: verificationToken.token_id },
      });

      throw new ConflictException(
        'Verification link has expired. Please request a new one.',
      );
    }

    // Verify user and consume token
    await this.prisma.$transaction([
      this.prisma.users.update({
        where: { user_id: verificationToken.user_id },
        data: { is_verified: true },
      }),
      this.prisma.email_verification_tokens.delete({
        where: { token_id: verificationToken.token_id },
      }),
    ]);

    return {
      message: 'Email verified successfully. You can now log in.',
    };
  }

  // Resend email verification link
  async resendVerificationEmail(emailInput: string) {
    const email = emailInput.trim().toLowerCase();

    const user = await this.prisma.users.findUnique({
      where: { email },
    });

    // Generic response for nonexistent accounts
    if (!user || user.is_verified) {
      return {
        message:
          'If the account is eligible, a verification email will be sent.',
      };
    }

    // Remove old verification tokens
    await this.prisma.email_verification_tokens.deleteMany({
      where: { user_id: user.user_id },
    });

    // Generate new token
    const { token, tokenHash } = this.generateVerificationToken();

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Store new token
    await this.prisma.email_verification_tokens.create({
      data: {
        user_id: user.user_id,
        token_hash: tokenHash,
        expires_at: expiresAt,
      },
    });

    // Send verification email
    await this.emailService.sendVerificationEmail(email, token);

    return {
      message:
        'If the account is eligible, a verification email will be sent.',
    };
  }

  // Login
  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();

    const user = await this.prisma.users.findUnique({
      where: { email },
    });

    const passwordOk = user
      ? await bcrypt.compare(dto.password, user.password_hash)
      : false;

    // Same error for nonexistent email and incorrect password
    if (!user || !passwordOk) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    // Require email verification before login
    if (!user.is_verified) {
      throw new ForbiddenException(
        'Please verify your email before logging in.',
      );
    }

    // Generate JWT
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

  // Get current authenticated user
  async getMe(userId: string) {
    const user = await this.prisma.users.findUnique({
      where: { user_id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('Account no longer exists.');
    }

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
