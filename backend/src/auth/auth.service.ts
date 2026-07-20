import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { UniqueConstraintError } from 'sequelize';
import { Op } from 'sequelize';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import { User } from './models/user.model';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendCodeDto } from './dto/resend-code.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ValidateResetCodeDto } from './dto/validate-reset-code.dto';
import { MailService } from '../mail/mail.service';
import { AuthRepository } from './auth.repository';
import { calculateNutritionGoalsFromProfile } from './utils/nutrition-goal-calculator';
import { SocialFriendship } from '../social/models/social-friendship.model';
import { UserCurrencyTransaction } from '../missions/models/user-currency-transaction.model';
import {
  AVATAR_BACKGROUND_NONE_ID,
  AVATAR_FRAME_NONE_ID,
  OFFENSIVE_BLOCKER_DEFAULT_ID,
} from '../missions/constants/avatar-frame-store';
import { parseNumber } from '../shared/utils/number-parser.util';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { StreakService } from '../streak/streak.service';

@Injectable()
export class AuthService {
  private readonly SALT_ROUNDS = 12;
  private readonly CODE_EXPIRATION_MINUTES = 15;

  constructor(
    private readonly authRepository: AuthRepository,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
    @InjectModel(SocialFriendship)
    private readonly socialFriendshipModel: typeof SocialFriendship,
    @InjectModel(UserCurrencyTransaction)
    private readonly userCurrencyTransactionModel: typeof UserCurrencyTransaction,
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    private readonly streakService: StreakService,
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
      message:
        'Conta criada com sucesso. Verifique seu email. Verificar na caixa de spam.',
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

  async signInWithGoogle(dto: GoogleAuthDto) {
    const hasIdToken = Boolean(dto.idToken && dto.idToken.trim().length > 0);
    const hasAccessToken = Boolean(
      dto.accessToken && dto.accessToken.trim().length > 0,
    );
    console.log(
      `[AUTH][GOOGLE] start hasIdToken=${hasIdToken} hasAccessToken=${hasAccessToken}`,
    );

    const idToken = dto.idToken?.trim() ?? '';
    const accessToken = dto.accessToken?.trim() ?? '';

    let googleUser: {
      email?: string;
      name?: string;
      email_verified?: string | boolean;
      aud?: string;
    };

    if (idToken) {
      try {
        googleUser = await this.validateGoogleIdToken(idToken);
      } catch (error) {
        // Fallback para accessToken quando o idToken existir, mas falhar por
        // incompatibilidade de audience/clientId entre plataformas.
        if (accessToken) {
          console.warn(
            '[AUTH][GOOGLE] idToken validation failed, trying accessToken fallback',
            error,
          );
          googleUser = await this.validateGoogleAccessToken(accessToken);
        } else {
          throw error;
        }
      }
    } else {
      googleUser = await this.validateGoogleAccessToken(accessToken);
    }
    console.log(
      `[AUTH][GOOGLE] token validated email=${googleUser.email ?? 'null'} name=${googleUser.name ?? 'null'}`,
    );
    if (!googleUser.email) {
      console.log('[AUTH][GOOGLE] abort reason=no-email');
      throw new UnauthorizedException('Conta Google sem email valido');
    }

    const email = googleUser.email.toLowerCase();
    let user = await this.authRepository.findByEmailFull(email);
    console.log(
      `[AUTH][GOOGLE] user lookup email=${email} found=${Boolean(user)}`,
    );
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      const fallbackPasswordHash = await bcrypt.hash(
        this.generateGoogleFallbackPassword(dto.idToken ?? dto.accessToken ?? ''),
        this.SALT_ROUNDS,
      );
      try {
        user = await this.authRepository.createGoogleUser({
          name: googleUser.name?.trim() || null,
          email,
          passwordHash: fallbackPasswordHash,
        });
        console.log(
          `[AUTH][GOOGLE] user created id=${user.id} email=${user.email}`,
        );
      } catch (error) {
        if (error instanceof UniqueConstraintError) {
          console.log(
            `[AUTH][GOOGLE] unique constraint on create, reloading user email=${email}`,
          );
          user = await this.authRepository.findByEmailFull(email);
        } else {
          console.error('[AUTH][GOOGLE] create user failed', error);
          throw error;
        }
      }
    } else if (!user.emailVerified) {
      await this.authRepository.updateVerification(user, {
        emailVerified: true,
        verificationCode: null,
        verificationCodeExpiresAt: null,
      });
      user = await this.authRepository.findByEmailFull(email);
      console.log(
        `[AUTH][GOOGLE] existing user email marked verified email=${email}`,
      );
    }

    if (!user) {
      console.log('[AUTH][GOOGLE] abort reason=user-null-after-flow');
      throw new UnauthorizedException('Nao foi possivel autenticar com Google');
    }

    const profile = await this.authRepository.findProfileById(user.id);
    const needsOnboarding = this.userNeedsOnboarding(profile);
    console.log(
      `[AUTH][GOOGLE] success id=${user.id} isNewUser=${isNewUser} needsOnboarding=${needsOnboarding}`,
    );

    const token = this.generateToken(user);
    return {
      message: 'Login com Google realizado com sucesso',
      isNewUser,
      needsOnboarding,
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
      return {
        message:
          'Se o email existir, um novo código será enviado. Verificar na caixa de spam.',
      };
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
      message:
        'Se o email existir, um novo código será enviado. Verificar na caixa de spam.',
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.authRepository.findByEmailWithPassword(dto.email);

    if (!user) {
      throw new BadRequestException('E-mail nao cadastrado.');
    }

    if (!user.emailVerified) {
      throw new BadRequestException(
        'Confirme seu e-mail antes de redefinir a senha.',
      );
    }

    const resetCode = this.generateCodeDifferentFrom(user.verificationCode);
    const verificationCodeExpiresAt = new Date(
      Date.now() + this.CODE_EXPIRATION_MINUTES * 60 * 1000,
    );

    await this.authRepository.updateVerification(user, {
      verificationCode: resetCode,
      verificationCodeExpiresAt,
    });

    const emailSent = await this.mailService.sendPasswordResetCode(
      user.email,
      resetCode,
    );

    if (!emailSent) {
      console.log(`[DEV] Codigo de reset para ${user.email}: ${resetCode}`);
    }

    return {
      message:
        'Codigo de redefinicao enviado. Verificar na caixa de spam.',
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.authRepository.findByEmailAndValidPasswordResetCode(
      dto.email,
      dto.code,
    );

    if (!user) {
      throw new BadRequestException('Codigo invalido ou expirado');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, this.SALT_ROUNDS);
    await this.authRepository.updatePasswordAndClearResetCode(user, passwordHash);

    return {
      message: 'Senha redefinida com sucesso',
    };
  }

  async validateResetCode(dto: ValidateResetCodeDto) {
    const user = await this.authRepository.findByEmailAndValidPasswordResetCode(
      dto.email,
      dto.code,
    );

    if (!user) {
      throw new BadRequestException('Codigo invalido ou expirado');
    }

    return { message: 'Codigo valido' };
  }

  async getProfile(userId: string) {
    const user = await this.authRepository.findProfileById(userId);
    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    const totalXp = await this.getTotalXp(userId);
    const streakDays = await this.streakService.getUserStreak(userId);
    const meals = await this.mealModel.findAll({
      where: { userId, status: MealStatus.Active },
      attributes: ['title', 'description', 'createdAt'],
      order: [['createdAt', 'DESC']],
    });
    const favoriteDish = this.getFavoriteDish(meals);
    const preferredPeriod = this.getPreferredPeriod(meals);

    return {
      ...user.toJSON(),
      streakDays,
      friendCount: await this.countFriends(userId),
      totalXp,
      xp: totalXp,
      favoriteDish,
      preferredPeriod,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const currentProfile = await this.authRepository.findProfileById(userId);
    if (!currentProfile) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    const mergedProfileInput = {
      birthDate: dto.birthDate ?? currentProfile.birthDate,
      weight: dto.weight ?? currentProfile.weight,
      height: dto.height ?? currentProfile.height,
      weightUnit: dto.weightUnit ?? currentProfile.weightUnit,
      heightUnit: dto.heightUnit ?? currentProfile.heightUnit,
      sex: dto.sex ?? currentProfile.sex,
      objective: dto.objective ?? currentProfile.objective,
      activityLevel: dto.activityLevel ?? currentProfile.activityLevel,
    };

    const calculatedGoals = calculateNutritionGoalsFromProfile(mergedProfileInput);
    const hideAnyGuide =
      dto.hideGuideMe === true ||
      dto.hideSocialGuideMe === true ||
      dto.hideMissionsGuideMe === true;

    const payload: UpdateProfileDto = {
      ...dto,
      ...(calculatedGoals ?? {}),
      ...(hideAnyGuide
        ? {
            hideGuideMe: true,
            hideSocialGuideMe: true,
            hideMissionsGuideMe: true,
          }
        : {}),
    };

    // Compras passam pelo fluxo transacional da loja.
    // Ignoramos alterações diretas de inventário vindas do patch de perfil.
    if (payload.purchasedAvatarFrameIds != null) {
      delete payload.purchasedAvatarFrameIds;
    }
    if (payload.purchasedAvatarBackgroundIds != null) {
      delete payload.purchasedAvatarBackgroundIds;
    }
    if (payload.offensiveBlockerInventoryCount != null) {
      delete payload.offensiveBlockerInventoryCount;
    }
    if (payload.equippedOffensiveBlockerId != null) {
      const normalizedBlockerId = payload.equippedOffensiveBlockerId.trim();
      if (normalizedBlockerId.length === 0) {
        payload.equippedOffensiveBlockerId = OFFENSIVE_BLOCKER_DEFAULT_ID;
      } else if (normalizedBlockerId !== OFFENSIVE_BLOCKER_DEFAULT_ID) {
        throw new BadRequestException('Bloqueador de ofensiva inválido.');
      } else {
        payload.equippedOffensiveBlockerId = normalizedBlockerId;
      }
    }

    if (payload.equippedAvatarFrameId != null) {
      const equippedId = payload.equippedAvatarFrameId.trim();
      const normalizedEquippedId = equippedId.length > 0 ? equippedId : AVATAR_FRAME_NONE_ID;
      const purchasedIds = new Set(
        (Array.isArray(currentProfile.purchasedAvatarFrameIds)
          ? currentProfile.purchasedAvatarFrameIds
          : []
        )
          .map((value) => value.toString().trim())
          .filter((value) => value.length > 0),
      );

      if (
        normalizedEquippedId != AVATAR_FRAME_NONE_ID &&
        !purchasedIds.has(normalizedEquippedId)
      ) {
        throw new BadRequestException('A moldura escolhida ainda não foi comprada.');
      }

      payload.equippedAvatarFrameId = normalizedEquippedId;
    }

    if (payload.equippedAvatarBackgroundId != null) {
      const equippedId = payload.equippedAvatarBackgroundId.trim();
      const normalizedEquippedId =
        equippedId.length > 0 ? equippedId : AVATAR_BACKGROUND_NONE_ID;
      const purchasedIds = new Set(
        (Array.isArray(currentProfile.purchasedAvatarBackgroundIds)
          ? currentProfile.purchasedAvatarBackgroundIds
          : []
        )
          .map((value) => value.toString().trim())
          .filter((value) => value.length > 0),
      );

      if (
        normalizedEquippedId != AVATAR_BACKGROUND_NONE_ID &&
        !purchasedIds.has(normalizedEquippedId)
      ) {
        throw new BadRequestException('O fundo escolhido ainda não foi comprado.');
      }

      payload.equippedAvatarBackgroundId = normalizedEquippedId;
    }

    const user = await this.authRepository.updateProfile(userId, payload);
    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    return user;
  }

  async getFallbackProfile() {
    let devUser = await this.authRepository.findByEmail('dev@jacaloria.com');
    
    if (!devUser) {
      devUser = await this.authRepository.createUser({
        name: 'Desenvolvedor',
        email: 'dev@jacaloria.com',
        passwordHash: 'dummy-hash',
        verificationCode: '000000',
        verificationCodeExpiresAt: new Date(),
      });
      await this.authRepository.updateVerification(devUser, {
        emailVerified: true,
        verificationCode: null,
        verificationCodeExpiresAt: null,
      });
      await this.authRepository.updateProfile(devUser.id, {
        dailyCalorieGoal: 2000,
        dailyProteinGoal: 120,
        dailyCarbsGoal: 200,
        dailyFatGoal: 60,
      });
    }

    const profile = await this.authRepository.findProfileById(devUser.id);
    if (!profile) {
      throw new UnauthorizedException('Usuário de desenvolvimento não encontrado');
    }

    return {
      ...profile.toJSON(),
      friendCount: await this.countFriends(devUser.id),
    };
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

  private generateCodeDifferentFrom(previousCode: string | null): string {
    let nextCode = this.generateCode();
    while (previousCode != null && nextCode == previousCode) {
      nextCode = this.generateCode();
    }
    return nextCode;
  }

  private async countFriends(userId: string) {
    return this.socialFriendshipModel.count({
      where: { [Op.or]: [{ userLowId: userId }, { userHighId: userId }] },
    });
  }

  private async getTotalXp(userId: string) {
    const rows = await this.userCurrencyTransactionModel.findAll({
      where: { userId, currency: 'xp' },
      attributes: ['amountSigned'],
    });

    return rows.reduce((sum, row) => sum + parseNumber(row.amountSigned), 0);
  }

  private getFavoriteDish(meals: Array<Pick<Meal, 'title' | 'description'>>) {
    if (!meals.length) return null;

    const titleCounts = new Map<string, number>();
    for (const meal of meals) {
      const rawLabel = (meal.description ?? meal.title ?? '').trim();
      const normalized = rawLabel.toLowerCase();
      if (!normalized) continue;
      titleCounts.set(normalized, (titleCounts.get(normalized) ?? 0) + 1);
    }

    if (!titleCounts.size) return null;

    let bestTitle = '';
    let bestCount = 0;
    for (const [title, count] of titleCounts.entries()) {
      if (count > bestCount) {
        bestTitle = title;
        bestCount = count;
      }
    }

    return bestTitle
      .split(' ')
      .filter((part) => part.length > 0)
      .map((part) => part[0].toUpperCase() + part.slice(1))
      .join(' ');
  }

  private getPreferredPeriod(meals: Array<Pick<Meal, 'createdAt'>>) {
    if (!meals.length) return null;

    const periodCounts = { morning: 0, afternoon: 0, night: 0 };

    for (const meal of meals) {
      const hour = new Date(meal.createdAt).getHours();
      if (hour < 12) {
        periodCounts.morning += 1;
      } else if (hour < 18) {
        periodCounts.afternoon += 1;
      } else {
        periodCounts.night += 1;
      }
    }

    if (
      periodCounts.morning >= periodCounts.afternoon &&
      periodCounts.morning >= periodCounts.night
    ) {
      return 'morning';
    }
    if (periodCounts.afternoon >= periodCounts.night) {
      return 'afternoon';
    }
    return 'night';
  }

  private async validateGoogleIdToken(idToken: string): Promise<{
    email?: string;
    name?: string;
    email_verified?: string | boolean;
    aud?: string;
  }> {
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`,
    );
    if (!response.ok) {
      throw new UnauthorizedException('Token Google invalido');
    }

    const payload = (await response.json()) as {
      email?: string;
      name?: string;
      email_verified?: string | boolean;
      aud?: string;
    };

    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (clientId && payload.aud && payload.aud !== clientId) {
      throw new UnauthorizedException('Token Google com audience invalida');
    }

    if (
      payload.email_verified !== true &&
      payload.email_verified !== 'true'
    ) {
      throw new UnauthorizedException('Email do Google nao verificado');
    }

    return payload;
  }

  private generateGoogleFallbackPassword(idToken: string): string {
    const hash = createHash('sha256').update(idToken).digest('hex');
    return `google_${hash.substring(0, 16)}9`;
  }

  private async validateGoogleAccessToken(accessToken: string): Promise<{
    email?: string;
    name?: string;
    email_verified?: string | boolean;
  }> {
    if (!accessToken) {
      throw new UnauthorizedException('Access token Google ausente');
    }

    const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) {
      throw new UnauthorizedException('Access token Google invalido');
    }

    const payload = (await response.json()) as {
      email?: string;
      name?: string;
      email_verified?: string | boolean;
    };

    if (
      payload.email_verified !== true &&
      payload.email_verified !== 'true'
    ) {
      throw new UnauthorizedException('Email do Google nao verificado');
    }

    return payload;
  }

  private userNeedsOnboarding(profile: any): boolean {
    if (!profile) {
      return true;
    }

    const hasBirthDate = Boolean(profile.birthDate);
    const hasWeight = Number(profile.weight) > 0;
    const hasHeight = Number(profile.height) > 0;
    const hasSex = typeof profile.sex === 'string' && profile.sex.trim().length > 0;
    const hasObjective =
      typeof profile.objective === 'string' && profile.objective.trim().length > 0;
    const hasActivityLevel =
      typeof profile.activityLevel === 'string' &&
      profile.activityLevel.trim().length > 0;

    return !(
      hasBirthDate &&
      hasWeight &&
      hasHeight &&
      hasSex &&
      hasObjective &&
      hasActivityLevel
    );
  }
}
