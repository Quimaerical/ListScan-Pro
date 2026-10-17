import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// App branding widget presenting the ListScan PRO identity and SVG icon.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showBadge;
  final double fontSize;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.showBadge = true,
    this.fontSize = 20.0,
    this.textColor,
  });

  /// Factory constructor for just the icon mark
  const AppLogo.iconOnly({
    super.key,
    this.size = 32.0,
  })  : showText = false,
        showBadge = false,
        fontSize = 20.0,
        textColor = null;

  /// Factory constructor for the horizontal navbar brand
  const AppLogo.horizontal({
    super.key,
    this.size = 30.0,
    this.fontSize = 20.0,
    this.showBadge = true,
    this.textColor,
  })  : showText = true;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveTextColor = textColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // SVG Icon asset
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: SvgPicture.asset(
            'assets/icons/listscan.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),

        if (showText) ...<Widget>[
          const SizedBox(width: 9.0),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                letterSpacing: -0.5,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'List',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: effectiveTextColor,
                  ),
                ),
                const TextSpan(
                  text: 'Scan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandMint,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (showBadge) ...<Widget>[
          const SizedBox(width: 6.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: AppColors.brandMint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: AppColors.brandMint.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w800,
                color: AppColors.brandMint,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
