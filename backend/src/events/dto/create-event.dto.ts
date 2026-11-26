import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export enum MediaTypeDto {
  IMAGE = 'image',
  VIDEO = 'video',
}

export class CreateEventDto {
  @ApiProperty({ example: 'UTM AI Hackathon 2026' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title!: string;

  @ApiProperty({ example: 'Join us for a 24-hour hackathon!' })
  @IsString()
  @IsNotEmpty()
  description!: string;

  @ApiProperty({
    example:
      'https://yyuswgbbfdgfirmwbhxl.supabase.co/storage/v1/object/public/event-media/posters/poster.jpg',
  })
  @IsUrl()
  @IsNotEmpty()
  mediaUrl!: string;

  @ApiProperty({ enum: MediaTypeDto, default: MediaTypeDto.IMAGE })
  @IsEnum(MediaTypeDto)
  mediaType!: MediaTypeDto;

  @ApiPropertyOptional({ example: 'template_tech_01' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  templateId?: string;

  @ApiPropertyOptional({ example: 'Dewan Sultan Mizan, UTM JB' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  location?: string;

  @ApiProperty({ example: '2026-11-25T09:00:00.000Z' })
  @IsDateString()
  startTime!: string;

  @ApiProperty({ example: '2026-11-25T17:00:00.000Z' })
  @IsDateString()
  endTime!: string;
}