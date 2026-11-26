
import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface.js';
import { user_role } from '../generated/prisma/enums.js';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<{ headers: { authorization?: string }; user?: AuthenticatedUser }>();

    const header = request.headers.authorization;
    const [type, token] = header?.split(' ') ?? [];

    if (type !== 'Bearer' || !token) {
      throw new UnauthorizedException('Missing or invalid token.');
    }

    try {
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        role: user_role | null;
      }>(token);

      if (
        typeof payload.sub !== 'string' ||
        !payload.sub ||
        (payload.role !== null &&
          !Object.values(user_role).includes(payload.role))
      ) {
        throw new UnauthorizedException('Invalid token payload.');
      }

      request.user = {
        user_id: payload.sub,
        role: payload.role,
      };
    } catch {
      throw new UnauthorizedException('Invalid or expired token.');
    }

    return true;
  }
}
