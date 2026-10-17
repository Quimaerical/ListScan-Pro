import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../../../shopping_lists/domain/models/shopping_item.dart';
import '../../../shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';
import '../controllers/recipe_search_controller.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_detail_bottom_sheet.dart';

class RecipeSearchScreen extends StatefulWidget {
  final ShoppingListsController shoppingListsController;
  final String? targetListId;
  final String? targetListTitle;
  final RecipeSearchController? recipeSearchController;

  const RecipeSearchScreen({
    super.key,
    required this.shoppingListsController,
    this.targetListId,
    this.targetListTitle,
    this.recipeSearchController,
  });

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  late final RecipeSearchController _controller;
  late final TextEditingController _textController;
  static const Uuid _uuid = Uuid();

  static const List<String> _popularCategories = [
    'Pasta',
    'Chicken',
    'Salad',
    'Beef',
    'Soup',
    'Dessert',
    'Fish',
    'Vegetarian',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.recipeSearchController ??
        RecipeSearchController(repository: RecipeRepositoryImpl());
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    if (widget.recipeSearchController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    _controller.search(query);
  }

  void _onQuickChipSelected(String category) {
    _textController.text = category;
    _controller.search(category);
  }

  void _openRecipeDetail(Recipe recipe) {
    RecipeDetailBottomSheet.show(
      context: context,
      recipe: recipe,
      onImport: (selectedIngredients) =>
          _handleImport(recipe, selectedIngredients),
    );
  }

  Future<void> _handleImport(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    if (ingredients.isEmpty) return;

    if (widget.targetListId != null) {
      await _importIntoList(widget.targetListId!, recipe, ingredients);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ingredients.length} ingredientes añadidos a "${widget.targetListTitle ?? 'la lista'}"',
            ),
            backgroundColor: AppColors.primaryMint,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _showTargetSelectionModal(recipe, ingredients);
    }
  }

  Future<void> _importIntoList(
    String listId,
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    // Add a separator for the recipe if list already has items
    await widget.shoppingListsController.addSeparator(
      listId,
      label: 'Receta: ${recipe.name}',
    );

    for (final ing in ingredients) {
      await widget.shoppingListsController.addItem(
        listId,
        ing.name,
        quantity: ing.measure.isNotEmpty ? ing.measure : null,
      );
    }
  }

  Future<void> _showTargetSelectionModal(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lists = widget.shoppingListsController.lists
        .where((l) => !l.isArchived)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Importar ${ingredients.length} ingredientes',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona dónde deseas guardar los ingredientes de ${recipe.name}:',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryMint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.primaryMint,
                ),
              ),
              title: const Text(
                'Crear nueva lista para esta receta',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                '🍳 Receta: ${recipe.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              onTap: () async {
                Navigator.of(modalCtx).pop();

                final items = ingredients.map((ing) {
                  return ShoppingItem(
                    id: _uuid.v4(),
                    listId: '',
                    name: ing.name,
                    quantity: ing.measure.isNotEmpty ? ing.measure : null,
                    amount: 1,
                    isCompleted: false,
                    createdAt: DateTime.now(),
                  );
                }).toList();

                await widget.shoppingListsController.createList(
                  title: '🍳 ${recipe.name}',
                  initialItems: items,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lista "🍳 ${recipe.name}" creada con éxito'),
                      backgroundColor: AppColors.primaryMint,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            if (lists.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'O agregar a una lista existente:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (listCtx, idx) {
                    final item = lists[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 20,
                        color: AppColors.primaryMint,
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${item.totalCount} productos'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.02),
                      onTap: () async {
                        Navigator.of(modalCtx).pop();
                        await _importIntoList(item.id, recipe, ingredients);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${ingredients.length} ingredientes agregados a "${item.title}"',
                              ),
                              backgroundColor: AppColors.primaryMint,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(
          widget.targetListTitle != null
              ? 'Añadir Receta a "${widget.targetListTitle}"'
              : 'Explorar Recetas',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Buscar platillo (ej. pasta, pollo, pizza)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _textController.clear();
                          _controller.search('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),

          // Quick Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _popularCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _popularCategories[index];
                final isSelected =
                    _textController.text.toLowerCase() == cat.toLowerCase();

                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primaryMint.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryMint,
                  backgroundColor: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.8),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryMint
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                  onSelected: (_) => _onQuickChipSelected(cat),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results / State view
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                switch (_controller.status) {
                  case RecipeSearchStatus.initial:
                    return _buildInitialState(isDark);
                  case RecipeSearchStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMint,
                      ),
                    );
                  case RecipeSearchStatus.empty:
                    return _buildEmptyState(isDark);
                  case RecipeSearchStatus.error:
                    return _buildErrorState(isDark);
                  case RecipeSearchStatus.success:
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _controller.recipes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final recipe = _controller.recipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => _openRecipeDetail(recipe),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: AppColors.primaryMint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Encuentra inspiración culinaria',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca cualquier receta en línea e importa al instante todos sus ingredientes a tu lista de compras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              'No encontramos recetas para "${_controller.query}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con términos en inglés (ej. "carbonara", "pie", "curry") o palabras más generales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Error al consultar recetas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _controller.errorMessage ?? 'Ocurrió un error inesperado de red.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _controller.search(_controller.query),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
