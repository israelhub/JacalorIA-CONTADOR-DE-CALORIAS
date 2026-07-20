import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../helpers/food_review_helpers.dart';
import '../helpers/image_optimizer.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
import 'food_analysis_processing_page.dart';
import 'food_review_page.dart';
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
    return _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
  }
}

class FoodCapturePage extends StatefulWidget {
  const FoodCapturePage({
    super.key,
    FoodAnalysisService? analysisService,
    FoodImagePicker? imagePicker,
  }) : _analysisService = analysisService ?? const FoodAnalysisService(),
       _imagePicker = imagePicker;

  final FoodAnalysisService _analysisService;
  final FoodImagePicker? _imagePicker;

  @override
  State<FoodCapturePage> createState() => _FoodCapturePageState();
}

class _FoodCapturePageState extends State<FoodCapturePage> {
  CameraController? _cameraController;
  bool _isBusy = false;
  String? _error;
  String? _cameraError;
  bool _isCameraInitializing = true;

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
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FoodAnalysisPageHeader(title: 'Nova refeição'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 10, child: _buildCameraArea(context)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _CaptureActions(
                      onTextEntry: _openTextEntry,
                      onCapture: _takePhoto,
                      onGallery: () => _pickAndAnalyze(ImageSource.gallery),
                      isCameraReady:
                          _cameraController?.value.isInitialized ?? false,
                      isBusy: _isBusy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraArea(BuildContext context) {
    if (_isCameraInitializing) {
      return _CameraShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: AppColors.action500),
            SizedBox(height: AppSpacing.lg),
            Text('Preparando a câmera...'),
          ],
        ),
      );
    }

    if (_cameraError != null || _cameraController == null) {
      return _CameraShell(
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
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _initializeCamera,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final controller = _cameraController!;
    return _CameraShell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: CameraPreview(controller),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
      });

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Nenhuma câmera disponível neste dispositivo.');
      }

      final backCamera = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList();
      final selectedCamera = backCamera.isNotEmpty
          ? backCamera.first
          : cameras.first;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _cameraController?.dispose();
      setState(() {
        _cameraController = null;
        _isCameraInitializing = false;
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

  Future<void> _openTextEntry() async {
    final typedItems = await showModalBottomSheet<List<FoodAnalysisItem>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _ManualFoodEntrySheet(),
    );

    if (!mounted || typedItems == null || typedItems.isEmpty) {
      return;
    }

    final aiManualAnalysis = await _pushAnalysisLoadingPage(
      imageBytes: null,
      title: 'Analisando...',
      message: 'A inteligência artificial está analisando sua refeição...',
      operation: () => widget._analysisService.recalculate(items: typedItems),
    );

    if (!mounted || aiManualAnalysis == null) {
      return;
    }

    final manualAnalysis = _hasIdentifiedFood(aiManualAnalysis)
        ? aiManualAnalysis
        : FoodAnalysisResult(
            items: typedItems,
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
      analysis: manualAnalysis,
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
      final rawBytes = await picture.readAsBytes();
      final optimized = await optimizeForAnalysis(rawBytes);
      final bytes = optimized.bytes;

      final analysis = await _pushAnalysisLoadingPage(
        imageBytes: bytes,
        title: 'Analisando...',
        message: 'A inteligência artificial está analisando sua refeição...',
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
        _error = error.toString().replaceFirst('Exception: ', '');
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
      final optimized = await optimizeForAnalysis(rawBytes);
      final bytes = optimized.bytes;

      final analysis = await _pushAnalysisLoadingPage(
        imageBytes: bytes,
        title: 'Analisando...',
        message: 'A inteligência artificial está analisando sua refeição...',
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
        _error = error.toString().replaceFirst('Exception: ', '');
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
    required this.onCapture,
    required this.onGallery,
    required this.isCameraReady,
    required this.isBusy,
  });

  final VoidCallback onTextEntry;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final bool isCameraReady;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    const shutterSize = 90.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 75,
          child: _CaptureActionButton(
            icon: Icons.edit_outlined,
            label: 'Digitar',
            onTap: onTextEntry,
          ),
        ),
        SizedBox(
          width: shutterSize,
          height: shutterSize,
          child: _CameraShutterButton(
            onTap: isCameraReady && !isBusy ? onCapture : null,
            isBusy: isBusy,
          ),
        ),
        SizedBox(
          width: 75,
          child: _CaptureActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            onTap: onGallery,
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.brand900Variant),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.brand900Variant,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.action500, width: 4),
            boxShadow: AppShadows.md,
          ),
          child: Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: Icon(
                Icons.camera_alt,
                color: AppColors.action500,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraShell extends StatelessWidget {
  const _CameraShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: child,
      ),
    );
  }
}

class _ManualFoodEntrySheet extends StatefulWidget {
  const _ManualFoodEntrySheet();

  @override
  State<_ManualFoodEntrySheet> createState() => _ManualFoodEntrySheetState();
}

class _ManualFoodEntrySheetState extends State<_ManualFoodEntrySheet> {
  static const String _entryInstructions =
      'Escreva um alimento por linha no formato: Nome - quantidade em gramas.\n'
      'Exemplo:\nArroz - 120 g\nFeijão - 90 g\nFrango grelhado - 150 g';

  final TextEditingController _manualEntryController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _manualEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
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
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.foodReviewFieldBorder),
                boxShadow: AppShadows.foodReviewField,
              ),
              child: TextField(
                key: const ValueKey('manual-food-entry-field'),
                controller: _manualEntryController,
                minLines: 6,
                maxLines: 10,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _entryInstructions,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
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
    final parsedItems = parseManualFoodBlock(_manualEntryController.text);

    if (parsedItems.isEmpty) {
      setState(() {
        _error =
            'Use o formato Nome - quantidade em gramas. Exemplo: Arroz - 120 g';
      });
      return;
    }

    final items = parsedItems
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
        .toList(growable: false);

    Navigator.of(context).pop(items);
  }
}

class _NoFoodIdentifiedSheet extends StatelessWidget {
  const _NoFoodIdentifiedSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
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
