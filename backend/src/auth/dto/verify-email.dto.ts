
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class VerifyEmailDto {
  @ApiProperty({
    example: 'your-verification-token',
    description: 'Email verification token received through email',
  })
  @IsString()
  @IsNotEmpty()
  token!: string;
}
