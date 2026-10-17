import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/shopping_item.dart';

/// Interactive tile representing a single shopping item with instant checkbox toggling,
/// animated strike-through styling, quantity badge, and swipe-to-delete dismissal.
class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final PastelPalette palette;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.palette,
    required this.onToggleCompleted,
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

            // Quantity Chip if available
            if (item.quantity != null && item.quantity!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                margin: const EdgeInsets.only(left: 8.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  item.quantity!,
                  style: TextStyle(
                    fontSize: 12.0,
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
