import { user_role } from '../../generated/prisma/enums.js';

export interface AuthenticatedUser {
  userId: string;
  role: user_role | null;
}