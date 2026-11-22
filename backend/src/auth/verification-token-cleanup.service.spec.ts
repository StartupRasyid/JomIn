import { Test, TestingModule } from '@nestjs/testing';
import { VerificationTokenCleanupService } from './verification-token-cleanup.service.js';

describe('VerificationTokenCleanupService', () => {
  let service: VerificationTokenCleanupService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [VerificationTokenCleanupService],
    }).compile();

    service = module.get<VerificationTokenCleanupService>(VerificationTokenCleanupService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
