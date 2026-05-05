import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class AddFriendByEmailDto {
  @IsEmail()
  @MaxLength(160)
  email: string;
}
