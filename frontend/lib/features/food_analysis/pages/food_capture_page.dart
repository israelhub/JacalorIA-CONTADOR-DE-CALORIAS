import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_input.dart';
import '../models/food_analysis_result.dart';
import '../models/food_meal_record.dart';
import '../services/food_analysis_service.dart';
import 'food_review_page.dart';

abstract class FoodImagePicker {
  Future<XFile?> pickImage(ImageSource source);
}

class ImagePickerAdapter implements FoodImagePicker {
  ImagePickerAdapter(this._picker);

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source, imageQuality: 85);
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
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceAlt,
        elevation: 0,
        title: Text(
          'Nova refeição',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
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
    if (kIsWeb) {
      setState(() {
        _isCameraInitializing = false;
        _cameraError = null;
      });
      return;
    }

    try {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
      });

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Nenhuma câmera disponível');
      }

      final backCamera = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList();
      final selectedCamera = backCamera.isNotEmpty
          ? backCamera.first
          : cameras.first;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
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

      setState(() {
        _cameraController = null;
        _isCameraInitializing = false;
        _cameraError = error.toString().replaceFirst('Exception: ', '');
      });
    }
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

    final manualAnalysis = await widget._analysisService.recalculate(
      items: typedItems,
    );

    if (!mounted) {
      return;
    }

    final updatedMeal = await Navigator.of(context).push<FoodMealRecord>(
      MaterialPageRoute(
        builder: (_) => FoodReviewPage(
          imageBytes: null,
          analysis: manualAnalysis,
          analysisService: widget._analysisService,
        ),
      ),
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

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();
      final analysis = await widget._analysisService.analyzeImage(
        imageBytes: bytes,
        mimeType: _guessMimeType(picture.name),
      );

      if (!mounted) {
        return;
      }

      final updatedMeal = await Navigator.of(context).push<FoodMealRecord>(
        MaterialPageRoute(
          builder: (_) => FoodReviewPage(
            imageBytes: bytes,
            analysis: analysis,
            analysisService: widget._analysisService,
          ),
        ),
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

      final bytes = await image.readAsBytes();
      final analysis = await widget._analysisService.analyzeImage(
        imageBytes: bytes,
        mimeType: _guessMimeType(image.name),
      );

      if (!mounted) {
        return;
      }

      final updatedMeal = await Navigator.of(context).push<FoodMealRecord>(
        MaterialPageRoute(
          builder: (_) => FoodReviewPage(
            imageBytes: bytes,
            analysis: analysis,
            analysisService: widget._analysisService,
          ),
        ),
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

  String _guessMimeType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }
}

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
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.brand900Variant,
              ),
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
            border: Border.all(
              color: AppColors.action500,
              width: 4,
            ),
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
  final List<TextEditingController> _nameControllers = <TextEditingController>[
    TextEditingController(),
  ];

  final List<TextEditingController> _gramsControllers = <TextEditingController>[
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _gramsControllers) {
      controller.dispose();
    }
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
          children: [
            Text(
              'Digitar alimentos',
              style: AppTextStyles.homeSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _nameControllers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  return _ManualEntryRow(
                    nameController: _nameControllers[index],
                    gramsController: _gramsControllers[index],
                    onRemove: _nameControllers.length > 1
                        ? () => _removeRow(index)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar linha'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addRow() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _gramsControllers.add(TextEditingController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _nameControllers[index].dispose();
      _gramsControllers[index].dispose();
      _nameControllers.removeAt(index);
      _gramsControllers.removeAt(index);
    });
  }

  void _submit() {
    final items = <FoodAnalysisItem>[];

    for (var index = 0; index < _nameControllers.length; index++) {
      final name = _nameControllers[index].text.trim();
      final grams = int.tryParse(_gramsControllers[index].text.trim()) ?? 0;
      if (name.isEmpty || grams <= 0) {
        continue;
      }

      items.add(
        FoodAnalysisItem(
          name: name,
          grams: grams,
          unit: 'g',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
      );
    }

    Navigator.of(context).pop(items);
  }
}

class _ManualEntryRow extends StatelessWidget {
  const _ManualEntryRow({
    required this.nameController,
    required this.gramsController,
    required this.onRemove,
  });

  final TextEditingController nameController;
  final TextEditingController gramsController;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AppInputField(
            label: '',
            hint: 'Alimento',
            controller: nameController,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 96,
          child: AppInputField(
            label: '',
            hint: 'g',
            controller: gramsController,
            keyboardType: TextInputType.number,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
        ],
      ],
    );
  }
}
