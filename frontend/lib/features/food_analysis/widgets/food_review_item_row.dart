import 'package:flutter/material.dart';

import '../../../shared/widgets/app_input.dart';
import '../../../shared/theme/app_theme.dart';

class FoodReviewItemRow extends StatelessWidget {
  const FoodReviewItemRow({
    super.key,
    required this.index,
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppInput(
              key: ValueKey('food-review-name-field-$index'),
              controller: nameController,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          _QuantityInput(
            index: index,
            quantityController: quantityController,
            unitController: unitController,
            onChanged: onChanged,
          ),
          const SizedBox(width: 4),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete),
              color: AppColors.foodReviewDeleteIcon,
              iconSize: 24,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 26),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _QuantityInput extends StatefulWidget {
  const _QuantityInput({
    required this.index,
    required this.quantityController,
    required this.unitController,
    required this.onChanged,
  });

  final int index;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final VoidCallback onChanged;

  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<_QuantityInput> {
  late final TextEditingController _combinedController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final qty = widget.quantityController.text;
    final unit = widget.unitController.text;
    _combinedController = TextEditingController(text: '$qty $unit');
  }

  @override
  void dispose() {
    _combinedController.dispose();
    super.dispose();
  }

  void _onCombinedChanged(String value) {
    if (_isSyncing) return;
    _isSyncing = true;

    final trimmed = value.trim();
    final parts = trimmed.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      widget.quantityController.text = parts[0];
      widget.unitController.text = parts.sublist(1).join(' ');
    } else if (parts.length == 1) {
      final match = RegExp(r'^(\d+)(\D+)$').firstMatch(parts[0]);
      if (match != null) {
        widget.quantityController.text = match.group(1)!;
        widget.unitController.text = match.group(2)!;
      } else {
        widget.quantityController.text = parts[0];
      }
    }

    _isSyncing = false;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: AppInput(
        key: ValueKey('food-review-quantity-field-${widget.index}'),
        controller: _combinedController,
        onChanged: _onCombinedChanged,
        textCapitalization: TextCapitalization.none,
      ),
    );
  }
}
