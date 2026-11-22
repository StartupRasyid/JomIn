import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const header = request.headers['authorization'] as string | undefined;
    const [type, token] = header?.split(' ') ?? [];

    if (type !== 'Bearer' || !token) {
      throw new UnauthorizedException('Missing or invalid token.');
    }

    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string; role: string }>(token);
      request.user = { userId: payload.sub, role: payload.role };
    } catch {
      throw new UnauthorizedException('Invalid or expired token.');
    }
    return true;
  }
}