import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../settings/domain/models/app_update_info.dart';

/// Dismissible glassmorphic update banner showing latest release info,
/// direct download link, and manual APK installation guidance.
class UpdateNotificationBanner extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onDismiss;

  const UpdateNotificationBanner({
    super.key,
    required this.updateInfo,
    required this.onDismiss,
  });

  void _showInstallGuideDialog(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: <Widget>[
              const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primaryMint,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Instalar APK en Android',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Pasos sencillos para actualizar desde tu navegador:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  step: '1',
                  title: 'Descarga el archivo APK',
                  description:
                      'Toca el botón "Descargar Actualización" para obtener el instalador oficial más reciente.',
                  textColor: textColor,
                  secColor: secColor,
                ),
                const SizedBox(height: 10),
                _buildGuideStep(
                  step: '2',
                  title: 'Abre el archivo descargado',
                  description:
                      'Al finalizar la descarga, pulsa en la notificación del navegador o busca el archivo en la carpeta "Descargas".',
                  textColor: textColor,
                  secColor: secColor,
                ),
                const SizedBox(height: 10),
                _buildGuideStep(
                  step: '3',
                  title: 'Permite fuentes desconocidas',
                  description:
                      'Si Android solicita confirmación, pulsa en Ajustes y activa "Permitir desde esta fuente" para tu navegador.',
                  textColor: textColor,
                  secColor: secColor,
                ),
                const SizedBox(height: 10),
                _buildGuideStep(
                  step: '4',
                  title: 'Presiona "Actualizar"',
                  description:
                      'Toca el botón Actualizar. Todas tus listas y notas se conservarán automáticamente intactas.',
                  textColor: textColor,
                  secColor: secColor,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildGuideStep({
    required String step,
    required String title,
    required String description,
    required Color textColor,
    required Color secColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryMint,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: secColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    final String targetUrl = updateInfo.apkDownloadUrl ?? updateInfo.releaseUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: GlassCard(
        borderRadius: 18.0,
        padding: const EdgeInsets.all(14.0),
        backgroundColor: AppColors.primaryMint.withValues(
          alpha: isDark ? 0.20 : 0.12,
        ),
        borderColor: AppColors.primaryMint.withValues(
          alpha: isDark ? 0.40 : 0.30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header with badge and close icon
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMint.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: AppColors.primaryMint,
                    size: 18.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Nueva versión disponible (${updateInfo.latestVersion})',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Versión actual: v${updateInfo.currentVersion}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar aviso',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.0,
                    color: secColor.withValues(alpha: 0.7),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28.0,
                    minHeight: 28.0,
                  ),
                  onPressed: onDismiss,
                ),
              ],
            ),

            if (updateInfo.releaseNotes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    height: 1.35,
                    color: secColor,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10.0),

            // Action buttons: Download & Guide
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryMint,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    await UrlLauncherHelper.launch(targetUrl);
                  },
                  icon: const Icon(
                    Icons.file_download_outlined,
                    size: 16.0,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Descargar Actualización',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryMint.withValues(alpha: 0.40),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showInstallGuideDialog(context),
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 15.0,
                    color: AppColors.primaryMint,
                  ),
                  label: const Text(
                    '¿Cómo instalar la APK?',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
