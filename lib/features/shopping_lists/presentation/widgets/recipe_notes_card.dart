import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

/// Collapsible and editable glassmorphic card for recipe instructions
/// and custom list notes positioned at the top of [ListDetailScreen].
class RecipeNotesCard extends StatefulWidget {
  final String? notes;
  final PastelPalette palette;
  final ValueChanged<String?> onNotesChanged;

  const RecipeNotesCard({
    super.key,
    required this.notes,
    required this.palette,
    required this.onNotesChanged,
  });

  @override
  State<RecipeNotesCard> createState() => _RecipeNotesCardState();
}

class _RecipeNotesCardState extends State<RecipeNotesCard> {
  bool _isExpanded = false;

  bool get _hasNotes =>
      widget.notes != null && widget.notes!.trim().isNotEmpty;

  Future<void> _showEditDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: widget.notes ?? '',
    );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = widget.palette.accentColor(isDark);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: <Widget>[
              Icon(Icons.menu_book_rounded, color: accentColor, size: 22.0),
              const SizedBox(width: 8.0),
              const Text(
                'Receta y Notas',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 12,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Escribe las notas de la receta, instrucciones de cocción o detalles de la compra...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                contentPadding: const EdgeInsets.all(14.0),
              ),
            ),
          ),
          actions: <Widget>[
            if (_hasNotes)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                onPressed: () => Navigator.of(ctx).pop('__DELETE__'),
                child: const Text('Borrar notas'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result == '__DELETE__') {
        widget.onNotesChanged(null);
      } else {
        final String clean = result.trim();
        widget.onNotesChanged(clean.isEmpty ? null : clean);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = widget.palette.accentColor(isDark);
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    // Empty state: subtle add notes button
    if (!_hasNotes) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: InkWell(
          onTap: () => _showEditDialog(context),
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.35),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.30 : 0.22),
                style: BorderStyle.solid,
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.menu_book_outlined,
                  size: 16.0,
                  color: accentColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Añadir receta o notas...',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Populated state: collapsible glass card
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: GlassCard(
        borderRadius: 16.0,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header Row: Title & Actions
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8.0),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.menu_book_rounded,
                    size: 17.0,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Receta y Notas',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  // Edit Action
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 17.0,
                      color: secColor,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28.0,
                      minHeight: 28.0,
                    ),
                    tooltip: 'Editar notas',
                    onPressed: () => _showEditDialog(context),
                  ),
                  const SizedBox(width: 4.0),
                  // Expand / Collapse Action
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20.0,
                    color: secColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4.0),

            // Content: Preview or Full multiline
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: AnimatedCrossFade(
                firstChild: Text(
                  widget.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: secColor,
                  ),
                ),
                secondChild: Container(
                  constraints: const BoxConstraints(maxHeight: 220.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      widget.notes!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
