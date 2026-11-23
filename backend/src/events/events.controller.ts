import {
  BadRequestException,
  Body,
  Controller,
  Post,
  Req,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { isUUID } from 'class-validator';
import { CreateEventDto } from './dto/create-event.dto.js';
import { EventsService } from './events.service.js';
import 'multer';

@ApiTags('events')
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post('upload')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB limit
    }),
  )
  uploadMedia(@UploadedFile() file: Express.Multer.File) {
    return this.eventsService.uploadMedia(file);
  }

  @Post()
  createEvent(@Req() req: any, @Body() dto: CreateEventDto) {
    // Once JWT AuthGuard (SS-76) is active, req.user.sub provides the logged-in organizer's user_id.
    // Fallback header 'x-user-id' allows testing in Swagger before AuthGuard is wired.
    const organizerId = req.user?.sub ?? req.headers['x-user-id'];
    if (!organizerId || !isUUID(organizerId)) {
      throw new BadRequestException('A valid organizer UUID is required.');
    }
    return this.eventsService.createEvent(organizerId, dto);
  }
}