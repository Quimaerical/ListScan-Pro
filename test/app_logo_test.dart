import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shopliist_pro/core/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders horizontal brand with SVG icon, List, Scan, and PRO badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo.horizontal(),
        ),
      ),
    );

    // Verify SVG icon widget
    expect(find.byType(SvgPicture), findsOneWidget);

    // Verify Brand text
    expect(find.textContaining('List'), findsOneWidget);
    expect(find.textContaining('Scan'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
  });

  testWidgets('AppLogo.iconOnly renders only the SVG icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo.iconOnly(size: 48),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.textContaining('List'), findsNothing);
    expect(find.text('PRO'), findsNothing);
  });
}
