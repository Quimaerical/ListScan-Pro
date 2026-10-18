import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ocr_recognized_item.dart';

/// Card widget for a recognized OCR line, with checkbox selection,
/// quantity indicator, quick text editing and removal action.
class OcrItemCard extends StatelessWidget {
  final OcrRecognizedItem item;
  final ValueChanged<bool> onToggleSelect;
  final ValueChanged<String> onEditName;
  final VoidCallback onRemove;

  const OcrItemCard({
    super.key,
    required this.item,
    required this.onToggleSelect,
    required this.onEditName,
    required this.onRemove,
  });

  void _showEditDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController(
      text: item.cleanedName,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Editar producto detectado'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre del producto'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
            ),
            onPressed: () {
              final String val = textController.text.trim();
              if (val.isNotEmpty) {
                onEditName(val);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: item.isSelected
            ? AppColors.primaryMint.withValues(alpha: isDark ? 0.18 : 0.12)
            : Colors.white.withValues(alpha: isDark ? 0.04 : 0.35),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: item.isSelected
              ? AppColors.primaryMint.withValues(alpha: isDark ? 0.45 : 0.35)
              : Colors.white.withValues(alpha: isDark ? 0.08 : 0.30),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          // Selection Checkbox
          Checkbox(
            value: item.isSelected,
            activeColor: AppColors.primaryMint,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            onChanged: (bool? val) {
              if (val != null) {
                onToggleSelect(val);
              }
            },
          ),

          // Product Name (tap to edit)
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditDialog(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.cleanedName,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: item.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: item.isSelected ? textColor : secColor,
                    ),
                  ),
                  if (item.originalText != item.cleanedName &&
                      item.originalText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Original: "${item.originalText}"',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: secColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Quantity badge if detected
          if (item.quantity != null && item.quantity!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              margin: const EdgeInsets.only(right: 6.0),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                item.quantity!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryMint,
                ),
              ),
            ),

          // Edit icon
          IconButton(
            tooltip: 'Editar nombre',
            icon: Icon(
              Icons.edit_outlined,
              size: 19.0,
              color: secColor.withValues(alpha: 0.7),
            ),
            onPressed: () => _showEditDialog(context),
          ),

          // Remove item
          IconButton(
            tooltip: 'Descartar',
            icon: Icon(
              Icons.close_rounded,
              size: 20.0,
              color: const Color(0xFFEF4444).withValues(alpha: 0.7),
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
