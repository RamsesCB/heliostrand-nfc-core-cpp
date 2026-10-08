import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/main.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/ui/widgets/ldr_chart_card.dart';

void main() {
  testWidgets('Carga el dashboard de Theo Jansen Solar Tracker', (WidgetTester tester) async {
    await tester.pumpWidget(const HeliostrandApp());

    // Verificar que el título de la app se renderiza
    expect(find.text('Theo Jansen Solar Tracker'), findsOneWidget);
    // Verificar que los paneles principales están presentes
    expect(find.text('Sensores LDR (Luz)'), findsOneWidget);
    expect(find.text('Servomotores (Seguimiento)'), findsOneWidget);
  });

  testWidgets('LdrChartCard no genera overflow en pantallas móviles (360dp)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (final dir in LightDirection.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: LdrChartCard(
                ldrValues: const [100, 50, 80, 20],
                dominantDirection: dir,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sensores LDR (Luz)'), findsOneWidget);
    }
  });
}

