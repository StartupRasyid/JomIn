import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import 'multer';

@Injectable()
export class EventsService {
  private readonly supabase: SupabaseClient;
  private readonly bucket = 'event-media';

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.supabase = createClient(
      this.config.getOrThrow<string>('SUPABASE_URL'),
      this.config.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  async uploadMedia(file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No media file provided.');
    }

    const isVideo = file.mimetype.startsWith('video/');
    const isImage = file.mimetype.startsWith('image/');
    if (!isImage && !isVideo) {
      throw new BadRequestException('Only image or video files are allowed.');
    }

    const ext = extname(file.originalname) || (isVideo ? '.mp4' : '.jpg');
    const filePath = `${isVideo ? 'videos' : 'posters'}/${randomUUID()}${ext}`;

    const { error } = await this.supabase.storage
      .from(this.bucket)
      .upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (error) {
      throw new InternalServerErrorException(`Upload failed: ${error.message}`);
    }

    const { data } = this.supabase.storage
      .from(this.bucket)
      .getPublicUrl(filePath);

    return {
      mediaUrl: data.publicUrl,
      mediaType: isVideo ? 'video' : 'image',
    };
  }

  async createEvent(organizerId: string, dto: CreateEventDto) {
    const start = new Date(dto.startTime);
    const end = new Date(dto.endTime);
    if (end <= start) {
      throw new BadRequestException('End time must be after start time.');
    }

    return this.prisma.events.create({
      data: {
        organizer_id: organizerId,
        title: dto.title.trim(),
        description: dto.description.trim(),
        media_url: dto.mediaUrl,
        media_type: dto.mediaType,
        template_id: dto.templateId,
        location: dto.location?.trim(),
        start_time: start,
        end_time: end,
      },
    });
  }
}