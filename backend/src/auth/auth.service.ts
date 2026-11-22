
import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import bcrypt from 'bcryptjs';
import { randomBytes, createHash } from 'node:crypto';

import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { EmailService } from './email.service.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
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
    // Normalize email
    const email = dto.email.trim().toLowerCase();

    // Check whether the email already exists
    const existing = await this.prisma.users.findUnique({
      where: { email },
    });

    if (existing) {
      return {
        message:
          'If registration is possible, please check your email for further instructions.',
      };
    }

    // Hash the user's password
    const passwordHash = await bcrypt.hash(dto.password, 10);

    // Create the user account
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
      // Handle simultaneous registration attempts for the same email
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

    // Set token expiration to 15 minutes
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

    // Return registration response
    return {
      message:
        'If registration is possible, please check your email for further instructions.',
    };
  }
  // Verify user's email address
  async verifyEmail(token: string) {
    // Hash the token received from the email
    const tokenHash = createHash('sha256')
      .update(token)
      .digest('hex');

    // Find the matching verification token
    const verificationToken =
      await this.prisma.email_verification_tokens.findUnique({
        where: { token_hash: tokenHash },
      });

    // Check whether the token exists
    if (!verificationToken) {
      throw new ConflictException(
        'Invalid or expired verification link.',
      );
    }

    // Check whether the token has expired
    if (verificationToken.expires_at <= new Date()) {
      await this.prisma.email_verification_tokens.delete({
        where: { token_id: verificationToken.token_id },
      });

      throw new ConflictException(
        'Verification link has expired. Please request a new one.',
      );
    }

    // Mark the user's email as verified and consume the token
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

    // Find the registered user
    const user = await this.prisma.users.findUnique({
      where: { email },
    });

    // Return the same response if the account does not exist
    if (!user) {
      return {
        message:
          'If the account is eligible, a verification email will be sent.',
      };
    }

    // Return the same response if the email is already verified
    if (user.is_verified) {
      return {
        message:
          'If the account is eligible, a verification email will be sent.',
      };
    }

    // Delete previous verification tokens
    await this.prisma.email_verification_tokens.deleteMany({
      where: { user_id: user.user_id },
    });

    // Generate a new verification token
    const { token, tokenHash } = this.generateVerificationToken();

    // Set expiration to 15 minutes
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Store the new token
    await this.prisma.email_verification_tokens.create({
      data: {
        user_id: user.user_id,
        token_hash: tokenHash,
        expires_at: expiresAt,
      },
    });

    // Send the new verification email
    await this.emailService.sendVerificationEmail(email, token);

    return {
      message:
        'If the account is eligible, a verification email will be sent.',
    };
  }
}
