import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

/// Glassmorphic fixed bottom input bar for rapid item addition without losing focus.
class QuickAddBar extends StatefulWidget {
  final PastelPalette palette;
  final void Function(String name, String? quantity) onAdd;

  const QuickAddBar({
    super.key,
    required this.palette,
    required this.onAdd,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _showQuantityField = false;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final String name = _nameController.text.trim();
    final String qty = _qtyController.text.trim();

    if (name.isEmpty) return;

    widget.onAdd(name, qty.isNotEmpty ? qty : null);

    _nameController.clear();
    _qtyController.clear();
    _nameFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = widget.palette.accentColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        borderRadius: 22.0,
        backgroundColor: widget.palette.backgroundColor(isDark),
        borderColor: widget.palette.borderColor(isDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Plus icon / Quantity expander toggle
                IconButton(
                  tooltip: _showQuantityField ? 'Ocultar cantidad' : 'Añadir cantidad',
                  icon: Icon(
                    _showQuantityField ? Icons.tune : Icons.add_circle_outline,
                    color: accentColor,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showQuantityField = !_showQuantityField;
                    });
                  },
                ),

                // Name input field
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Agregar producto...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      hintStyle: TextStyle(
                        color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                            .withValues(alpha: 0.65),
                        fontSize: 15.0,
                      ),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),

                // Submit button
                IconButton(
                  tooltip: 'Guardar',
                  icon: Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: _handleSubmit,
                ),
              ],
            ),

            // Optional Quantity Field Drawer
            if (_showQuantityField)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0, right: 12.0, bottom: 4.0),
                child: TextField(
                  controller: _qtyController,
                  decoration: InputDecoration(
                    hintText: 'Cantidad opcional (ej: 2 kg, 1 docena, 500g)',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    hintStyle: TextStyle(
                      fontSize: 13.0,
                      color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
