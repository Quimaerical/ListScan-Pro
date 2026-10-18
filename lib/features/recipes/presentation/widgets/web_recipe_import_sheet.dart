import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/web_recipe_extractor_service.dart';
import '../../domain/models/recipe.dart';

/// Modal bottom sheet allowing users to import recipes by pasting a web link
/// (with automatic Schema.org JSON-LD parsing) or pasting raw text/OCR recognition notes.
class WebRecipeImportSheet extends StatefulWidget {
  final WebRecipeExtractorService extractorService;
  final void Function(Recipe recipe) onRecipeExtracted;

  const WebRecipeImportSheet({
    super.key,
    required this.extractorService,
    required this.onRecipeExtracted,
  });

  static Future<void> show({
    required BuildContext context,
    required WebRecipeExtractorService extractorService,
    required void Function(Recipe recipe) onRecipeExtracted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: WebRecipeImportSheet(
              extractorService: extractorService,
              onRecipeExtracted: onRecipeExtracted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<WebRecipeImportSheet> createState() => _WebRecipeImportSheetState();
}

class _WebRecipeImportSheetState extends State<WebRecipeImportSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textTitleController = TextEditingController();
  final TextEditingController _rawTextController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textTitleController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        controller.text = data.text!.trim();
      });
    }
  }

  Future<void> _extractFromWeb() async {
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa o pega un enlace web');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Recipe? recipe = await widget.extractorService.extractFromUrl(url);

      if (!mounted) return;

      if (recipe == null || recipe.ingredients.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No pudimos extraer los ingredientes automáticamente de esta página. Intenta copiar el texto de la receta y usar la pestaña "Texto / OCR".';
        });
        return;
      }

      Navigator.of(context).pop();
      widget.onRecipeExtracted(recipe);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al conectar con la página web: $e';
      });
    }
  }

  void _parseFromText() {
    final String text = _rawTextController.text.trim();
    if (text.isEmpty) {
      setState(
        () => _errorMessage = 'Por favor ingresa o pega el texto de la receta',
      );
      return;
    }

    final Recipe recipe = widget.extractorService.parseFromRawText(
      title: _textTitleController.text.trim().isNotEmpty
          ? _textTitleController.text.trim()
          : 'Receta Personalizada',
      text: text,
    );

    if (recipe.ingredients.isEmpty) {
      setState(() {
        _errorMessage =
            'No se detectaron ingredientes claros en el texto. Asegúrate de incluir cantidades (ej. "500g pollo", "2 huevos").';
      });
      return;
    }

    Navigator.of(context).pop();
    widget.onRecipeExtracted(recipe);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),

          // Header
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.brandMint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.brandMint,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Importar Receta Inteligente',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Extrae ingredientes desde una URL o texto/notas',
                      style: TextStyle(fontSize: 12.5, color: secColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Tab Bar
          Container(
            height: 42.0,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.brandMint,
                borderRadius: BorderRadius.circular(10.0),
              ),
              labelColor: AppColors.brandDarkForest,
              unselectedLabelColor: secColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              tabs: const <Widget>[
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.link_rounded, size: 18.0),
                      SizedBox(width: 6.0),
                      Text('Enlace Web'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.text_fields_rounded, size: 18.0),
                      SizedBox(width: 6.0),
                      Text('Texto / OCR'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Error Message Banner
          if (_errorMessage != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 20.0,
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
          ],

          // Tab views
          SizedBox(
            height: 240.0,
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                // TAB 1: WEB URL
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Pega el enlace de cualquier blog o sitio web de cocina:',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: secColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://ejemplo.com/receta-pollo-curry',
                        prefixIcon: const Icon(Icons.public_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 20.0),
                          tooltip: 'Pegar del portapapeles',
                          onPressed: () => _pasteFromClipboard(_urlController),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Compatible con Schema.org Recipe (Directo al Paladar, Allrecipes, Cookpad, BBC Good Food y más).',
                      style: TextStyle(fontSize: 11.5, color: secColor),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _extractFromWeb,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandMint,
                        foregroundColor: AppColors.brandDarkForest,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.brandDarkForest,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded, size: 20.0),
                      label: Text(
                        _isLoading
                            ? 'Extrayendo receta...'
                            : 'Escanear & Extraer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),

                // TAB 2: RAW TEXT / OCR
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _textTitleController,
                      decoration: InputDecoration(
                        hintText: 'Nombre de la receta (ej. Ramen Casero)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.title_rounded, size: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Expanded(
                      child: TextField(
                        controller: _rawTextController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText:
                              'Pega los ingredientes y notas aquí...\nEjemplo:\n- 500g pollo\n- 2 cdas salsa de soja\n- 1 diente de ajo',
                          alignLabelWithHint: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_rounded, size: 20.0),
                            tooltip: 'Pegar del portapapeles',
                            onPressed: () =>
                                _pasteFromClipboard(_rawTextController),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    FilledButton.icon(
                      onPressed: _parseFromText,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandMint,
                        foregroundColor: AppColors.brandDarkForest,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: const Icon(
                        Icons.playlist_add_check_rounded,
                        size: 20.0,
                      ),
                      label: const Text(
                        'Procesar Ingredientes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
