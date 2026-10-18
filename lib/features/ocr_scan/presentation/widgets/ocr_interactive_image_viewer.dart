import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ocr_recognized_item.dart';

/// Interactive on-image OCR bounding boxes inspector and selector.
/// Supports zooming, panning, and toggling bounding box selection via tap.
class OcrInteractiveImageViewer extends StatelessWidget {
  final String imagePath;
  final List<OcrRecognizedItem> items;
  final ValueChanged<String> onToggleItem;
  final Size? imageSize;

  const OcrInteractiveImageViewer({
    super.key,
    required this.imagePath,
    required this.items,
    required this.onToggleItem,
    this.imageSize,
  });

  void _handleTap(Offset localTap, double scaleX, double scaleY) {
    if (scaleX <= 0 || scaleY <= 0) return;

    final Offset imageTap = Offset(localTap.dx / scaleX, localTap.dy / scaleY);

    OcrRecognizedItem? bestMatch;
    double minDistance = double.infinity;
    final double marginX = 24.0 / scaleX;
    final double marginY = 24.0 / scaleY;

    for (final OcrRecognizedItem item in items) {
      final Rect? box = item.boundingBox;
      if (box == null) continue;

      // Inflate by ~24 screen pixels in each direction to ensure effortless tapping
      final Rect hitBox = Rect.fromLTRB(
        box.left - marginX,
        box.top - marginY,
        box.right + marginX,
        box.bottom + marginY,
      );
      if (hitBox.contains(imageTap)) {
        final double dist = (imageTap - box.center).distance;
        if (dist < minDistance) {
          minDistance = dist;
          bestMatch = item;
        }
      }
    }

    if (bestMatch != null) {
      onToggleItem(bestMatch.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        final Size naturalSize =
            (imageSize != null && imageSize!.width > 0 && imageSize!.height > 0)
            ? imageSize!
            : Size(maxW, maxH);

        final FittedSizes fitted = applyBoxFit(
          BoxFit.contain,
          naturalSize,
          Size(maxW, maxH),
        );

        final Size displaySize = fitted.destination;
        final double scaleX = displaySize.width / naturalSize.width;
        final double scaleY = displaySize.height / naturalSize.height;

        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          clipBehavior: Clip.hardEdge,
          child: Center(
            child: SizedBox(
              width: displaySize.width,
              height: displaySize.height,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // 1. Base Image
                  Image.file(
                    File(imagePath),
                    width: displaySize.width,
                    height: displaySize.height,
                    fit: BoxFit.fill,
                  ),

                  // 2. Custom Painter with Bounding Boxes
                  CustomPaint(
                    size: displaySize,
                    painter: _OcrBoxesPainter(
                      items: items,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      isDark: isDark,
                    ),
                  ),

                  // 3. Tap Detector
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (TapUpDetails details) {
                      _handleTap(details.localPosition, scaleX, scaleY);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OcrBoxesPainter extends CustomPainter {
  final List<OcrRecognizedItem> items;
  final double scaleX;
  final double scaleY;
  final bool isDark;

  const _OcrBoxesPainter({
    required this.items,
    required this.scaleX,
    required this.scaleY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final OcrRecognizedItem item in items) {
      final Rect? originalBox = item.boundingBox;
      if (originalBox == null) continue;

      final Rect scaledBox = Rect.fromLTRB(
        originalBox.left * scaleX,
        originalBox.top * scaleY,
        originalBox.right * scaleX,
        originalBox.bottom * scaleY,
      );

      final RRect rrect = RRect.fromRectAndRadius(
        scaledBox,
        const Radius.circular(5.0),
      );

      if (item.isSelected) {
        // --- SELECTED STATE: Mint Glass Highlight ---
        final Paint fillPaint = Paint()
          ..color = AppColors.primaryMint.withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, fillPaint);

        final Paint borderPaint = Paint()
          ..color = AppColors.primaryMint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawRRect(rrect, borderPaint);

        // Checkmark circle badge at top-left
        final Offset badgeCenter = Offset(
          scaledBox.left + min(9.0, scaledBox.width / 2),
          scaledBox.top + min(9.0, scaledBox.height / 2),
        );

        final Paint badgeBg = Paint()
          ..color = AppColors.primaryMint
          ..style = PaintingStyle.fill;
        canvas.drawCircle(badgeCenter, 7.5, badgeBg);

        final TextPainter checkPainter = TextPainter(
          text: const TextSpan(
            text: '✓',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        checkPainter.paint(
          canvas,
          badgeCenter - Offset(checkPainter.width / 2, checkPainter.height / 2),
        );
      } else {
        // --- DESELECTED STATE: Dimmed translucent gray ---
        final Paint fillPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, fillPaint);

        final Paint borderPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawRRect(rrect, borderPaint);

        // Dash circle badge at top-left
        final Offset badgeCenter = Offset(
          scaledBox.left + min(9.0, scaledBox.width / 2),
          scaledBox.top + min(9.0, scaledBox.height / 2),
        );

        final Paint badgeBg = Paint()
          ..color = Colors.black.withValues(alpha: 0.65)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(badgeCenter, 7.5, badgeBg);

        final TextPainter dashPainter = TextPainter(
          text: const TextSpan(
            text: '—',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        dashPainter.paint(
          canvas,
          badgeCenter - Offset(dashPainter.width / 2, dashPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OcrBoxesPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.isDark != isDark;
  }
}
