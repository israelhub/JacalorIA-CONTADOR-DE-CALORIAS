import { Controller, Post, Get, Patch, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendCodeDto } from './dto/resend-code.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ValidateResetCodeDto } from './dto/validate-reset-code.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('google')
  async signInWithGoogle(@Body() dto: GoogleAuthDto) {
    try {
      return await this.authService.signInWithGoogle(dto);
    } catch (error) {
      console.error('[AUTH][GOOGLE] controller error', error);
      throw error;
    }
  }

  @Post('email/verify')
  verifyEmail(@Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(dto);
  }

  @Post('email/resend-code')
  resendCode(@Body() dto: ResendCodeDto) {
    return this.authService.resendCode(dto);
  }

  @Post('password/forgot')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Post('password/reset')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  @Post('password/validate-code')
  validateResetCode(@Body() dto: ValidateResetCodeDto) {
    return this.authService.validateResetCode(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  getProfile(@Request() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  updateProfile(@Request() req, @Body() dto: UpdateProfileDto) {
    return this.authService.updateProfile(req.user.sub, dto);
  }

  @Get('profile/dev')
  getProfileDev() {
    return this.authService.getFallbackProfile();
  }

  @Patch('profile/dev')
  async updateProfileDev(@Body() dto: UpdateProfileDto) {
    const devProfile = await this.authService.getFallbackProfile();
    return this.authService.updateProfile(devProfile.id, dto);
  }
}
