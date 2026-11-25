import { ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsEnum, IsUUID } from 'class-validator';

export enum CommitteeUnitDto {
  ACTIVITY = 'Activity',
  MULTIMEDIA = 'Multimedia',
  FOOD = 'Food',
  TECHNICAL = 'Technical',
  PROTOCOL = 'Protocol',
  SPONSORSHIP = 'Sponsorship',
}

export class SaveOnboardingDto {
  @ApiProperty({
    type: [String],
    example: ['11111111-1111-1111-1111-111111111111'],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'Select at least one interest.' })
  @IsUUID('4', { each: true })
  interestIds!: string[];

  @ApiProperty({
    enum: CommitteeUnitDto,
    isArray: true,
    example: [CommitteeUnitDto.TECHNICAL, CommitteeUnitDto.MULTIMEDIA],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'Select at least one role of interest.' })
  @IsEnum(CommitteeUnitDto, { each: true })
  roles!: CommitteeUnitDto[];
}