import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';

class RecipeDetailBottomSheet extends StatefulWidget {
  final Recipe recipe;
  final void Function(List<RecipeIngredient> selectedIngredients) onImport;

  const RecipeDetailBottomSheet({
    super.key,
    required this.recipe,
    required this.onImport,
  });

  static Future<void> show({
    required BuildContext context,
    required Recipe recipe,
    required void Function(List<RecipeIngredient> selectedIngredients) onImport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecipeDetailBottomSheet(
        recipe: recipe,
        onImport: onImport,
      ),
    );
  }

  @override
  State<RecipeDetailBottomSheet> createState() => _RecipeDetailBottomSheetState();
}

class _RecipeDetailBottomSheetState extends State<RecipeDetailBottomSheet> {
  late List<RecipeIngredient> _ingredients;
  bool _instructionsExpanded = false;

  @override
  void initState() {
    super.initState();
    _ingredients = widget.recipe.ingredients
        .map((i) => i.copyWith(isSelected: true))
        .toList();
  }

  int get _selectedCount => _ingredients.where((i) => i.isSelected).length;

  void _toggleAll(bool select) {
    setState(() {
      _ingredients = _ingredients.map((i) => i.copyWith(isSelected: select)).toList();
    });
  }

  void _toggleIndex(int index) {
    setState(() {
      final current = _ingredients[index];
      _ingredients[index] = current.copyWith(isSelected: !current.isSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.recipe.thumbnailUrl != null &&
                    widget.recipe.thumbnailUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      widget.recipe.thumbnailUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.recipe.category != null)
                            Text(
                              widget.recipe.category!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryMint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (widget.recipe.category != null &&
                              widget.recipe.area != null)
                            const Text(' • '),
                          if (widget.recipe.area != null)
                            Text(
                              widget.recipe.area!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Instructions Accordion (if available)
          if (widget.recipe.instructions != null &&
              widget.recipe.instructions!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _instructionsExpanded = !_instructionsExpanded;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: AppColors.primaryMint,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Instrucciones de preparación',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _instructionsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                      if (_instructionsExpanded) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.recipe.instructions!.trim(),
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Selection controls bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredientes ($_selectedCount/${_ingredients.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => _toggleAll(_selectedCount < _ingredients.length),
                  child: Text(
                    _selectedCount < _ingredients.length
                        ? 'Seleccionar todos'
                        : 'Deseleccionar',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable list of ingredients
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return CheckboxListTile(
                  value: ingredient.isSelected,
                  onChanged: (_) => _toggleIndex(index),
                  activeColor: AppColors.primaryMint,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  title: Text(
                    ingredient.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: ingredient.isSelected
                          ? null
                          : TextDecoration.lineThrough,
                      color: ingredient.isSelected
                          ? (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)
                          : (isDark
                              ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                              : AppColors.textSecondaryLight.withValues(alpha: 0.6)),
                    ),
                  ),
                  subtitle: ingredient.measure.isNotEmpty
                      ? Text(
                          ingredient.measure,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

          // Action button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedCount > 0
                      ? () {
                          final selected = _ingredients.where((i) => i.isSelected).toList();
                          Navigator.of(context).pop();
                          widget.onImport(selected);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryMint,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(
                    'Añadir $_selectedCount ingredientes a una lista',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
