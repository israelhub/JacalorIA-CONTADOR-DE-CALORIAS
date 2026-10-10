import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../services/missions_service.dart';

class GoldStatementPage extends StatefulWidget {
  const GoldStatementPage({super.key, MissionsService? service})
    : _service = service ?? const MissionsService();

  final MissionsService _service;

  @override
  State<GoldStatementPage> createState() => _GoldStatementPageState();
}

class _GoldStatementPageState extends State<GoldStatementPage> {
  late final Future<List<Map<String, dynamic>>> _statementFuture;

  @override
  void initState() {
    super.initState();
    _statementFuture = widget._service.fetchGoldStatement();
  }

  @override
  Widget build(BuildContext context) {
    final scrollTop = AppBackPageHeader.scrollTopInset(
      context,
      extra: AppSpacing.lg,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Extrato de ouro'),
      body: AppBackPageContent(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _statementFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppSkeletonList(
                itemCount: 5,
                itemHeight: 64,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  scrollTop,
                  AppSpacing.pageHorizontal,
                  AppSpacing.md,
                ),
              );
            }

            if (snapshot.hasError) {
              final message =
                  snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                  'Erro ao carregar extrato.';
              return Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    scrollTop,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            final entries = snapshot.data ?? const <Map<String, dynamic>>[];
            if (entries.isEmpty) {
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: scrollTop),
                  child: Text(
                    'Ainda não há movimentações de ouro.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                scrollTop,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final amount = _toInt(
                  entry['amountSigned'] ?? entry['amount'] ?? entry['value'],
                );
                final isCredit = amount >= 0;
                final type =
                    entry['sourceType']?.toString() ??
                    entry['type']?.toString() ??
                    'movimentacao';
                final dateLabel = _dateLabel(
                  entry['createdAt'] ??
                      entry['created_at'] ??
                      entry['date'] ??
                      entry['occurredAt'],
                );

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCredit
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: isCredit
                            ? AppColors.action500
                            : AppColors.missionsRewardGold,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _prettyType(type),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.brand900Variant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (dateLabel != null)
                              Text(
                                dateLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : ''}$amount',
                        style: AppTextStyles.captionStrong.copyWith(
                          color: isCredit
                              ? AppColors.action500
                              : AppColors.missionsRewardGold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _prettyType(String rawType) {
    final key = rawType.trim().toLowerCase();
    if (key == 'mission_reward') {
      return 'Recompensa de missão';
    }
    if (key == 'check_in_reward') {
      return 'Recompensa de check-in';
    }
    if (key == 'avatar_frame_purchase') {
      return 'Compra de moldura';
    }
    if (key == 'avatar_background_purchase') {
      return 'Compra de fundo';
    }
    if (key == 'jaca_emoji_purchase') {
      return 'Compra de figurinha';
    }
    if (key == 'offensive_blocker_purchase' ||
        key == 'offensive_blocker_auto_purchase') {
      return 'Compra de bloqueador';
    }
    if (key == 'streak_restore_purchase') {
      return 'Restauração de sequência';
    }
    if (key == 'blocker_purchase' || key == 'profile_blocker_purchase') {
      return 'Compra de bloqueador';
    }

    return rawType.replaceAll('_', ' ');
  }

  String? _dateLabel(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
