import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

/// Glassmorphic fixed bottom input bar for rapid item addition without losing focus,
/// with integrated local SQLite autocomplete suggestions.
class QuickAddBar extends StatefulWidget {
  final PastelPalette palette;
  final void Function(String name, String? quantity) onAdd;
  final void Function(String markdownContent)? onImportMarkdown;
  final ValueChanged<String>? onImportLink;
  final Future<List<String>> Function(String query)? onFetchSuggestions;

  const QuickAddBar({
    super.key,
    required this.palette,
    required this.onAdd,
    this.onImportMarkdown,
    this.onImportLink,
    this.onFetchSuggestions,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _showQuantityField = false;
  List<String> _suggestions = <String>[];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _qtyController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (widget.onFetchSuggestions == null) return;

    _debounceTimer?.cancel();
    final query = _nameController.text.trim();

    if (query.isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = <String>[]);
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final results = await widget.onFetchSuggestions!(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results
            .where((s) => s.toLowerCase() != query.toLowerCase())
            .toList();
      });
    });
  }

  bool _isWebUrl(String text) {
    final String trimmed = text.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  bool _isMarkdownOrMultiLine(String text) {
    if (text.contains('\n')) return true;
    final String trimmed = text.trim();
    if (trimmed.startsWith('- [') ||
        trimmed.startsWith('* [') ||
        trimmed.startsWith('• [') ||
        trimmed.startsWith('---') ||
        trimmed.startsWith('# ') ||
        trimmed.startsWith('## ') ||
        trimmed.startsWith('### ')) {
      return true;
    }
    return false;
  }

  void _handleSubmit() {
    final String rawInput = _nameController.text;
    final String name = rawInput.trim();
    final String qty = _qtyController.text.trim();

    if (name.isEmpty) return;

    if (widget.onImportLink != null && _isWebUrl(rawInput)) {
      widget.onImportLink!(rawInput.trim());
      _debounceTimer?.cancel();
      _nameController.clear();
      _qtyController.clear();
      setState(() => _suggestions = <String>[]);
      return;
    }

    if (widget.onImportMarkdown != null && _isMarkdownOrMultiLine(rawInput)) {
      widget.onImportMarkdown!(rawInput);
    } else {
      widget.onAdd(name, qty.isNotEmpty ? qty : null);
    }

    _debounceTimer?.cancel();
    _nameController.clear();
    _qtyController.clear();
    setState(() => _suggestions = <String>[]);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Autocomplete suggestions chips row
            if (_suggestions.isNotEmpty) ...[
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ActionChip(
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white.withValues(
                        alpha: isDark ? 0.12 : 0.65,
                      ),
                      side: BorderSide(
                        color: accentColor.withValues(alpha: 0.35),
                      ),
                      avatar: Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      label: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      onPressed: () {
                        _nameController.text = suggestion;
                        _handleSubmit();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],

            Row(
              children: <Widget>[
                // Plus icon / Quantity expander toggle
                IconButton(
                  tooltip: _showQuantityField
                      ? 'Ocultar cantidad'
                      : 'Añadir cantidad',
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
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Agregar producto, link o Markdown...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      hintStyle: TextStyle(
                        color:
                            (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
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
                padding: const EdgeInsets.only(
                  top: 6.0,
                  left: 12.0,
                  right: 12.0,
                  bottom: 4.0,
                ),
                child: TextField(
                  controller: _qtyController,
                  decoration: InputDecoration(
                    hintText: 'Cantidad opcional (ej: 2 kg, 1 docena, 500g)',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(
                      alpha: isDark ? 0.08 : 0.6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 13.0,
                      color:
                          (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)
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
