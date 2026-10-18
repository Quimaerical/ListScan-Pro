import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/shopping_item.dart';

/// Visual divider widget with optional label used to section items within a shopping list.
/// Separators do not count toward progress or completed totals.
class ListSeparatorTile extends StatelessWidget {
  final ShoppingItem item;
  final PastelPalette palette;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ListSeparatorTile({
    super.key,
    required this.item,
    required this.palette,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = palette.accentColor(isDark);
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final bool hasLabel = item.name.trim().isNotEmpty;

    return Dismissible(
      key: Key('separator_${item.id}'),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
        child: Row(
          children: <Widget>[
            // Leading line
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      accentColor.withValues(alpha: 0.05),
                      accentColor.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Optional Label Chip
            InkWell(
              onTap: onRename,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: hasLabel ? 12.0 : 8.0,
                  vertical: 4.0,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: palette.backgroundColor(isDark),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: palette.borderColor(isDark),
                    width: 0.8,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.tag_rounded, size: 14.0, color: accentColor),
                    if (hasLabel) ...<Widget>[
                      const SizedBox(width: 5.0),
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4.0),
                    Icon(
                      Icons.edit_rounded,
                      size: 12.0,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),

            // Trailing line
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      accentColor.withValues(alpha: 0.5),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
