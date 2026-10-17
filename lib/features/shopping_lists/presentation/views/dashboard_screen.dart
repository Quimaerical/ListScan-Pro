import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../../domain/models/shopping_list.dart';
import '../controllers/shopping_lists_controller.dart';
import '../widgets/export_import_sheet.dart';
import '../widgets/note_card_widget.dart';
import 'list_detail_screen.dart';
import '../../../ocr_scan/presentation/views/scan_list_screen.dart';
import '../../../recipes/presentation/views/recipe_search_screen.dart';

/// Main Dashboard view in the spirit of Google Keep, featuring appetizing pastel glassmorphism,
/// structured vertical lists by default, with dynamic toggle to 2-column masonry grid,
/// light/dark theme switcher, search and filters.
class DashboardScreen extends StatefulWidget {
  final ShoppingListsController controller;

  const DashboardScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadLists();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCreateNewList() async {
    final ShoppingList newList = await widget.controller.createList(
      title: 'Nueva Lista',
      colorIndex: 0,
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext ctx) => ListDetailScreen(
            listId: newList.id,
            controller: widget.controller,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final List<ShoppingList> displayLists = widget.controller.filteredLists;

        return ConstrainedScaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                Text(
                  'ShopLiist',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: AppColors.primaryMint.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryMint,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              // Toggle Theme Mode (Light / Dark)
              IconButton(
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: textColor,
                ),
                onPressed: widget.controller.toggleThemeMode,
              ),

              // Toggle View Mode (List vs Grid)
              IconButton(
                tooltip: widget.controller.isGridView
                    ? 'Ver como lista vertical'
                    : 'Ver como cuadrícula',
                icon: Icon(
                  widget.controller.isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                  color: textColor,
                ),
                onPressed: widget.controller.toggleViewMode,
              ),

              // OCR Scanner
              IconButton(
                tooltip: 'Escanear con OCR',
                icon: Icon(
                  Icons.document_scanner_outlined,
                  color: textColor,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext ctx) => ScanListScreen(
                        shoppingListsController: widget.controller,
                      ),
                    ),
                  );
                },
              ),

              // Recipes Search & Inspiration
              IconButton(
                tooltip: 'Buscar recetas e ideas',
                icon: Icon(
                  Icons.restaurant_menu_rounded,
                  color: textColor,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext ctx) => RecipeSearchScreen(
                        shoppingListsController: widget.controller,
                      ),
                    ),
                  );
                },
              ),

              // Interoperability / Import sheet
              IconButton(
                tooltip: 'Archivos e importación',
                icon: Icon(
                  Icons.folder_open_outlined,
                  color: textColor,
                ),
                onPressed: () {
                  ExportImportSheet.show(
                    context: context,
                    controller: widget.controller,
                  );
                },
              ),
              const SizedBox(width: 8.0),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _handleCreateNewList,
            backgroundColor: AppColors.primaryMint,
            elevation: 3.0,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24.0),
            label: const Text(
              'Nueva Lista',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.0,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: widget.controller.loadLists,
            color: AppColors.primaryMint,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: <Widget>[
                // Search Bar Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: GlassCard(
                      borderRadius: 18.0,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.search_rounded,
                            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar listas o productos...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                                hintStyle: TextStyle(
                                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                      .withValues(alpha: 0.65),
                                  fontSize: 14.5,
                                ),
                              ),
                              onChanged: widget.controller.setSearchQuery,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18.0),
                              onPressed: () {
                                _searchController.clear();
                                widget.controller.setSearchQuery('');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Filter Tabs Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: _FilterTabsRow(
                      selectedIndex: widget.controller.selectedFilterIndex,
                      onFilterChanged: widget.controller.setFilterIndex,
                    ),
                  ),
                ),

                // Main Content List or Grid
                if (widget.controller.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryMint),
                    ),
                  )
                else if (displayLists.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyListsPlaceholder(
                      isSearching: widget.controller.searchQuery.isNotEmpty,
                      onCreateFirstList: _handleCreateNewList,
                    ),
                  )
                else if (!widget.controller.isGridView)
                  // Structured Vertical List (Default)
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 90.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext ctx, int index) {
                          final ShoppingList list = displayLists[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: NoteCardWidget(
                              list: list,
                              isGrid: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext c) => ListDetailScreen(
                                      listId: list.id,
                                      controller: widget.controller,
                                    ),
                                  ),
                                );
                              },
                              onTogglePin: () => widget.controller.togglePin(list.id),
                              onDelete: () => widget.controller.deleteList(list.id),
                              onToggleItem: (String itemId, bool isCompleted) {
                                widget.controller.toggleItem(list.id, itemId, isCompleted);
                              },
                            ),
                          );
                        },
                        childCount: displayLists.length,
                      ),
                    ),
                  )
                else
                  // 2-Column Responsive Grid View (Toggleable)
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 90.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext ctx, int index) {
                          final ShoppingList list = displayLists[index];
                          return NoteCardWidget(
                            list: list,
                            isGrid: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (BuildContext c) => ListDetailScreen(
                                    listId: list.id,
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            },
                            onTogglePin: () => widget.controller.togglePin(list.id),
                            onDelete: () => widget.controller.deleteList(list.id),
                            onToggleItem: (String itemId, bool isCompleted) {
                              widget.controller.toggleItem(list.id, itemId, isCompleted);
                            },
                          );
                        },
                        childCount: displayLists.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterTabsRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterChanged;

  const _FilterTabsRow({
    required this.selectedIndex,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> filters = <String>['Todas', 'Pendientes', 'Archivadas'];

    return Row(
      children: List<Widget>.generate(filters.length, (int index) {
        final bool isSelected = index == selectedIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) => onFilterChanged(index),
            labelStyle: TextStyle(
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
            selectedColor: AppColors.primaryMint,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
              side: BorderSide(
                color: isSelected ? AppColors.primaryMint : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyListsPlaceholder extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreateFirstList;

  const _EmptyListsPlaceholder({
    required this.isSearching,
    required this.onCreateFirstList,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color secColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 52.0,
                color: AppColors.primaryMint,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              isSearching ? 'No se encontraron resultados' : '¡Comienza tus listas de compras!',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              isSearching
                  ? 'Prueba con otro término de búsqueda o limpia el filtro.'
                  : 'Crea listas ágiles, organízalas por colores pastel o importa notas en Markdown y CSV.',
              style: TextStyle(
                fontSize: 14.0,
                color: secColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...<Widget>[
              const SizedBox(height: 22.0),
              OutlinedButton.icon(
                onPressed: onCreateFirstList,
                icon: const Icon(Icons.add, color: AppColors.primaryMint),
                label: const Text(
                  'Crear mi primera lista',
                  style: TextStyle(
                    color: AppColors.primaryMint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryMint),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
