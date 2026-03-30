import 'package:flutter/material.dart';

import 'personal_data_page.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _animateIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _animateIn = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 226.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;
            final mascotBubbleWidth = contentWidth;
            final mascotWidth = mascotBubbleWidth * 0.69;
            final bubbleWidth = mascotBubbleWidth * 0.46;
            final mascotHeight = mascotWidth * 1.08;
            final bubbleHeight = (mascotBubbleWidth * 0.11).clamp(44.0, 52.0);
            final bubbleTop = AppSpacing.lg;
            final bubbleLeft = mascotBubbleWidth - bubbleWidth - AppSpacing.xs;
            final mascotBubbleHeight =
                (bubbleTop + bubbleHeight) > mascotHeight
                    ? (bubbleTop + bubbleHeight)
                    : mascotHeight;
            final mascotBlockLeftShift = (contentWidth * 0.09).clamp(28.0, 48.0);

            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: (AppSpacing.huge * 2) + AppSpacing.sm + AppSpacing.lg - 2,
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
                    child: Text(
                      'Seja bem vindo(a) ao',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge.copyWith(
                        height: 36.8 / 36,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeOutCubic,
                    offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
                    child: SizedBox(
                      key: const ValueKey('welcome-logo-image'),
                      width: buttonWidth,
                      height: AppSpacing.huge + AppSpacing.xs - 2,
                      child: const Image(
                        key: ValueKey('welcome-logo-asset'),
                        image: AssetImage('assets/images/nome.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: (AppSpacing.huge * 2) + AppSpacing.sm + AppSpacing.xs),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    opacity: _animateIn ? 1 : 0,
                    child: Transform.translate(
                      offset: Offset(-mascotBlockLeftShift, 0),
                      child: SizedBox(
                        width: mascotBubbleWidth,
                        height: mascotBubbleHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              key: const ValueKey('welcome-mascot-box'),
                              width: mascotWidth,
                              height: mascotHeight,
                              child: const KeyedSubtree(
                                key: ValueKey('welcome-jaca-image'),
                                child: Image(
                                  key: ValueKey('welcome-jaca-asset'),
                                  image: AssetImage('assets/images/Jaca_acenando_v2.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: bubbleTop,
                              left: bubbleLeft,
                              child: Container(
                                key: const ValueKey('welcome-bubble-container'),
                                constraints: BoxConstraints.tightFor(
                                  width: bubbleWidth,
                                  height: bubbleHeight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs / 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputSurface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    key: const ValueKey('welcome-bubble-text'),
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 19.952 / 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Olá, meu nome é '),
                                        TextSpan(
                                          text: 'Jaca',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.brand900Variant,
                                            height: 19.952 / 14,
                                          ),
                                        ),
                                        const TextSpan(text: '\nQuero te conhecer melhor!'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge + AppSpacing.xxl),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    opacity: _animateIn ? 1 : 0,
                    child: SizedBox(
                      width: buttonWidth,
                      height: AppSpacing.huge + AppSpacing.xs,
                      child: AppButton(
                        label: 'Começar',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PersonalDataPage(),
                            ),
                          );
                        },
                        variant: AppButtonVariant.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
