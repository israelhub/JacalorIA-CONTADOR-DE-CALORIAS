import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'app_skeleton.dart';

class AppImageCacheManager {
  AppImageCacheManager._();

  static const key = 'jacaloriaImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 400,
    ),
  );
}

class MemCacheSize {
  const MemCacheSize({this.width, this.height});

  final int? width;
  final int? height;
}

MemCacheSize resolveAspectSafeMemCache({
  double? width,
  double? height,
  required double devicePixelRatio,
}) {
  final dpr = devicePixelRatio <= 0 ? 2.0 : devicePixelRatio;
  final w = _finitePositivePixels(width, dpr);
  final h = _finitePositivePixels(height, dpr);
  if (w == null && h == null) {
    return const MemCacheSize();
  }
  if (w != null && h != null) {
    if (w >= h) {
      return MemCacheSize(width: w);
    }
    return MemCacheSize(height: h);
  }
  return MemCacheSize(width: w, height: h);
}

int? _finitePositivePixels(double? logical, double dpr) {
  if (logical == null || !logical.isFinite || logical <= 0) {
    return null;
  }
  final px = (logical * dpr).round();
  return px > 0 ? px : null;
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.placeholder,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
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

    final memCache = resolveAspectSafeMemCache(
      width: width,
      height: height,
      devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0,
    );

    return CachedNetworkImage(
      key: cacheKey,
      imageUrl: imageUrl,
      cacheKey: imageUrl,
      cacheManager: AppImageCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCache.width,
      memCacheHeight: memCache.height,
      maxWidthDiskCache: memCache.width,
      maxHeightDiskCache: memCache.height,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => loading,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
