import 'package:flutter/material.dart';

import '../../features/avatar_frames/models/avatar_background_catalog.dart';
import '../theme/app_theme.dart';
import 'framed_avatar.dart';

class AvatarProfilePreview extends StatelessWidget {
  const AvatarProfilePreview({
    super.key,
    required this.avatarUrl,
    required this.frameId,
    required this.name,
    this.backgroundId,
    this.height = defaultHeight,
    this.avatarSize,
  });

  /// Altura padrao do banner no perfil / loja.
  static const double defaultHeight = 173;

  /// Proporcao tipica do banner (largura / [defaultHeight]), usada no catalogo.
  /// Calibrada no layout real (~598x177).
  static const double bannerAspectRatio = 598 / 177;

  final String? avatarUrl;
  final String? frameId;
  final String? backgroundId;
  final String name;
  final double height;
  final double? avatarSize;

  @override
  Widget build(BuildContext context) {
    final backgroundAssetPath = AvatarBackgroundCatalog.assetPathForId(
      backgroundId,
    );

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.homeProgressTrack,
        image: backgroundAssetPath == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundAssetPath),
                fit: BoxFit.cover,
              ),
      ),
      child: Center(
        child: FramedAvatar(
          size: avatarSize ?? AppSpacing.huge * 3.4,
          avatarUrl: avatarUrl,
          frameId: frameId,
          fallbackText: name,
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
