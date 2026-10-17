import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/shopping_item.dart';

/// Interactive tile representing a single shopping item with instant checkbox toggling,
/// animated strike-through styling, integer quantity stepper with up/down arrows and manual input,
/// detail chip, and swipe-to-delete dismissal.
class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final PastelPalette palette;
  final ValueChanged<bool> onToggleCompleted;
  final ValueChanged<int>? onAmountChanged;
  final VoidCallback onDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.palette,
    required this.onToggleCompleted,
    this.onAmountChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = palette.accentColor(isDark);
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Dismissible(
      key: Key('item_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.40),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.40),
            width: 0.8,
          ),
        ),
        child: Row(
          children: <Widget>[
            // Smooth custom Checkbox
            Transform.scale(
              scale: 1.05,
              child: Checkbox(
                value: item.isCompleted,
                activeColor: accentColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                side: BorderSide(
                  color: item.isCompleted
                      ? accentColor
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                          .withValues(alpha: 0.5),
                  width: 1.5,
                ),
                onChanged: (bool? value) {
                  if (value != null) {
                    onToggleCompleted(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8.0),

            // Item Name with Strikethrough
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: item.isCompleted ? FontWeight.w400 : FontWeight.w500,
                  color: item.isCompleted
                      ? textColor.withValues(alpha: 0.45)
                      : textColor,
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: textColor.withValues(alpha: 0.45),
                ),
              ),
            ),

            // Integer Stepper Counter to the right of the name
            _ItemAmountStepper(
              item: item,
              accentColor: accentColor,
              isDark: isDark,
              onAmountChanged: onAmountChanged,
            ),

            // Free-text Detail / Unit Chip if available (e.g. "kg", "paquetes")
            if (item.quantity != null && item.quantity!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                margin: const EdgeInsets.only(left: 6.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  item.quantity!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stepper widget displaying integer quantity with up/down arrows and tap-to-type input.
class _ItemAmountStepper extends StatelessWidget {
  final ShoppingItem item;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<int>? onAmountChanged;

  const _ItemAmountStepper({
    required this.item,
    required this.accentColor,
    required this.isDark,
    required this.onAmountChanged,
  });

  Future<void> _showManualInputDialog(BuildContext context) async {
    final TextEditingController textController =
        TextEditingController(text: '${item.amount}');

    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            'Cantidad para "${item.name}"',
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad entera',
              hintText: 'Ej: 1, 3, 12',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            onSubmitted: (String val) {
              final int? parsed = int.tryParse(val.trim());
              Navigator.of(ctx).pop(parsed != null ? ShoppingItem.clampAmount(parsed) : null);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () {
                final int? parsed = int.tryParse(textController.text.trim());
                Navigator.of(ctx).pop(parsed != null ? ShoppingItem.clampAmount(parsed) : null);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && result != item.amount) {
      onAmountChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = item.amount > ShoppingItem.minAmount && !item.isCompleted;
    final bool canIncrease = item.amount < ShoppingItem.maxAmount && !item.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.09),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.28 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Down arrow (decrease amount)
          InkWell(
            onTap: canDecrease ? () => onAmountChanged?.call(item.amount - 1) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19.0,
                color: canDecrease ? accentColor : accentColor.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Tappable count (opens direct number keyboard input)
          InkWell(
            onTap: !item.isCompleted ? () => _showManualInputDialog(context) : null,
            borderRadius: BorderRadius.circular(6.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
              child: Text(
                '${item.amount}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: item.isCompleted
                      ? accentColor.withValues(alpha: 0.45)
                      : accentColor,
                ),
              ),
            ),
          ),

          // Up arrow (increase amount)
          InkWell(
            onTap: canIncrease ? () => onAmountChanged?.call(item.amount + 1) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 19.0,
                color: canIncrease ? accentColor : accentColor.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
