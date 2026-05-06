import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/theme/app_theme.dart';

class SocialQrScanSheet extends StatefulWidget {
  const SocialQrScanSheet({super.key});

  @override
  State<SocialQrScanSheet> createState() => _SocialQrScanSheetState();
}

class _SocialQrScanSheetState extends State<SocialQrScanSheet> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: MobileScanner(
            onDetect: (capture) {
              if (_handled || capture.barcodes.isEmpty) return;
              final value = capture.barcodes.first.rawValue;
              if (value == null || value.trim().isEmpty) return;
              _handled = true;
              Navigator.of(context).pop(value.trim());
            },
          ),
        ),
      ),
    );
  }
}
