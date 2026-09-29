import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIconAssets {
  AppIconAssets._();

  static const String gold = 'assets/icons/gold.svg';
  static const String xp = 'assets/icons/xp.svg';
  static const String blocker = 'assets/icons/blocker.svg';
  static const String sticker = 'assets/icons/sticker.svg';
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.asset,
    this.size = 16,
    this.color,
    this.tinted = false,
  });

  const AppSvgIcon.gold({super.key, this.size = 16, this.color})
    : asset = AppIconAssets.gold,
      tinted = false;

  const AppSvgIcon.xp({super.key, this.size = 16, this.color})
    : asset = AppIconAssets.xp,
      tinted = false;

  const AppSvgIcon.blocker({super.key, this.size = 16, this.color})
    : asset = AppIconAssets.blocker,
      tinted = false;

  const AppSvgIcon.sticker({super.key, this.size = 16, this.color})
    : asset = AppIconAssets.sticker,
      tinted = true;

  final String asset;
  final double size;
  final Color? color;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: tinted && color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
