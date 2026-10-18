import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/config/endpoint_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constrained_scaffold.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/app_logo.dart';
import '../controllers/settings_controller.dart';

/// Screen for configuring app preferences, recipe ingestion APIs, and local storage.
class SettingsScreen extends StatefulWidget {
  final SettingsController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _customApiKeyController;
  late final TextEditingController _geminiApiKeyController;
  bool _obscureCustomKey = true;
  bool _obscureGeminiKey = true;

  @override
  void initState() {
    super.initState();
    _customApiKeyController = TextEditingController(
      text: widget.controller.customRecipeApiKey,
    );
    _geminiApiKeyController = TextEditingController(
      text: widget.controller.geminiApiKey,
    );
    widget.controller.loadSettings().then((_) {
      if (mounted) {
        _customApiKeyController.text = widget.controller.customRecipeApiKey;
        _geminiApiKeyController.text = widget.controller.geminiApiKey;
      }
    });
  }

  @override
  void dispose() {
    _customApiKeyController.dispose();
    _geminiApiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKeys() {
    widget.controller.setCustomRecipeApiKey(_customApiKeyController.text);
    widget.controller.setGeminiApiKey(_geminiApiKeyController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración de APIs guardada en la base de datos.'),
        backgroundColor: AppColors.brandMint,
        behavior: SnackBarBehavior.floating,
      ),
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

    return ConstrainedScaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            children: <Widget>[
              // Brand Banner
              _SettingsBrandBanner(isDark: isDark),
              const SizedBox(height: 20.0),

              // Section: Appearance & View Mode
              _SettingsSectionHeader(
                title: 'Apariencia y Visualización',
                isDark: isDark,
              ),
              const SizedBox(height: 8.0),
              _AppearanceCard(
                controller: widget.controller,
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 20.0),

              // Section: Recipe APIs & Ingestion
              _SettingsSectionHeader(
                title: 'Fuentes de Recetas e Ingestión',
                isDark: isDark,
              ),
              const SizedBox(height: 8.0),
              _RecipeSourcesCard(
                controller: widget.controller,
                isDark: isDark,
                textColor: textColor,
                secColor: secColor,
                customApiKeyController: _customApiKeyController,
                geminiApiKeyController: _geminiApiKeyController,
                obscureCustomKey: _obscureCustomKey,
                obscureGeminiKey: _obscureGeminiKey,
                onToggleObscureCustomKey: () =>
                    setState(() => _obscureCustomKey = !_obscureCustomKey),
                onToggleObscureGeminiKey: () =>
                    setState(() => _obscureGeminiKey = !_obscureGeminiKey),
                onSave: _saveApiKeys,
              ),
              const SizedBox(height: 20.0),

              // Section: Storage & Database Stats
              _SettingsSectionHeader(
                title: 'Almacenamiento Local (SQLite)',
                isDark: isDark,
              ),
              const SizedBox(height: 8.0),
              _DatabaseStatsCard(
                controller: widget.controller,
                isDark: isDark,
                textColor: textColor,
                secColor: secColor,
              ),
              const SizedBox(height: 20.0),

              // Section: About
              _AboutAppCard(
                isDark: isDark,
                textColor: textColor,
                secColor: secColor,
              ),
              const SizedBox(height: 32.0),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsBrandBanner extends StatelessWidget {
  final bool isDark;

  const _SettingsBrandBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.brandDarkForest.withValues(
          alpha: isDark ? 0.40 : 0.08,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.brandMint.withValues(alpha: isDark ? 0.30 : 0.20),
          width: 1.0,
        ),
      ),
      child: const Row(
        children: <Widget>[
          AppLogo.iconOnly(size: 46.0),
          SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppLogo.horizontal(size: 24.0, fontSize: 18.0),
                SizedBox(height: 4.0),
                Text(
                  'Gestión inteligente de listas, recetas y OCR',
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SettingsSectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.brandMint : AppColors.primaryMint,
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;
  final Color textColor;

  const _AppearanceCard({
    required this.controller,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Theme Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppColors.brandMint,
                      size: 22.0,
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: controller.themeMode == ThemeMode.dark,
                  activeTrackColor: AppColors.brandMint,
                  onChanged: (bool val) {
                    controller.setThemeMode(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20.0),

            // View Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      controller.isGridView
                          ? Icons.grid_view_rounded
                          : Icons.view_agenda_outlined,
                      color: AppColors.brandMint,
                      size: 22.0,
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Vista de Cuadrícula',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: controller.isGridView,
                  activeTrackColor: AppColors.brandMint,
                  onChanged: (_) => controller.toggleGridView(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSourcesCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;
  final Color textColor;
  final Color secColor;
  final TextEditingController customApiKeyController;
  final TextEditingController geminiApiKeyController;
  final bool obscureCustomKey;
  final bool obscureGeminiKey;
  final VoidCallback onToggleObscureCustomKey;
  final VoidCallback onToggleObscureGeminiKey;
  final VoidCallback onSave;

  const _RecipeSourcesCard({
    required this.controller,
    required this.isDark,
    required this.textColor,
    required this.secColor,
    required this.customApiKeyController,
    required this.geminiApiKeyController,
    required this.obscureCustomKey,
    required this.obscureGeminiKey,
    required this.onToggleObscureCustomKey,
    required this.onToggleObscureGeminiKey,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // TheMealDB Switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'TheMealDB (Cocina Internacional)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                'Recetas tradicionales, mediterráneas y occidentales.',
                style: TextStyle(fontSize: 12.0, color: secColor),
              ),
              value: controller.enableTheMealDb,
              activeTrackColor: AppColors.brandMint,
              onChanged: controller.setEnableTheMealDb,
            ),
            const Divider(height: 16.0),

            // Asian & Extended Open Provider
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Cocina Asiática & Extendida (Forkify Open)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                'Ramen, Sushi, Pad Thai, Curries, Dim Sum, Bibimbap y más de 1M de recetas sin API key.',
                style: TextStyle(fontSize: 12.0, color: secColor),
              ),
              value: controller.enableAsianRecipes,
              activeTrackColor: AppColors.brandMint,
              onChanged: controller.setEnableAsianRecipes,
            ),
            const Divider(height: 16.0),

            // Custom API / Spoonacular key field
            Text(
              'API Key Personalizada de Recetas (Opcional)',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Añade una clave para Spoonacular u otra API si deseas recetas ilimitadas en español nativo.',
              style: TextStyle(fontSize: 12.0, color: secColor),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: customApiKeyController,
              obscureText: obscureCustomKey,
              decoration: InputDecoration(
                hintText: 'Ingresa tu API Key...',
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureCustomKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleObscureCustomKey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Gemini AI API key field
            Text(
              'Google Gemini API Key (Opcional)',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Permite enriquecer el reconocimiento inteligente de ingredientes desde textos desestructurados.',
              style: TextStyle(fontSize: 12.0, color: secColor),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: geminiApiKeyController,
              obscureText: obscureGeminiKey,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                prefixIcon: const Icon(Icons.auto_awesome_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureGeminiKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleObscureGeminiKey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Save APIs button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandMint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'Guardar Ajustes de APIs',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatabaseStatsCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;
  final Color textColor;
  final Color secColor;

  const _DatabaseStatsCard({
    required this.controller,
    required this.isDark,
    required this.textColor,
    required this.secColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _StatTile(
                  title: 'Listas Guardadas',
                  value: '${controller.databaseListCount}',
                  icon: Icons.format_list_bulleted_rounded,
                  textColor: textColor,
                  secColor: secColor,
                ),
                Container(
                  height: 36.0,
                  width: 1.0,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                _StatTile(
                  title: 'Productos Totales',
                  value: '${controller.databaseItemCount}',
                  icon: Icons.shopping_basket_rounded,
                  textColor: textColor,
                  secColor: secColor,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            TextButton.icon(
              onPressed: () => controller.refreshDatabaseStats(),
              icon: const Icon(Icons.refresh_rounded, size: 18.0),
              label: const Text('Actualizar estadísticas de almacenamiento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color textColor;
  final Color secColor;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.textColor,
    required this.secColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 24.0, color: AppColors.brandMint),
        const SizedBox(height: 6.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12.0, color: secColor)),
      ],
    );
  }
}

class _AboutAppCard extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final Color secColor;

  const _AboutAppCard({
    required this.isDark,
    required this.textColor,
    required this.secColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'ListScan PRO v1.0.4',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Arquitectura Offline-First con SQLite. Tus listas, datos y claves se almacenan exclusivamente en tu dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.0, color: secColor, height: 1.4),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Diseñado y desarrollado por Quimaerical',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.0, color: secColor, height: 1.4),
            ),
            const SizedBox(height: 8.0),
            InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                final url = EndpointSecurity.getGitHubReleasesWebUrl().replaceAll('/releases', '');
                UrlLauncherHelper.launch(url);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abriendo repositorio en GitHub...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.code_rounded,
                      size: 14.0,
                      color: isDark ? AppColors.brandMint : AppColors.primaryMint,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Repositorio en GitHub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.brandMint : AppColors.primaryMint,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
