import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';
import '../controllers/shopping_lists_controller.dart';
import '../widgets/color_picker_palette.dart';
import '../widgets/export_import_sheet.dart';
import '../widgets/list_separator_tile.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/shopping_item_tile.dart';
import '../../../ocr_scan/presentation/views/scan_list_screen.dart';
import '../../../recipes/data/services/web_recipe_extractor_service.dart';
import '../../../recipes/domain/models/recipe.dart';
import '../../../recipes/domain/models/recipe_ingredient.dart';
import '../../../recipes/presentation/views/recipe_search_screen.dart';
import '../../../recipes/presentation/widgets/web_recipe_import_sheet.dart';

/// Interactive detail screen for a shopping list with instant item checkoffs,
/// live title editing, pastel palette selector, collapsible completed section,
/// and quick persistent bottom add bar.
class ListDetailScreen extends StatefulWidget {
  final String listId;
  final ShoppingListsController controller;

  const ListDetailScreen({
    super.key,
    required this.listId,
    required this.controller,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _isCompletedExpanded = true;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isCompletedExpanded = widget.controller.isCompletedExpanded;
    final ShoppingList? list = _getList();
    _titleController = TextEditingController(text: list?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  ShoppingList? _getList() {
    final int idx = widget.controller.lists.indexWhere(
      (ShoppingList l) => l.id == widget.listId,
    );
    if (idx != -1) return widget.controller.lists[idx];
    return null;
  }

  void _handleTitleChange(String newTitle) {
    final ShoppingList? list = _getList();
    if (list != null &&
        newTitle.trim().isNotEmpty &&
        newTitle.trim() != list.title) {
      widget.controller.updateList(list.copyWith(title: newTitle.trim()));
    }
  }

  void _handleColorChange(int colorIndex) {
    final ShoppingList? list = _getList();
    if (list != null) {
      widget.controller.updateList(list.copyWith(colorIndex: colorIndex));
    }
  }

  void _handleDeleteList() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('¿Eliminar lista?'),
        content: const Text(
          'Esta acción eliminará la lista y todos sus productos de forma permanente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.deleteList(widget.listId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showAddSeparatorDialog() async {
    final TextEditingController textCtrl = TextEditingController();
    final String? label = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: const Text('Nuevo Separador'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Nombre opcional (ej: Frutas, Lácteos...)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onSubmitted: (String val) => Navigator.of(ctx).pop(val),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (label != null) {
      await widget.controller.addSeparator(widget.listId, label: label);
    }
  }

  Future<void> _showRenameSeparatorDialog(ShoppingItem item) async {
    final TextEditingController textCtrl = TextEditingController(
      text: item.name,
    );
    final String? newLabel = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: const Text('Editar Separador'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Nombre opcional',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onSubmitted: (String val) => Navigator.of(ctx).pop(val),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newLabel != null) {
      await widget.controller.renameSeparator(widget.listId, item.id, newLabel);
    }
  }

  Future<void> _handleSmartLinkImport(
    BuildContext context,
    ShoppingList list,
    String url,
  ) async {
    final WebRecipeExtractorService extractor = WebRecipeExtractorService();
    await WebRecipeImportSheet.show(
      context: context,
      extractorService: extractor,
      initialUrl: url,
      onRecipeExtracted: (Recipe recipe) async {
        int added = 0;
        for (final RecipeIngredient ing in recipe.ingredients) {
          final String name = ing.name.trim();
          if (name.isNotEmpty) {
            await widget.controller.addItem(
              list.id,
              name,
              quantity: ing.measure.isNotEmpty ? ing.measure : null,
            );
            added++;
          }
        }
        if (context.mounted && added > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se importaron $added ingredientes de "${recipe.name}".',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final ShoppingList? list = _getList();

        if (list == null) {
          return const ConstrainedScaffold(
            body: Center(child: Text('Lista no encontrada')),
          );
        }

        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final PastelPalette palette = AppColors.getPalette(list.colorIndex);
        final Color accentColor = palette.accentColor(isDark);
        final Color textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final Color secColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        final List<ShoppingItem> pendingItems = list.items
            .where((ShoppingItem item) => !item.isCompleted)
            .toList();
        final List<ShoppingItem> completedItems = list.items
            .where((ShoppingItem item) => item.isCompleted)
            .toList();

        return ConstrainedScaffold(
          backgroundColor: isDark
              ? AppColors.scaffoldDark
              : palette.backgroundColor(false).withValues(alpha: 0.35),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.4,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Título de la lista',
                    ),
                    onSubmitted: _handleTitleChange,
                  ),
                ),
                if (list.hasPrices)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.5,
                    ),
                    margin: const EdgeInsets.only(left: 6.0),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.22 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.40 : 0.30,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 13.0,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Total: \$${list.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: <Widget>[
              // Toggle Pin
              IconButton(
                tooltip: list.isPinned ? 'Desfijar' : 'Fijar',
                icon: Icon(
                  list.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: list.isPinned ? accentColor : textColor,
                ),
                onPressed: () => widget.controller.togglePin(list.id),
              ),

              // Add Separator
              IconButton(
                tooltip: 'Agregar separador',
                icon: const Icon(Icons.splitscreen_rounded),
                onPressed: _showAddSeparatorDialog,
              ),

              // More options popup menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (String val) {
                  if (val == 'scan') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => ScanListScreen(
                          shoppingListsController: widget.controller,
                          targetListId: list.id,
                        ),
                      ),
                    );
                  } else if (val == 'recipes') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => RecipeSearchScreen(
                          shoppingListsController: widget.controller,
                          targetListId: list.id,
                          targetListTitle: list.title,
                        ),
                      ),
                    );
                  } else if (val == 'export') {
                    ExportImportSheet.show(
                      context: context,
                      controller: widget.controller,
                      activeList: list,
                    );
                  } else if (val == 'archive') {
                    widget.controller.toggleArchive(list.id, list.isArchived);
                  } else if (val == 'delete') {
                    _handleDeleteList();
                  }
                },
                itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'scan',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.document_scanner_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Escanear con OCR'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'recipes',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.restaurant_menu_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Buscar recetas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.ios_share_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Exportar o compartir'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          list.isArchived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(list.isArchived ? 'Desarchivar' : 'Archivar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Eliminar lista',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: 8.0,
              ),
              child: QuickAddBar(
                palette: palette,
                onFetchSuggestions: widget.controller.getProductSuggestions,
                onAdd: (String name, String? quantity) {
                  widget.controller.addItem(list.id, name, quantity: quantity);
                },
                onImportLink: (String url) {
                  _handleSmartLinkImport(context, list, url);
                },
                onImportMarkdown: (String markdownContent) async {
                  final int count = await widget.controller.importMarkdownIntoList(
                    list.id,
                    markdownContent,
                  );
                  if (context.mounted && count > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Se importaron $count elementos desde el texto.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          body: Column(
            children: <Widget>[
              // Color Picker Palette Row
              ColorPickerPalette(
                selectedIndex: list.colorIndex,
                onColorSelected: _handleColorChange,
              ),

              // Progress Bar & Counter Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: GlassCard(
                  borderRadius: 16.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  backgroundColor: palette.backgroundColor(isDark),
                  borderColor: palette.borderColor(isDark),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Progreso de compras',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: secColor,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (list.hasPrices) ...<Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.5,
                                          vertical: 1.5,
                                        ),
                                        margin: const EdgeInsets.only(right: 8.0),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                            alpha: isDark ? 0.20 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Text(
                                          'Total: \$${list.totalPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Text(
                                      '${list.completedCount} de ${list.totalCount}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: LinearProgressIndicator(
                                value: list.progressPercentage,
                                minHeight: 4.0,
                                backgroundColor: Colors.white.withValues(
                                  alpha: isDark ? 0.1 : 0.4,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Items Scrollable List
              Expanded(
                child: list.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.checklist_rtl_rounded,
                                size: 48.0,
                                color: accentColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                'Tu lista está vacía',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Escribe abajo para agregar tu primer producto.',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: secColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          88.0,
                        ),
                        children: <Widget>[
                          // Pending items and separators
                          for (final ShoppingItem item in pendingItems)
                            if (item.isSeparator)
                              ListSeparatorTile(
                                item: item,
                                palette: palette,
                                onRename: () =>
                                    _showRenameSeparatorDialog(item),
                                onDelete: () => widget.controller.deleteItem(
                                  list.id,
                                  item.id,
                                ),
                              )
                            else
                              ShoppingItemTile(
                                item: item,
                                palette: palette,
                                onToggleCompleted: (bool val) {
                                  widget.controller.toggleItem(
                                    list.id,
                                    item.id,
                                    val,
                                  );
                                },
                                onAmountChanged: (int newAmount) {
                                  widget.controller.setItemAmount(
                                    list.id,
                                    item.id,
                                    newAmount,
                                  );
                                },
                                onPriceChanged: (double? newPrice) {
                                  widget.controller.updateItemPrice(
                                    list.id,
                                    item.id,
                                    newPrice,
                                  );
                                },
                                onDelete: () {
                                  widget.controller.deleteItem(
                                    list.id,
                                    item.id,
                                  );
                                },
                              ),

                          // Completed items section
                          if (completedItems.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 16.0),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isCompletedExpanded = !_isCompletedExpanded;
                                });
                                widget.controller.toggleCompletedExpanded();
                              },
                              borderRadius: BorderRadius.circular(10.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      _isCompletedExpanded
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_right_rounded,
                                      color: secColor,
                                      size: 20.0,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      'Comprados (${completedItems.length})',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: secColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isCompletedExpanded)
                              for (final ShoppingItem item in completedItems)
                                ShoppingItemTile(
                                  item: item,
                                  palette: palette,
                                  onToggleCompleted: (bool val) {
                                    widget.controller.toggleItem(
                                      list.id,
                                      item.id,
                                      val,
                                    );
                                  },
                                  onAmountChanged: (int newAmount) {
                                    widget.controller.setItemAmount(
                                      list.id,
                                      item.id,
                                      newAmount,
                                    );
                                  },
                                  onPriceChanged: (double? newPrice) {
                                    widget.controller.updateItemPrice(
                                      list.id,
                                      item.id,
                                      newPrice,
                                    );
                                  },
                                  onDelete: () {
                                    widget.controller.deleteItem(
                                      list.id,
                                      item.id,
                                    );
                                  },
                                ),
                          ],
                          const SizedBox(height: 40.0),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
