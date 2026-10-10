import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_network_image.dart';

bool hasFadedMealImage({
  required String? imageAsset,
  required Uint8List? imageBytes,
  required String? imageUrl,
}) {
  if (imageBytes != null && imageBytes.isNotEmpty) {
    return true;
  }
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    return true;
  }
  if (imageAsset != null && imageAsset.trim().isNotEmpty) {
    return true;
  }
  return false;
}

class FadedMealImage extends StatelessWidget {
  const FadedMealImage({
    super.key,
    this.imageAsset,
    this.imageBytes,
    this.imageUrl,
  });

  final String? imageAsset;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = _image();
    if (image == null) {
      return const MealImageFallback();
    }

    return SizedBox.expand(child: image);
  }

  Widget? _image() {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }
    if (imageUrl != null) {
      return AppNetworkImage(
        url: imageUrl!,
        fit: BoxFit.cover,
        error: const MealImageFallback(),
      );
    }
    final asset = imageAsset;
    if (asset != null) {
      return Image.asset(asset, fit: BoxFit.cover, alignment: Alignment.center);
    }
    return null;
  }
}

class MealImageFallback extends StatelessWidget {
  const MealImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.restaurant_outlined,
        size: 40,
        color: AppColors.action500,
      ),
    );
  }
}
