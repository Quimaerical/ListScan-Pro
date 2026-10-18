import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/native_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../domain/models/shopping_list.dart';
import '../controllers/shopping_lists_controller.dart';

/// Modal bottom sheet for exporting lists to Markdown/CSV, copying to clipboard,
/// sharing directly to other applications, or importing local files.
class ExportImportSheet extends StatefulWidget {
  final ShoppingListsController controller;
  final ShoppingList? activeList;

  const ExportImportSheet({
    super.key,
    required this.controller,
    this.activeList,
  });

  static Future<void> show({
    required BuildContext context,
    required ShoppingListsController controller,
    ShoppingList? activeList,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) =>
          ExportImportSheet(controller: controller, activeList: activeList),
    );
  }

  @override
  State<ExportImportSheet> createState() => _ExportImportSheetState();
}

class _ExportImportSheetState extends State<ExportImportSheet> {
  late bool _includeNotes;

  @override
  void initState() {
    super.initState();
    _includeNotes = widget.activeList?.hasNotes == true;
  }

  Future<void> _handleShareDirectly(BuildContext context) async {
    if (widget.activeList == null) return;
    final String mdContent = widget.controller.exportToMarkdown(
      widget.activeList!,
      includeNotes: _includeNotes,
    );
    Navigator.of(context).pop();
    final bool shared = await NativeShareService.shareText(
      text: mdContent,
      title: widget.activeList!.title,
    );
    if (!shared && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista copiada al portapapeles.'),
          backgroundColor: AppColors.primaryMint,
        ),
      );
    }
  }

  Future<void> _handleSaveMarkdown(BuildContext context) async {
    if (widget.activeList == null) return;
    final String mdContent = widget.controller.exportToMarkdown(
      widget.activeList!,
      includeNotes: _includeNotes,
    );
    final String filename =
        '${widget.activeList!.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.md';

    await _saveContentToFile(
      context: context,
      filename: filename,
      content: mdContent,
      extension: 'md',
    );
  }

  Future<void> _handleSaveCsv(BuildContext context) async {
    if (widget.activeList == null) return;
    final String csvContent = widget.controller.exportToCsv(
      widget.activeList!,
      includeNotes: _includeNotes,
    );
    final String filename =
        '${widget.activeList!.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.csv';

    await _saveContentToFile(
      context: context,
      filename: filename,
      content: csvContent,
      extension: 'csv',
    );
  }

  Future<void> _saveContentToFile({
    required BuildContext context,
    required String filename,
    required String content,
    required String extension,
  }) async {
    try {
      final FileSaveLocation? location = await getSaveLocation(
        suggestedName: filename,
        acceptedTypeGroups: <XTypeGroup>[
          XTypeGroup(
            label: extension.toUpperCase(),
            extensions: <String>[extension],
          ),
        ],
      );

      String? targetPath = location?.path;
      if (targetPath == null) {
        // Fallback when system save dialog is cancelled or unavailable
        final Directory dir = await getApplicationDocumentsDirectory();
        targetPath = '${dir.path}/$filename';
      }

      final File file = File(targetPath);
      await file.writeAsString(content, flush: true);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado con éxito en: $filename'),
            backgroundColor: AppColors.primaryMint,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar archivo: $e')));
      }
    }
  }

  Future<void> _handleCopyToClipboard(BuildContext context) async {
    if (widget.activeList == null) return;
    final String mdContent = widget.controller.exportToMarkdown(
      widget.activeList!,
      includeNotes: _includeNotes,
    );
    await Clipboard.setData(ClipboardData(text: mdContent));

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Lista copiada al portapapeles! Lista para pegar en cualquier app.',
          ),
          backgroundColor: AppColors.primaryMint,
        ),
      );
    }
  }

  Future<void> _handleImportFile(BuildContext context) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Listas de compras (.md, .csv)',
      extensions: <String>['md', 'csv', 'txt'],
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[typeGroup],
    );

    if (file == null) return;

    final String content = await file.readAsString();

    if (content.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo seleccionado está vacío.')),
        );
      }
      return;
    }

    final ShoppingList importedList = await widget.controller.importFromContent(
      filename: file.name,
      content: content,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Lista "${importedList.title}" importada con éxito!'),
          backgroundColor: AppColors.primaryMint,
        ),
      );
    }
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: GlassCard(
        borderRadius: 24.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grabber handle
            Center(
              child: Container(
                width: 40.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            Text(
              'Interoperabilidad & Archivos',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Guarda tus listas en el dispositivo, cópialas o importa archivos sin dependencias externas.',
              style: TextStyle(
                fontSize: 13.0,
                color: (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 18.0),

            if (widget.activeList != null && widget.activeList!.hasNotes) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.50),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.40),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _includeNotes,
                  onChanged: (bool value) {
                    setState(() {
                      _includeNotes = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF6366F1),
                      size: 20.0,
                    ),
                  ),
                  title: Text(
                    'Incluir receta y notas',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    _includeNotes
                        ? 'Se exportarán las instrucciones y notas de la receta.'
                        : 'Solo se exportará la lista de compras.',
                    style: TextStyle(fontSize: 12.0, color: secColor),
                  ),
                  activeTrackColor: AppColors.primaryMint,
                ),
              ),
              const SizedBox(height: 12.0),
            ],

            if (widget.activeList != null) ...<Widget>[
              // Direct Native Share tile
              _SheetActionTile(
                icon: Icons.share_rounded,
                iconColor: AppColors.primaryMint,
                title: 'Compartir a otra aplicación',
                subtitle:
                    'Envía la lista directamente por WhatsApp, Telegram, Correo o Mensajes.',
                onTap: () => _handleShareDirectly(context),
              ),
              const SizedBox(height: 10.0),

              // Copy to Clipboard tile
              _SheetActionTile(
                icon: Icons.copy_all_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Copiar al Portapapeles',
                subtitle:
                    'Copia el checklist en Markdown para pegarlo donde prefieras.',
                onTap: () => _handleCopyToClipboard(context),
              ),
              const SizedBox(height: 10.0),

              // Save Markdown tile
              _SheetActionTile(
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'Guardar archivo Markdown (.md)',
                subtitle:
                    'Guarda la lista para abrirla en Obsidian, Notability o editores de texto.',
                onTap: () => _handleSaveMarkdown(context),
              ),
              const SizedBox(height: 10.0),

              // Save CSV tile
              _SheetActionTile(
                icon: Icons.table_chart_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Guardar archivo CSV (.csv)',
                subtitle:
                    'Guarda la lista para abrirla en Microsoft Excel, Hojas de cálculo o Notion.',
                onTap: () => _handleSaveCsv(context),
              ),
              const SizedBox(height: 10.0),
            ],

            // Import File tile
            _SheetActionTile(
              icon: Icons.file_upload_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Importar Archivo (.md o .csv)',
              subtitle:
                  'Selecciona un archivo local del dispositivo para agregarlo como lista.',
              onTap: () => _handleImportFile(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.iconColor,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.50),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.40),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22.0),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.0, color: secColor),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: secColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
