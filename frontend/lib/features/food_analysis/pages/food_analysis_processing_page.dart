import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../models/food_analysis_result.dart';
import '../services/food_analysis_service.dart';
import '../widgets/food_analysis_page_header.dart';

class _StatusStage {
  const _StatusStage({
    required this.after,
    required this.title,
    required this.message,
  });

  final Duration after;
  final String title;
  final String message;
}

/// Mensagens progressivas enquanto a análise roda (budget ~55s).
/// Só UX de espera — sem jargão de fallback/modelo.
const List<_StatusStage> _analysisStatusStages = [
  _StatusStage(
    after: Duration.zero,
    title: 'Analisando...',
    message: 'A inteligência artificial está analisando sua refeição...',
  ),
  _StatusStage(
    after: Duration(seconds: 12),
    title: 'Ainda analisando...',
    message: 'Isso pode levar alguns segundos. Estamos olhando bem o prato.',
  ),
  _StatusStage(
    after: Duration(seconds: 28),
    title: 'Quase pronto...',
        message: 'Demorando um pouco mais; refinando a estimativa das calorias.',
  ),
  _StatusStage(
    after: Duration(seconds: 42),
    title: 'Só mais um instante...',
    message: 'Obrigado pela paciência. Se não concluir, você pode tentar de novo.',
  ),
];

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _scannerController;
  bool _didResolve = false;
  String? _errorMessage;
  bool _canRetry = false;
  bool _started = false;
  int _statusStageIndex = 0;
  Timer? _statusTimer;
  int _elapsedSeconds = 0;

  bool get _hasError => _errorMessage != null;

  String get _displayTitle {
    if (_hasError) {
      return 'Não foi possível';
    }
    // Save/recalc sem título no overlay: não sobe os stages de "Analisando...".
    if (widget.title.trim().isEmpty) {
      return '';
    }
    if (_statusStageIndex == 0) {
      return widget.title;
    }
    return _analysisStatusStages[_statusStageIndex].title;
  }

  String get _displayMessage {
    if (_hasError) {
      return _errorMessage!;
    }
    if (widget.title.trim().isEmpty || _statusStageIndex == 0) {
      return widget.message;
    }
    return _analysisStatusStages[_statusStageIndex].message;
  }

  IconData get _displayIcon {
    if (_hasError) {
      return Icons.error_outline;
    }
    return widget.statusIcon;
  }

  Color get _displayIconColor {
    if (_hasError) {
      return AppColors.textError;
    }
    return AppColors.action500;
  }

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

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
    _scannerController.dispose();
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

  void _stopStatusProgression({required bool stopScanner}) {
    _statusTimer?.cancel();
    _statusTimer = null;
    if (stopScanner && _scannerController.isAnimating) {
      _scannerController.stop();
    }
  }

  Future<void> _runOperation() async {
    try {
      final result = await widget.operation();

      if (!mounted || _didResolve) {
        return;
      }

      _didResolve = true;
      _stopStatusProgression(stopScanner: true);
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _didResolve) {
        return;
      }

      final mapped = FoodAnalysisService.toUserFacingError(error);
      _stopStatusProgression(stopScanner: true);

      setState(() {
        _errorMessage = mapped.message;
        _canRetry = mapped.canRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPreviewImage =
        (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) ||
        (widget.imageUrl ?? '').trim().toLowerCase().startsWith('http') ||
        (widget.imageAsset ?? '').trim().startsWith('assets/');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: FoodAnalysisPageHeader(title: widget.appBarTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.foodReviewFieldBorder,
                      ),
                      boxShadow: AppShadows.foodReviewField,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 0.88,
                            child: _buildPreviewImage(),
                          ),
                          if (hasPreviewImage)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.brand900Variant.withValues(
                                        alpha: 0.28,
                                      ),
                                      AppColors.brand900Variant.withValues(
                                        alpha: 0.08,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (widget.showScanner &&
                              hasPreviewImage &&
                              !_hasError)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _scannerController,
                                builder: (context, child) {
                                  return Align(
                                    alignment: Alignment(
                                      0,
                                      (_scannerController.value * 2) - 1,
                                    ),
                                    child: Container(
                                      height: 42,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppColors.action500.withValues(
                                              alpha: 0.2,
                                            ),
                                            AppColors.action500.withValues(
                                              alpha: 0.42,
                                            ),
                                            AppColors.action500.withValues(
                                              alpha: 0.2,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0, 0.2, 0.5, 0.8, 1],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Sem imagem: sem ícone no meio (só a mensagem embaixo).
                                  if (hasPreviewImage || _hasError) ...[
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withValues(
                                          alpha: 0.9,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.sm,
                                      ),
                                      child: Icon(
                                        _displayIcon,
                                        color: _displayIconColor,
                                        size: 32,
                                      ),
                                    ),
                                    if (_displayTitle.isNotEmpty)
                                      const SizedBox(height: AppSpacing.md),
                                  ],
                                  if (_displayTitle.isNotEmpty)
                                    Text(
                                      _displayTitle,
                                      style: AppTextStyles.homeSectionTitle
                                          .copyWith(
                                        color: hasPreviewImage
                                            ? AppColors.surface
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _displayMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _hasError
                      ? AppColors.textError
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!_hasError &&
                  widget.title.trim().isNotEmpty &&
                  _statusStageIndex >= 1) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _elapsedHint(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (!_hasError)
                const CircularProgressIndicator(color: AppColors.action500)
              else if (_canRetry)
                _RetryActions(
                  onRetry: _retry,
                  onGoBack: () => Navigator.of(context).pop(null),
                )
              else
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Voltar'),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
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
      return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    }

    final imageUrl = (widget.imageUrl ?? '').trim();
    if (imageUrl.toLowerCase().startsWith('http')) {
      return Image(
        image: CachedNetworkImageProvider(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, wasSyncLoaded) {
          if (wasSyncLoaded || frame != null) {
            return child;
          }
          return const AppSkeletonBox(
            height: double.infinity,
            borderRadius: 0,
          );
        },
        errorBuilder: (_, __, ___) => _buildMissingImage(),
      );
    }

    final imageAsset = (widget.imageAsset ?? '').trim();
    if (imageAsset.startsWith('assets/')) {
      return Image.asset(imageAsset, fit: BoxFit.cover, width: double.infinity);
    }

    return _buildMissingImage();
  }

  Widget _buildMissingImage() {
    return Container(
      color: AppColors.surfaceAlt,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Imagem não cadastrada',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _canRetry = false;
      _statusStageIndex = 0;
    });
    if (!_scannerController.isAnimating) {
      _scannerController.repeat();
    }
    _startStatusProgression();
    unawaited(_runOperation());
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
        AppButton(
          label: 'Tentar novamente',
          onPressed: onRetry,
        ),
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
