import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../controllers/ocr_scan_controller.dart';
import '../widgets/ocr_interactive_image_viewer.dart';

/// Fullscreen interactive viewer allowing granular visual inspection and
/// box selection directly on top of the scanned receipt or note image.
class OcrImageViewerScreen extends StatelessWidget {
  final OcrScanController controller;
  final VoidCallback? onCommit;

  const OcrImageViewerScreen({
    super.key,
    required this.controller,
    this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textColor = isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;
        final Color secColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        if (controller.imagePath == null) {
          return const ConstrainedScaffold(
            body: Center(child: Text('No hay imagen para mostrar.')),
          );
        }

        return ConstrainedScaffold(
          appBar: AppBar(
            title: const Text('Revisar en Imagen'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => controller.selectAll(!controller.allSelected),
                child: Text(
                  controller.allSelected ? 'Desmarcar' : 'Todos',
                  style: const TextStyle(
                    color: AppColors.primaryMint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: GlassCard(
                borderRadius: 18.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${controller.selectedCount} de ${controller.totalCount} seleccionados',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Toca una caja sobre la imagen para cambiarla',
                            style: TextStyle(fontSize: 11.5, color: secColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryMint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 12.0,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Listo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: OcrInteractiveImageViewer(
            imagePath: controller.imagePath!,
            items: controller.items,
            onToggleItem: (String id) => controller.toggleItemSelection(id),
            imageSize: controller.imageSize,
          ),
        );
      },
    );
  }
}
