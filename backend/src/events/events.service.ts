import { Injectable, NotFoundException } from '@nestjs/common';
import { sticker_type } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly postSelect = {
    event_id: true,
    title: true,
    description: true,
    media_url: true,
    media_type: true,
    location: true,
    start_time: true,
    end_time: true,
    created_at: true,
    users: { select: { full_name: true } },
    event_stickers: {
      where: { type: sticker_type.registration_link },
      select: { label: true, target_url: true },
      take: 1,
    },
    _count: { select: { event_likes: true, event_comments: true } },
  } as const;

  async list() {
    const posts = await this.prisma.events.findMany({
      orderBy: [{ start_time: 'asc' }, { created_at: 'desc' }],
      select: this.postSelect,
    });

    return posts.map((post) => this.toPost(post));
  }

  async get(eventId: string) {
    const post = await this.prisma.events.findUnique({
      where: { event_id: eventId },
      select: this.postSelect,
    });

    if (!post) throw new NotFoundException('Event post not found.');
    return this.toPost(post);
  }

  private toPost(post: {
    event_id: string;
    title: string;
    description: string;
    media_url: string;
    media_type: 'image' | 'video' | null;
    location: string | null;
    start_time: Date;
    end_time: Date;
    created_at: Date | null;
    users: { full_name: string };
    event_stickers: { label: string; target_url: string | null }[];
    _count: { event_likes: number; event_comments: number };
  }) {
    return {
      id: post.event_id,
      title: post.title,
      description: post.description,
      mediaUrl: post.media_url,
      mediaType: post.media_type,
      location: post.location,
      startTime: post.start_time,
      endTime: post.end_time,
      createdAt: post.created_at,
      organizerName: post.users.full_name,
      registration: post.event_stickers[0]
        ? {
            label: post.event_stickers[0].label,
            targetUrl: post.event_stickers[0].target_url,
          }
        : null,
      likeCount: post._count.event_likes,
      commentCount: post._count.event_comments,
    };
  }
}
