import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/main.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/ui/widgets/ldr_chart_card.dart';

void main() {
  testWidgets('Carga el dashboard minimalista de Theo Jansen Solar Tracker', (WidgetTester tester) async {
    await tester.pumpWidget(const HeliostrandApp());
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('Theo Jansen'), findsAtLeastNWidgets(1));
    expect(find.text('Solar Tracker'), findsOneWidget);

    // 2. Status Card
    expect(find.text('Listo para escanear'), findsOneWidget);

    // 3. LDR Card
    expect(find.text('Sensores LDR (Luz)'), findsOneWidget);

    // 4. Servos Card
    expect(find.text('Pitch (Vertical)'), findsOneWidget);
    expect(find.text('Yaw (Horizontal)'), findsOneWidget);

    // 5. Metrics Grid
    expect(find.text('Potencia'), findsOneWidget);

    // 6. Historial
    expect(find.text('Historial'), findsOneWidget);

    // 7. Sticky CTA
    expect(find.text('Iniciar Escaneo NFC'), findsOneWidget);
  });

  testWidgets('LdrChartCard no genera overflow en pantallas móviles (360dp) incluso con valores máximos y accesibilidad', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (final dir in LightDirection.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: LdrChartCard(
                  ldrValues: const [255, 255, 255, 255],
                  dominantDirection: dir,
                ),
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
