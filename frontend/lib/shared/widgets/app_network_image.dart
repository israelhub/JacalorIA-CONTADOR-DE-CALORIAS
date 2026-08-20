import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_skeleton.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheDimension,
    this.borderRadius = 0,
    this.placeholder,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheDimension;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    if (imageUrl.isEmpty) {
      return error ?? const SizedBox.shrink();
    }

    final cacheKey = ValueKey('network-image-$imageUrl');
    final loading = placeholder ??
        AppSkeletonBox(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
        );
    final fallback = error ?? const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        key: cacheKey,
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return loading;
        },
      );
    }

    return CachedNetworkImage(
      key: cacheKey,
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheDimension,
      memCacheHeight: cacheDimension,
      placeholder: (_, __) => loading,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
