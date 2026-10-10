import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_card.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../models/food_analysis_result.dart';
import '../services/food_analysis_service.dart';
import '../widgets/food_analysis_page_header.dart';

class _StatusStage {
  const _StatusStage({required this.after, required this.message});

  final Duration after;
  final String message;
}

const List<_StatusStage> _analysisStatusStages = [
  _StatusStage(
    after: Duration.zero,
    message: 'Estamos analisando os alimentos da sua refeição...',
  ),
  _StatusStage(
    after: Duration(seconds: 12),
    message: 'Isso pode levar alguns segundos. Estamos olhando bem o prato.',
  ),
  _StatusStage(
    after: Duration(seconds: 28),
    message: 'Demorando um pouco mais; refinando a estimativa das calorias.',
  ),
  _StatusStage(
    after: Duration(seconds: 42),
    message:
        'Obrigado pela paciência. Se não concluir, você pode tentar de novo.',
  ),
];

const String _jacaAnalyzingAsset = 'assets/images/jaca_analisando.jpg';

class FoodAnalysisProcessingPage extends StatefulWidget {
  const FoodAnalysisProcessingPage({
    super.key,
    required this.imageBytes,
    this.imageUrl,
    this.imageAsset,
    required this.title,
    required this.message,
    required this.operation,
    this.appBarTitle = 'Nova refeição',
    this.statusIcon = Icons.auto_awesome,
    this.showScanner = true,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? imageAsset;
  final String title;
  final String message;
  final Future<FoodAnalysisResult> Function() operation;
  final String appBarTitle;
  final IconData statusIcon;
  final bool showScanner;

  @override
  State<FoodAnalysisProcessingPage> createState() =>
      _FoodAnalysisProcessingPageState();
}

class _FoodAnalysisProcessingPageState extends State<FoodAnalysisProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _shineController;
  late final AnimationController _pulseController;
  bool _didResolve = false;
  String? _errorMessage;
  bool _canRetry = false;
  bool _started = false;
  int _statusStageIndex = 0;
  Timer? _statusTimer;
  int _elapsedSeconds = 0;

  bool get _hasError => _errorMessage != null;

  String get _displayMessage {
    if (_hasError) {
      return _errorMessage!;
    }
    if (widget.message.trim().isNotEmpty && _statusStageIndex == 0) {
      return widget.message;
    }
    return _analysisStatusStages[_statusStageIndex].message;
  }

  double get _progressValue {
    if (_hasError || _didResolve) {
      return 0;
    }
    final t = (_elapsedSeconds / 55).clamp(0.0, 1.0);
    return (1 - math.exp(-2.2 * t)).clamp(0.08, 0.94);
  }

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) {
        return;
      }
      _started = true;
      _startStatusProgression();
      unawaited(_runOperation());
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startStatusProgression() {
    _statusTimer?.cancel();
    _elapsedSeconds = 0;
    _statusStageIndex = 0;

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _hasError || _didResolve) {
        return;
      }

      _elapsedSeconds += 1;
      final elapsed = Duration(seconds: _elapsedSeconds);
      var nextIndex = 0;
      for (var i = 0; i < _analysisStatusStages.length; i++) {
        if (elapsed >= _analysisStatusStages[i].after) {
          nextIndex = i;
        }
      }

      if (nextIndex != _statusStageIndex || _elapsedSeconds > 0) {
        setState(() {
          _statusStageIndex = nextIndex;
        });
      }
    });
  }

  void _stopStatusProgression({required bool stopShine}) {
    _statusTimer?.cancel();
    _statusTimer = null;
    if (stopShine) {
      if (_shineController.isAnimating) {
        _shineController.stop();
      }
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    }
  }

  Future<void> _runOperation() async {
    try {
      final result = await widget.operation();

      if (!mounted || _didResolve) {
        return;
      }

      _didResolve = true;
      _stopStatusProgression(stopShine: true);
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _didResolve) {
        return;
      }

      final mapped = FoodAnalysisService.toUserFacingError(error);
      _stopStatusProgression(stopShine: true);

      setState(() {
        _errorMessage = mapped.message;
        _canRetry = mapped.canRetry;
      });
    }
  }

  bool get _hasPreviewImage {
    return (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) ||
        (widget.imageUrl ?? '').trim().toLowerCase().startsWith('http') ||
        (widget.imageAsset ?? '').trim().startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: FoodAnalysisPageHeader(title: widget.appBarTitle),
      body: AppBackPageContent(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppBackPageHeader.contentTopInset(context),
            AppSpacing.pageHorizontal,
            0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              if (_hasPreviewImage) {
                return _buildWithImageLayout(
                  availableHeight: availableHeight,
                  screenHeight: screenHeight,
                );
              }
              return _buildWithoutImageLayout(availableHeight: availableHeight);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWithImageLayout({
    required double availableHeight,
    required double screenHeight,
  }) {
    final statusBlockHeight = _estimateStatusBlockHeight();
    final imageHeight = (screenHeight * 0.48)
        .clamp(220.0, availableHeight - statusBlockHeight)
        .toDouble();

    return Column(
      children: [
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _AnalysisPreviewCard(
                image: _buildPreviewImage(),
                showEffect: widget.showScanner && !_hasError,
                shineController: _shineController,
                pulseController: _pulseController,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusCard(
          hasError: _hasError,
          displayMessage: _displayMessage,
          showElapsedHint: !_hasError && _statusStageIndex >= 1,
          elapsedHint: _elapsedHint(),
          progressValue: _progressValue,
          canRetry: _canRetry,
          onRetry: _retry,
          onGoBack: () => Navigator.of(context).pop(null),
          mascotSize: _hasError
              ? null
              : (screenHeight * 0.12).clamp(72.0, 110.0).toDouble(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildWithoutImageLayout({required double availableHeight}) {
    final mascotSize = (availableHeight * 0.28).clamp(120.0, 180.0);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight * 0.85),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusCard(
                hasError: _hasError,
                displayMessage: _displayMessage,
                showElapsedHint: !_hasError && _statusStageIndex >= 1,
                elapsedHint: _elapsedHint(),
                progressValue: _progressValue,
                canRetry: _canRetry,
                onRetry: _retry,
                onGoBack: () => Navigator.of(context).pop(null),
                mascotSize: _hasError ? null : mascotSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _estimateStatusBlockHeight() {
    var height = 120.0;
    if (!_hasError) {
      height += 120;
    }
    if (!_hasError && _statusStageIndex >= 1) {
      height += 28;
    }
    if (_hasError && _canRetry) {
      height += 80;
    }
    return height + AppSpacing.md + AppSpacing.sm;
  }

  String _elapsedHint() {
    final seconds = _elapsedSeconds;
    if (seconds < 60) {
      return 'Há ${seconds}s nesta análise';
    }
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (rest == 0) {
      return 'Há ${minutes}min nesta análise';
    }
    return 'Há ${minutes}min ${rest}s nesta análise';
  }

  Widget _buildPreviewImage() {
    final bytes = widget.imageBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.expand(),
      );
    }

    final imageUrl = (widget.imageUrl ?? '').trim();
    if (imageUrl.toLowerCase().startsWith('http')) {
      return AppNetworkImage(
        url: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        error: const SizedBox.expand(),
      );
    }

    final imageAsset = (widget.imageAsset ?? '').trim();
    if (imageAsset.startsWith('assets/')) {
      return Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return const SizedBox.expand();
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _canRetry = false;
      _statusStageIndex = 0;
    });
    if (!_shineController.isAnimating) {
      _shineController.repeat();
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    _startStatusProgression();
    unawaited(_runOperation());
  }
}

class _AnalysisPreviewCard extends StatelessWidget {
  const _AnalysisPreviewCard({
    required this.image,
    required this.showEffect,
    required this.shineController,
    required this.pulseController,
  });

  final Widget image;
  final bool showEffect;
  final AnimationController shineController;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.foodReviewFieldBorder),
        boxShadow: AppShadows.foodReviewField,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (showEffect) ...[
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  final pulse = 0.12 + (0.1 * pulseController.value);
                  return IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 1.05,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: pulse * 0.35),
                            Colors.black.withValues(alpha: pulse),
                          ],
                          stops: const [0.45, 0.78, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: Listenable.merge([shineController, pulseController]),
                builder: (context, child) {
                  final t = shineController.value;
                  final soft = 0.55 + (0.25 * pulseController.value);
                  return IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.8 + 3.6 * t, -1.1),
                          end: Alignment(-0.9 + 3.6 * t, 1.1),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.06 * soft),
                            Colors.white.withValues(alpha: 0.22 * soft),
                            Colors.white.withValues(alpha: 0.42 * soft),
                            Colors.white.withValues(alpha: 0.16 * soft),
                            Colors.white.withValues(alpha: 0.04 * soft),
                            Colors.transparent,
                          ],
                          stops: const [
                            0.0,
                            0.34,
                            0.42,
                            0.48,
                            0.52,
                            0.58,
                            0.66,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.hasError,
    required this.displayMessage,
    required this.showElapsedHint,
    required this.elapsedHint,
    required this.progressValue,
    required this.canRetry,
    required this.onRetry,
    required this.onGoBack,
    this.mascotSize,
  });

  final bool hasError;
  final String displayMessage;
  final bool showElapsedHint;
  final String elapsedHint;
  final double progressValue;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;
  final double? mascotSize;

  @override
  Widget build(BuildContext context) {
    final showMascot = mascotSize != null && !hasError;

    return AppFormCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMascot) ...[
            Image.asset(
              _jacaAnalyzingAsset,
              width: mascotSize,
              height: mascotSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: hasError ? AppColors.textError : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showElapsedHint) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              elapsedHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!hasError) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 6,
                backgroundColor: AppColors.homeProgressTrack,
                color: AppColors.textPrimary.withValues(alpha: 0.72),
              ),
            ),
          ] else if (canRetry) ...[
            const SizedBox(height: AppSpacing.md),
            _RetryActions(onRetry: onRetry, onGoBack: onGoBack),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onGoBack, child: const Text('Voltar')),
          ],
        ],
      ),
    );
  }
}

class _RetryActions extends StatelessWidget {
  const _RetryActions({required this.onRetry, required this.onGoBack});

  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(label: 'Tentar novamente', onPressed: onRetry),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Voltar',
          variant: AppButtonVariant.outline,
          onPressed: onGoBack,
        ),
      ],
    );
  }
}
