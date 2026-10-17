import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Horizontal row of appetizing pastel color swatches allowing the user
/// to customize the glassmorphic tone of the active list.
class ColorPickerPalette extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const ColorPickerPalette({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          AppColors.palettes.length,
          (int index) => _ColorSwatchItem(
            palette: AppColors.palettes[index],
            isSelected: index == selectedIndex,
            isDark: isDark,
            onTap: () => onColorSelected(index),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchItem extends StatelessWidget {
  final PastelPalette palette;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ColorSwatchItem({
    required this.palette,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = palette.backgroundColor(isDark);
    final Color accentColor = palette.accentColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? accentColor : Colors.white.withValues(alpha: isDark ? 0.20 : 0.60),
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: <BoxShadow>[
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                ),
            ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: accentColor,
                )
              : null,
        ),
      ),
    );
  }
}
