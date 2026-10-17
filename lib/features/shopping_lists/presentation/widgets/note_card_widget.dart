import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';

/// Note card widget styled in the spirit of Google Keep with delicious pastel glassmorphism.
/// Adaptively renders for both structured vertical lists and compact 2-column masonry grids.
class NoteCardWidget extends StatelessWidget {
  final ShoppingList list;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final void Function(String itemId, bool isCompleted)? onToggleItem;

  const NoteCardWidget({
    super.key,
    required this.list,
    required this.isGrid,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final PastelPalette palette = AppColors.getPalette(list.colorIndex);
    final Color accentColor = palette.accentColor(isDark);
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final int maxPreviewItems = isGrid ? 3 : 5;
    final List<ShoppingItem> previewItems = list.items.take(maxPreviewItems).toList();
    final int remainingItems = list.items.length - maxPreviewItems;

    return GlassCard(
      onTap: onTap,
      backgroundColor: palette.backgroundColor(isDark),
      borderColor: palette.borderColor(isDark),
      borderRadius: 20.0,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header: Title & Pin/Menu actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  list.title,
                  style: TextStyle(
                    fontSize: isGrid ? 16.0 : 17.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (list.isPinned)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 18.0,
                    color: accentColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Items preview list
          if (list.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                'Lista vacía',
                style: TextStyle(
                  fontSize: 13.0,
                  fontStyle: FontStyle.italic,
                  color: secondaryTextColor.withValues(alpha: 0.7),
                ),
              ),
            )
          else ...<Widget>[
            for (final ShoppingItem item in previewItems)
              _PreviewItemRow(
                item: item,
                accentColor: accentColor,
                textColor: textColor,
                onToggle: onToggleItem != null
                    ? (bool val) => onToggleItem!(item.id, val)
                    : null,
              ),

            if (remainingItems > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                child: Text(
                  '+ $remainingItems más...',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 10.0),

          // Subtle progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: list.progressPercentage,
              backgroundColor: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 3.5,
            ),
          ),

          const SizedBox(height: 8.0),

          // Footer: Item counter & Completion chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${list.completedCount}/${list.totalCount} completados',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              if (list.totalCount > 0 && list.completedCount == list.totalCount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '¡Lista lista!',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewItemRow extends StatelessWidget {
  final ShoppingItem item;
  final Color accentColor;
  final Color textColor;
  final ValueChanged<bool>? onToggle;

  const _PreviewItemRow({
    required this.item,
    required this.accentColor,
    required this.textColor,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle != null ? () => onToggle!(!item.isCompleted) : null,
            child: Container(
              width: 16.0,
              height: 16.0,
              decoration: BoxDecoration(
                color: item.isCompleted ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: item.isCompleted ? accentColor : textColor.withValues(alpha: 0.35),
                  width: 1.3,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 11.0,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.0,
                color: item.isCompleted ? textColor.withValues(alpha: 0.45) : textColor,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
