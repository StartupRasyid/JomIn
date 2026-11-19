import { user_role } from '../../generated/prisma/enums.js';

export interface AuthenticatedUser {
  user_id: string;
  role: user_role | null;
}