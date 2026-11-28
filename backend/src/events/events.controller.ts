import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { EventsService } from './events.service.js';

@ApiTags('Events')
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  // Event posts are public so guests can browse them too.
  @Get()
  list() {
    return this.eventsService.list();
  }

  @Get(':eventId')
  get(@Param('eventId') eventId: string) {
    return this.eventsService.get(eventId);
  }
}
