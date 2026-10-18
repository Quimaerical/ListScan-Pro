import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../../../shopping_lists/domain/models/shopping_list.dart';
import '../../../shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import '../../data/services/mlkit_ocr_service.dart';
import '../../domain/models/ocr_recognized_item.dart';
import '../../domain/services/ocr_service.dart';
import '../controllers/ocr_scan_controller.dart';
import 'ocr_image_viewer_screen.dart';
import '../widgets/ocr_interactive_image_viewer.dart';
import '../widgets/ocr_item_card.dart';

/// Screen for scanning lists and receipts using on-device OCR,
/// selecting recognized lines, and importing them into shopping lists.
class ScanListScreen extends StatefulWidget {
  final ShoppingListsController shoppingListsController;
  final String? targetListId;
  final OcrService? customOcrService;

  const ScanListScreen({
    super.key,
    required this.shoppingListsController,
    this.targetListId,
    this.customOcrService,
  });

  @override
  State<ScanListScreen> createState() => _ScanListScreenState();
}

class _ScanListScreenState extends State<ScanListScreen> {
  late final OcrScanController _ocrController;
  int _viewModeIndex = 0; // 0: Vista Imagen, 1: Vista Lista

  @override
  void initState() {
    super.initState();
    _ocrController = OcrScanController(
      ocrService: widget.customOcrService ?? MlKitOcrService(),
    );
  }

  @override
  void dispose() {
    _ocrController.dispose();
    super.dispose();
  }

  void _openFullscreenImageViewer() {
    if (_ocrController.imagePath == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            OcrImageViewerScreen(controller: _ocrController),
      ),
    );
  }

  Future<void> _handleCommitItems() async {
    final List<OcrRecognizedItem> selected = _ocrController.selectedItems;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un producto para continuar.'),
        ),
      );
      return;
    }

    if (widget.targetListId != null) {
      // Add items into existing active list
      for (final OcrRecognizedItem item in selected) {
        await widget.shoppingListsController.addItem(
          widget.targetListId!,
          item.cleanedName,
          quantity: item.quantity,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡${selected.length} productos agregados a la lista!',
            ),
            backgroundColor: AppColors.primaryMint,
          ),
        );
      }
    } else {
      // Create a new shopping list
      final DateTime now = DateTime.now();
      final String listTitle = 'Lista Escaneada ${now.day}/${now.month}';

      final ShoppingList created = await widget.shoppingListsController
          .createList(title: listTitle, colorIndex: 0);

      for (final OcrRecognizedItem item in selected) {
        await widget.shoppingListsController.addItem(
          created.id,
          item.cleanedName,
          quantity: item.quantity,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Nueva lista "$listTitle" creada con éxito!'),
            backgroundColor: AppColors.primaryMint,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ocrController,
      builder: (BuildContext context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final Color secColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        return ConstrainedScaffold(
          appBar: AppBar(
            title: const Text('Escanear con OCR'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              if (_ocrController.imagePath != null) ...<Widget>[
                IconButton(
                  tooltip: 'Pantalla completa',
                  icon: const Icon(Icons.fullscreen_rounded),
                  onPressed: _openFullscreenImageViewer,
                ),
                IconButton(
                  tooltip: 'Reiniciar',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _ocrController.reset,
                ),
              ],
            ],
          ),
          bottomNavigationBar: _ocrController.items.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryMint,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      onPressed: _ocrController.selectedCount > 0
                          ? _handleCommitItems
                          : null,
                      icon: const Icon(
                        Icons.playlist_add_check_rounded,
                        size: 22.0,
                      ),
                      label: Text(
                        widget.targetListId != null
                            ? 'Agregar (${_ocrController.selectedCount}) a la lista'
                            : 'Crear lista con (${_ocrController.selectedCount}) productos',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: _buildBody(context, isDark, textColor, secColor),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color secColor,
  ) {
    // 1. Initial State: Capture prompt (Camera or Gallery)
    if (_ocrController.imagePath == null && !_ocrController.isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 54.0,
                color: AppColors.primaryMint,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Digitalizar Lista o Ticket',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Toma una fotografía o selecciona una imagen de tus notas de compras o tickets físicos para extraer los productos automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, color: secColor, height: 1.4),
            ),
            const SizedBox(height: 32.0),

            Row(
              children: <Widget>[
                Expanded(
                  child: _CaptureOptionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Cámara',
                    subtitle: 'Tomar fotografía',
                    onTap: () =>
                        _ocrController.pickAndScanImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: _CaptureOptionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Galería',
                    subtitle: 'Elegir imagen',
                    onTap: () =>
                        _ocrController.pickAndScanImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Processing State
    if (_ocrController.isProcessing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: GlassCard(
            borderRadius: 24.0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(color: AppColors.primaryMint),
                const SizedBox(height: 20.0),
                Text(
                  'Procesando texto on-device...',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Google ML Kit está analizando las líneas de texto.',
                  style: TextStyle(fontSize: 12.5, color: secColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Results State (Recognized text items)
    return Column(
      children: <Widget>[
        // Image preview bar - Tappable to open fullscreen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GlassCard(
            onTap: _openFullscreenImageViewer,
            borderRadius: 16.0,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.file(
                    File(_ocrController.imagePath!),
                    width: 48.0,
                    height: 48.0,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${_ocrController.totalCount} líneas detectadas',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${_ocrController.selectedCount} seleccionados • Toca para abrir foto',
                        style: TextStyle(fontSize: 11.5, color: secColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir pantalla completa',
                  icon: const Icon(Icons.open_in_full_rounded, size: 20.0),
                  onPressed: _openFullscreenImageViewer,
                ),
                TextButton(
                  onPressed: () =>
                      _ocrController.selectAll(!_ocrController.allSelected),
                  child: Text(
                    _ocrController.allSelected ? 'Desmarcar' : 'Todos',
                    style: const TextStyle(
                      color: AppColors.primaryMint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Segmented control: Image view vs List view
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.crop_free_rounded, size: 18.0),
                  label: Text('En Imagen'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.format_list_bulleted_rounded, size: 18.0),
                  label: Text('En Lista'),
                ),
              ],
              selected: <int>{_viewModeIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _viewModeIndex = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primaryMint.withValues(
                  alpha: 0.20,
                ),
                selectedForegroundColor: AppColors.getPalette(
                  0,
                ).accentColor(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
            ),
          ),
        ),

        // Error message if any
        if (_ocrController.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Text(
              _ocrController.errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13.0),
            ),
          ),

        // Content: Interactive Image View OR Scrollable Cards
        Expanded(
          child: _viewModeIndex == 0
              ? Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: OcrInteractiveImageViewer(
                        imagePath: _ocrController.imagePath!,
                        items: _ocrController.items,
                        onToggleItem: (String id) =>
                            _ocrController.toggleItemSelection(id),
                        imageSize: _ocrController.imageSize,
                      ),
                    ),
                    Positioned(
                      top: 10.0,
                      left: 16.0,
                      right: 16.0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white)
                                .withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.touch_app_rounded,
                                size: 16.0,
                                color: AppColors.primaryMint,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                'Toca una caja para seleccionarla o deseleccionarla',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  itemCount: _ocrController.items.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final OcrRecognizedItem item = _ocrController.items[index];
                    return OcrItemCard(
                      item: item,
                      onToggleSelect: (_) =>
                          _ocrController.toggleItemSelection(item.id),
                      onEditName: (String newName) =>
                          _ocrController.updateItemName(item.id, newName),
                      onRemove: () => _ocrController.removeItem(item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CaptureOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CaptureOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return GlassCard(
      onTap: onTap,
      borderRadius: 20.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 22.0),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.primaryMint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28.0, color: AppColors.primaryMint),
          ),
          const SizedBox(height: 12.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(subtitle, style: TextStyle(fontSize: 12.0, color: secColor)),
        ],
      ),
    );
  }
}
