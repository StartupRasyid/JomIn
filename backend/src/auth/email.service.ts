import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer, { Transporter } from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter: Transporter;

  constructor(private readonly configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('SMTP_HOST'),
      port: this.configService.get<number>('SMTP_PORT', 465),
      secure: true,
      auth: {
        user: this.configService.get<string>('SMTP_USER'),
        pass: this.configService.get<string>('SMTP_PASS'),
      },
    });
  }

  async sendVerificationEmail(email: string, token: string) {
    const frontendUrl = this.configService.get<string>('FRONTEND_URL');

    const verificationUrl =
      `${frontendUrl}/verify-email?token=${encodeURIComponent(token)}`;

    await this.transporter.sendMail({
      from: this.configService.get<string>('EMAIL_FROM'),
      to: email,
      subject: 'Verify your JomIn account',
      html: `
        <h2>Welcome to JomIn!</h2>
        <p>Thank you for registering.</p>
        <p>Please click the link below to verify your email address:</p>
        <a href="${verificationUrl}">Verify My Email</a>
        <p>This verification link will expire in 15 minutes.</p>
        <p>If you did not create this account, you can ignore this email.</p>
      `,
    });

    this.logger.log(`Verification email sent to ${email}`);
  }
}
