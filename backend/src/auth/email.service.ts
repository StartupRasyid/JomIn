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

  private getFrontendUrl(requestOrigin?: string) {
    const configuredUrl = this.configService.get<string>(
      'FRONTEND_URL',
      'http://localhost:8080',
    );
    const configured = new URL(configuredUrl);

    if (requestOrigin) {
      try {
        const origin = new URL(requestOrigin);
        const sameHost = origin.hostname === configured.hostname ||
          (['localhost', '127.0.0.1'].includes(origin.hostname) &&
            ['localhost', '127.0.0.1'].includes(configured.hostname));

        // Keep the configured app host, but honor Flutter's dynamic dev port.
        if (sameHost && origin.protocol === configured.protocol) {
          return origin.origin;
        }
      } catch {
        // Ignore malformed Origin values and use the configured frontend URL.
      }
    }

    return configured.origin;
  }

  async sendVerificationEmail(email: string, token: string, requestOrigin?: string) {
    const frontendUrl = this.getFrontendUrl(requestOrigin);

    // Flutter web uses hash-based routes by default; keep the token inside
    // the hash so GoRouter receives it as a query parameter.
    const verificationUrl =
      `${frontendUrl}/#/verify-email?token=${encodeURIComponent(token)}`;

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
