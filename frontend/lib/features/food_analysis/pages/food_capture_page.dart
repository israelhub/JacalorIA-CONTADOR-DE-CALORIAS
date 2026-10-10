import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../helpers/food_capture_camera.dart';
import '../helpers/food_review_helpers.dart';
import '../helpers/image_optimizer.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
import 'food_analysis_processing_page.dart';
import 'food_review_page.dart';
import 'saved_meals_page.dart';
import '../widgets/food_analysis_page_header.dart';
import '../widgets/food_review_confirm_button.dart';

abstract class FoodImagePicker {
  Future<XFile?> pickImage(ImageSource source);
}

class ImagePickerAdapter implements FoodImagePicker {
  ImagePickerAdapter(this._picker);

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source);
  }
}

class FoodCapturePage extends StatefulWidget {
  const FoodCapturePage({
    super.key,
    this.recordedAt,
    FoodAnalysisService? analysisService,
    FoodImagePicker? imagePicker,
    Future<OptimizedImage> Function(Uint8List original)? optimizeImage,
  }) : _analysisService = analysisService ?? const FoodAnalysisService(),
       _imagePicker = imagePicker,
       _optimizeImage = optimizeImage ?? optimizeForAnalysis;

  final DateTime? recordedAt;
  final FoodAnalysisService _analysisService;
  final FoodImagePicker? _imagePicker;
  final Future<OptimizedImage> Function(Uint8List original) _optimizeImage;

  @override
  State<FoodCapturePage> createState() => _FoodCapturePageState();
}

class _FoodCapturePageState extends State<FoodCapturePage> {
  CameraController? _cameraController;
  bool _isBusy = false;
  String? _error;
  String? _cameraError;
  bool _isCameraInitializing = true;
  bool _isFlashOn = false;

  FoodImagePicker get _imagePicker =>
      widget._imagePicker ?? ImagePickerAdapter(ImagePicker());

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('food_capture');
    _initializeCamera();
  }

  @override
  void dispose() {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      unawaited(_releaseCamera(controller));
    }
    super.dispose();
  }

  Future<void> _releaseCamera(CameraController controller) async {
    try {
      if (controller.value.isInitialized) {
        await controller.setFlashMode(FlashMode.off);
      }
    } catch (_) {}
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: const FoodAnalysisPageHeader(title: 'Nova refeição'),
      body: AppBackPageContent(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _buildCameraArea(context)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.md,
                    AppSpacing.pageHorizontal,
                    AppSpacing.md,
                  ),
                  child: Column(
                    key: const Key('food-capture-actions'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null) ...[
                        _CaptureErrorBanner(message: _error!),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _CaptureActions(
                        onTextEntry: _openTextEntry,
                        onSavedMeals: _openSavedMeals,
                        onCapture: _takePhoto,
                        onGallery: () => _pickAndAnalyze(ImageSource.gallery),
                        isCameraReady:
                            _cameraController?.value.isInitialized ?? false,
                        isBusy: _isBusy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea(BuildContext context) {
    if (_isCameraInitializing) {
      return _CameraShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.action500),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Preparando a câmera...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraError != null || _cameraController == null) {
      return _CameraShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 64,
                color: AppColors.action500,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _cameraError ?? 'Não foi possível abrir a câmera.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _initializeCamera,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.action500,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController!;
    return _CameraShell(
      // No web, ClipRRect + HtmlElementView da camera fica preto.
      clipContent: !kIsWeb,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CameraLivePreview(controller: controller),
          Positioned(
            top: AppBackPageHeader.scrollTopInset(
              context,
              extra: AppSpacing.xs,
            ),
            right: AppSpacing.md,
            child: _FlashToggleButton(
              isOn: _isFlashOn,
              onTap: _isBusy ? null : _toggleFlash,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final next = !_isFlashOn;
    final applied = await _applyFlashMode(
      controller,
      next ? FlashMode.torch : FlashMode.off,
    );
    if (!mounted) {
      return;
    }
    if (applied) {
      setState(() {
        _isFlashOn = next;
      });
      return;
    }
    AppToast.error(context, message: 'Flash não disponível neste dispositivo.');
  }

  Future<bool> _applyFlashMode(
    CameraController controller,
    FlashMode mode, {
    int retries = 2,
  }) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        await controller.setFlashMode(mode);
        return true;
      } catch (_) {
        if (attempt == retries) {
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    return false;
  }

  Future<void> _turnFlashOff() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _isFlashOn = false;
      return;
    }

    await _applyFlashMode(controller, FlashMode.off, retries: 1);
    if (!mounted) {
      _isFlashOn = false;
      return;
    }
    if (_isFlashOn) {
      setState(() {
        _isFlashOn = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
        _isFlashOn = false;
      });

      final cameras = await availableCameras();
      final selectedCamera = selectFoodCaptureCamera(cameras);

      final controller = CameraController(
        selectedCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? ImageFormatGroup.unknown
            : ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (!mounted) {
        await _releaseCamera(controller);
        return;
      }

      final previous = _cameraController;
      _cameraController = controller;
      if (previous != null) {
        await _releaseCamera(previous);
      }
      setState(() {
        _isCameraInitializing = false;
        _isFlashOn = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final previous = _cameraController;
      _cameraController = null;
      if (previous != null) {
        await _releaseCamera(previous);
      }
      setState(() {
        _isCameraInitializing = false;
        _isFlashOn = false;
        _cameraError = _mapCameraError(error);
      });
    }
  }

  String _mapCameraError(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
        case 'CameraAccessDeniedWithoutPrompt':
        case 'AudioAccessDenied':
        case 'AudioAccessDeniedWithoutPrompt':
          return 'Permissão da câmera negada. Habilite o acesso no navegador '
              'e toque em "Tentar novamente".';
        case 'CameraAccessRestricted':
          return 'Acesso à câmera está restrito neste dispositivo.';
        default:
          return error.description?.isNotEmpty == true
              ? error.description!
              : 'Não foi possível abrir a câmera.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _openSavedMeals() async {
    if (_isBusy) {
      return;
    }

    final meal = await context.pushSlidePage<FoodMealRecord>(
      SavedMealsPage(recordedAt: widget.recordedAt),
    );

    if (!mounted || meal == null) {
      return;
    }

    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {'entry': 'saved_meal'},
    );

    Navigator.of(context).pop(meal);
  }

  Future<void> _openTextEntry() async {
    final typedText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _ManualFoodEntrySheet(),
    );

    if (!mounted || typedText == null || typedText.trim().isEmpty) {
      return;
    }

    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {'entry': 'text'},
    );
    unawaited(AnalyticsService.instance.flush());

    final aiManualAnalysis = await _pushAnalysisLoadingPage(
      imageBytes: null,
      title: '',
      message: 'Estamos analisando os alimentos da sua refeição...',
      operation: () => widget._analysisService.analyzeManualText(typedText),
    );

    if (!mounted || aiManualAnalysis == null) {
      return;
    }

    if (!_hasIdentifiedFood(aiManualAnalysis)) {
      final parsedFallback = parseManualFoodBlock(typedText);
      if (parsedFallback.isEmpty) {
        await _handleAnalysisResult(aiManualAnalysis);
        return;
      }

      final fallbackAnalysis = FoodAnalysisResult(
        items: parsedFallback
            .map(
              (item) => FoodAnalysisItem(
                name: item.name,
                grams: item.grams,
                unit: item.unit,
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
              ),
            )
            .toList(growable: false),
        totals: const FoodAnalysisTotals(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
        justification: '',
      );

      final updatedMeal = await _pushReviewPage(
        imageBytes: null,
        analysis: fallbackAnalysis,
      );

      if (updatedMeal != null && mounted) {
        Navigator.of(context).pop(updatedMeal);
      }
      return;
    }

    final updatedMeal = await _pushReviewPage(
      imageBytes: null,
      analysis: aiManualAnalysis,
    );

    if (updatedMeal != null && mounted) {
      Navigator.of(context).pop(updatedMeal);
    }
  }

  Future<void> _takePhoto() async {
    if (_isBusy ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {'entry': 'camera'},
    );

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final picture = await _cameraController!.takePicture();
      await _turnFlashOff();
      final rawBytes = await picture.readAsBytes();
      final optimized = await widget._optimizeImage(rawBytes);
      final bytes = optimized.bytes;

      final analysis = await _pushAnalysisLoadingPage(
        imageBytes: bytes,
        title: '',
        message: 'Estamos analisando os alimentos da sua refeição...',
        operation: () => widget._analysisService.analyzeImage(
          imageBytes: bytes,
          mimeType: optimized.mimeType,
        ),
      );

      if (!mounted || analysis == null) {
        return;
      }

      final canProceed = await _handleAnalysisResult(analysis);
      if (!canProceed || !mounted) {
        return;
      }

      final updatedMeal = await _pushReviewPage(
        imageBytes: bytes,
        analysis: analysis,
      );

      if (!mounted) {
        return;
      }

      if (updatedMeal != null) {
        Navigator.of(context).pop(updatedMeal);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = FoodAnalysisService.toUserFacingError(error).message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (_isBusy) {
      return;
    }

    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {
        'entry': source == ImageSource.camera ? 'camera' : 'gallery',
      },
    );

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final image = await _imagePicker.pickImage(source);
      if (image == null) {
        if (mounted) {
          setState(() {
            _isBusy = false;
          });
        }
        return;
      }

      final rawBytes = await image.readAsBytes();
      final optimized = await widget._optimizeImage(rawBytes);
      final bytes = optimized.bytes;

      final analysis = await _pushAnalysisLoadingPage(
        imageBytes: bytes,
        title: '',
        message: 'Estamos analisando os alimentos da sua refeição...',
        operation: () => widget._analysisService.analyzeImage(
          imageBytes: bytes,
          mimeType: optimized.mimeType,
        ),
      );

      if (!mounted || analysis == null) {
        return;
      }

      final canProceed = await _handleAnalysisResult(analysis);
      if (!canProceed || !mounted) {
        setState(() {
          _isBusy = false;
        });
        return;
      }

      final updatedMeal = await _pushReviewPage(
        imageBytes: bytes,
        analysis: analysis,
      );

      if (!mounted) {
        return;
      }

      if (updatedMeal != null) {
        Navigator.of(context).pop(updatedMeal);
      } else {
        setState(() {
          _isBusy = false;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _error = FoodAnalysisService.toUserFacingError(error).message;
      });
    }
  }

  Future<FoodAnalysisResult?> _pushAnalysisLoadingPage({
    required Uint8List? imageBytes,
    required String title,
    required String message,
    required Future<FoodAnalysisResult> Function() operation,
  }) {
    return context.pushSlidePage<FoodAnalysisResult>(
      FoodAnalysisProcessingPage(
        imageBytes: imageBytes,
        title: title,
        message: message,
        operation: operation,
      ),
    );
  }

  Future<FoodMealRecord?> _pushReviewPage({
    required Uint8List? imageBytes,
    required FoodAnalysisResult analysis,
  }) {
    return context.pushSlidePage<FoodMealRecord>(
      FoodReviewPage(
        imageBytes: imageBytes,
        analysis: analysis,
        analysisService: widget._analysisService,
        recordedAt: widget.recordedAt,
      ),
    );
  }

  bool _hasIdentifiedFood(FoodAnalysisResult analysis) {
    return analysis.items.any(
      (item) => item.name.trim().isNotEmpty && item.grams > 0,
    );
  }

  Future<bool> _handleAnalysisResult(FoodAnalysisResult analysis) async {
    if (_hasIdentifiedFood(analysis)) {
      return true;
    }

    final action = await showModalBottomSheet<_NoFoodAction>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => const _NoFoodIdentifiedSheet(),
    );

    if (!mounted) {
      return false;
    }

    if (action == _NoFoodAction.goHome) {
      Navigator.of(context).pop();
    }

    return false;
  }
}

enum _NoFoodAction { goHome, retry }

class _CaptureActions extends StatelessWidget {
  const _CaptureActions({
    required this.onTextEntry,
    required this.onSavedMeals,
    required this.onCapture,
    required this.onGallery,
    required this.isCameraReady,
    required this.isBusy,
  });

  final VoidCallback onTextEntry;
  final VoidCallback onSavedMeals;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final bool isCameraReady;
  final bool isBusy;

  static const double _sideButtonSize = 64;
  static const double _shutterSize = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            color: AppColors.surface,
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: isBusy ? null : onSavedMeals,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 15,
                      color: isBusy
                          ? AppColors.textTertiary
                          : const Color(0xFF4B5563),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Usar refeição salva',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isBusy
                              ? AppColors.textTertiary
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CaptureActionButton(
                icon: Icons.edit_outlined,
                label: 'Digitar',
                size: _sideButtonSize,
                onTap: isBusy ? null : onTextEntry,
              ),
              SizedBox(
                width: _shutterSize,
                height: _shutterSize,
                child: _CameraShutterButton(
                  onTap: isCameraReady && !isBusy ? onCapture : null,
                  isBusy: isBusy,
                ),
              ),
              _CaptureActionButton(
                icon: Icons.image_outlined,
                label: 'Galeria',
                size: _sideButtonSize,
                onTap: isBusy ? null : onGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureActionButton extends StatelessWidget {
  const _CaptureActionButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF374151) : AppColors.textTertiary;

    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? const Color(0xFF4B5563)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraShutterButton extends StatelessWidget {
  const _CameraShutterButton({required this.onTap, required this.isBusy});

  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final ringColor = enabled ? AppColors.action500 : AppColors.textTertiary;

    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: ringColor, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ringColor,
                    ),
                  )
                : Icon(Icons.photo_camera, color: ringColor, size: 28),
          ),
        ),
      ),
    );
  }
}

class _FlashToggleButton extends StatelessWidget {
  const _FlashToggleButton({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: isOn ? 0.45 : 0.28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Icon(
            isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            size: 22,
            color: enabled
                ? (isOn ? AppColors.accent500 : Colors.white)
                : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _CameraLivePreview extends StatelessWidget {
  const _CameraLivePreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // HtmlElementView: ClipRRect/FittedBox/Transform deixam a preview preta.
      // buildPreview() + CSS object-fit:cover preenche sem distorcer.
      return ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(child: controller.buildPreview()),
      );
    }

    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const ColoredBox(color: Colors.black);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // So width (altura solta): AspectRatio interno nao recebe
            // constraints apertadas erradas, que achatariam a textura.
            return ClipRect(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CaptureErrorBanner extends StatelessWidget {
  const _CaptureErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }
}

class _CameraShell extends StatelessWidget {
  const _CameraShell({required this.child, this.clipContent = true});

  final Widget child;
  // Web: never wrap HtmlElementView in ClipRRect (preview fica preta).
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: Colors.black,
      child: DefaultTextStyle(
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
        child: IconTheme(
          data: const IconThemeData(color: AppColors.action500),
          child: child,
        ),
      ),
    );

    // Full-bleed preview. ClipRect only on mobile; ClipRRect is never used.
    return SizedBox.expand(
      key: const Key('food-capture-camera'),
      child: clipContent ? ClipRect(child: content) : content,
    );
  }
}

class _ManualFoodEntrySheet extends StatefulWidget {
  const _ManualFoodEntrySheet();

  @override
  State<_ManualFoodEntrySheet> createState() => _ManualFoodEntrySheetState();
}

class _ManualFoodEntrySheetState extends State<_ManualFoodEntrySheet> {
  static const String _entryHint =
      'Ex.: Arroz branco cozido 120g, feijão preto cozido 100g e frango grelhado 150g';

  static const String _entryInstructions =
      'Escreva os alimentos com seus preparos e quantidade que você consumiu.\n'
      '\n'
      'Ex.: Arroz branco cozido - 120 g\n'
      '\n'
      'Com tabela nutricional (opcional):\n'
      'Alimento - porção da tabela - kcal - quanto consumiu\n'
      'Ex.: Whey - 100 g - 380 kcal - consumi 30 g';

  final TextEditingController _manualEntryController = TextEditingController();
  final FocusNode _manualEntryFocusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _manualEntryFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _manualEntryController.dispose();
    _manualEntryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pageHorizontal,
          right: AppSpacing.pageHorizontal,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Digitar alimentos',
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: _entryInstructions,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.brand900Variant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 168,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.foodReviewFieldBorder),
                boxShadow: AppShadows.foodReviewField,
              ),
              clipBehavior: Clip.antiAlias,
              child: TextField(
                key: const ValueKey('manual-food-entry-field'),
                controller: _manualEntryController,
                focusNode: _manualEntryFocusNode,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                enableInteractiveSelection: true,
                cursorColor: AppColors.brand900,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _entryHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  isDense: true,
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textError,
                ),
                textAlign: TextAlign.left,
              ),
            if (_error != null) const SizedBox(height: AppSpacing.md),
            FoodReviewConfirmButton(
              isBusy: false,
              onTap: _submit,
              label: 'Continuar',
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final text = _manualEntryController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _error = 'Digite o que você comeu para continuar.';
      });
      return;
    }

    Navigator.of(context).pop(text);
  }
}

class _NoFoodIdentifiedSheet extends StatelessWidget {
  const _NoFoodIdentifiedSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.xl,
          AppSpacing.pageHorizontal,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.no_meals_outlined,
              size: 38,
              color: AppColors.brand900Variant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não identificamos alimentos na análise.',
              textAlign: TextAlign.center,
              style: AppTextStyles.homeSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Você pode voltar para a home ou tentar novamente na nova refeição.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Voltar para home',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(_NoFoodAction.goHome),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Tentar novamente',
              onPressed: () => Navigator.of(context).pop(_NoFoodAction.retry),
            ),
          ],
        ),
      ),
    );
  }
}
