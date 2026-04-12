import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from './models/user.model';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendCodeDto } from './dto/resend-code.dto';
import { MailService } from '../mail/mail.service';
import { AuthRepository } from './auth.repository';

@Injectable()
export class AuthService {
  private readonly SALT_ROUNDS = 12;
  private readonly CODE_EXPIRATION_MINUTES = 15;

  constructor(
    private readonly authRepository: AuthRepository,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.authRepository.findByEmail(dto.email);

    if (existing) {
      throw new ConflictException('Email já cadastrado');
    }

    const passwordHash = await bcrypt.hash(dto.password, this.SALT_ROUNDS);
    const verificationCode = this.generateCode();
    const verificationCodeExpiresAt = new Date(
      Date.now() + this.CODE_EXPIRATION_MINUTES * 60 * 1000,
    );

    const user = await this.authRepository.createUser({
      name: dto.name?.trim() || null,
      email: dto.email,
      passwordHash,
      verificationCode,
      verificationCodeExpiresAt,
    });

    const emailSent = await this.mailService.sendVerificationCode(
      user.email,
      verificationCode,
    );

    if (!emailSent) {
      console.log(`[DEV] Código de verificação para ${user.email}: ${verificationCode}`);
    }

    return {
      message: 'Conta criada com sucesso. Verifique seu email.',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.authRepository.findByEmail(dto.email);

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    if (!user.emailVerified) {
      throw new UnauthorizedException('Email não verificado. Verifique sua caixa de entrada.');
    }

    const token = this.generateToken(user);

    return {
      message: 'Login realizado com sucesso',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
    };
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const user = await this.authRepository.findByEmailAndValidVerificationCode(
      dto.email,
      dto.code,
    );

    if (!user) {
      throw new BadRequestException('Código inválido ou expirado');
    }

    await this.authRepository.updateVerification(user, {
      emailVerified: true,
      verificationCode: null,
      verificationCodeExpiresAt: null,
    });

    const token = this.generateToken(user);

    return {
      message: 'Email verificado com sucesso',
      token,
      user: {
        id: user.id,
        email: user.email,
      },
    };
  }

  async resendCode(dto: ResendCodeDto) {
    const user = await this.authRepository.findByEmail(dto.email);

    if (!user) {
      return { message: 'Se o email existir, um novo código será enviado.' };
    }

    if (user.emailVerified) {
      return { message: 'Email já verificado.' };
    }

    const verificationCode = this.generateCode();
    const verificationCodeExpiresAt = new Date(
      Date.now() + this.CODE_EXPIRATION_MINUTES * 60 * 1000,
    );

    await this.authRepository.updateVerification(user, {
      verificationCode,
      verificationCodeExpiresAt,
    });

    const emailSent = await this.mailService.sendVerificationCode(
      user.email,
      verificationCode,
    );

    if (!emailSent) {
      console.log(`[DEV] Novo código para ${user.email}: ${verificationCode}`);
    }

    return {
      message: 'Se o email existir, um novo código será enviado.',
    };
  }

  async getProfile(userId: string) {
    const user = await this.authRepository.findProfileById(userId);

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    return { user };
  }

  private generateToken(user: User): string {
    return this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });
  }

  private generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}
