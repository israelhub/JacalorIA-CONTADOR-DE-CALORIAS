import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/food_analysis_result.dart';
import '../services/food_analysis_service.dart';
import '../widgets/food_analysis_page_header.dart';

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
  bool _isHighDemandError = false;
  bool _started = false;

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
      unawaited(_runOperation());
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _runOperation() async {
    try {
      final result = await widget.operation();

      if (!mounted || _didResolve) {
        return;
      }

      _didResolve = true;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted || _didResolve) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');
      final isHighDemandError =
          error is FoodAnalysisHighDemandException ||
          _looksLikeHighDemandError(message);

      setState(() {
        _errorMessage = isHighDemandError
            ? FoodAnalysisService.highDemandMessage
            : message;
        _isHighDemandError = isHighDemandError;
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
                          if (widget.showScanner && hasPreviewImage)
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
                          if (hasPreviewImage)
                            Positioned.fill(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                        widget.statusIcon,
                                        color: AppColors.action500,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      widget.title,
                                      style: AppTextStyles.homeSectionTitle
                                          .copyWith(color: AppColors.surface),
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
                _errorMessage ?? widget.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _errorMessage == null
                      ? AppColors.textPrimary
                      : AppColors.textError,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_errorMessage == null)
                const CircularProgressIndicator(color: AppColors.action500)
              else if (_isHighDemandError)
                _HighDemandActions(
                  onRetry: _retry,
                  onGoHome: _goHome,
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

  Widget _buildPreviewImage() {
    final bytes = widget.imageBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    }

    final imageUrl = (widget.imageUrl ?? '').trim();
    if (imageUrl.toLowerCase().startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
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

  bool _looksLikeHighDemandError(String message) {
    final normalizedMessage = message.toLowerCase();
    return normalizedMessage.contains('high demand') ||
        normalizedMessage.contains('alta demanda') ||
        normalizedMessage.contains('too many requests') ||
        normalizedMessage.contains('rate limit');
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isHighDemandError = false;
    });
    unawaited(_runOperation());
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _HighDemandActions extends StatelessWidget {
  const _HighDemandActions({required this.onRetry, required this.onGoHome});

  final VoidCallback onRetry;
  final VoidCallback onGoHome;

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
          label: 'Voltar para home',
          variant: AppButtonVariant.outline,
          onPressed: onGoHome,
        ),
      ],
    );
  }
}
