import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/food_analysis_result.dart';
import '../widgets/food_analysis_page_header.dart';

class FoodAnalysisProcessingPage extends StatefulWidget {
  const FoodAnalysisProcessingPage({
    super.key,
    required this.imageBytes,
    required this.title,
    required this.message,
    required this.operation,
    this.appBarTitle = 'Nova refeição',
    this.statusIcon = Icons.auto_awesome,
    this.showScanner = true,
  });

  final Uint8List? imageBytes;
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

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          if (widget.showScanner)
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

    return Image.asset(
      'assets/images/smiling green cartoon crocodile@2x.webp',
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}
