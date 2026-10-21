import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/ui/actions.dart';
import 'package:heliostrand_app/main.dart';
import 'package:heliostrand_app/ui/widgets/history_card.dart';
import 'package:heliostrand_app/models/robot_telemetry.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/models/motor_state.dart';

void main() {
  testWidgets('action failure shows a message without an unhandled exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runUiAction(
                context,
                () async => throw StateError('offline'),
                'No se pudo exportar el reporte.',
              ),
              child: const Text('Exportar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo exportar el reporte.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history displays the latest five entries first', (tester) async {
    final history = List.generate(
      6,
      (index) => RobotTelemetry(
        ldrValues: const [0, 0, 0, 0],
        ldrAverage: 0,
        primaryLightDirection: LightDirection.equilibrado,
        servoPitchAngle: 100 - index,
        servoYawAngle: 90,
        polarityReversalsCount: 0,
        motorDirection: MotorState.detenido,
        operatingVoltage: 0,
        batteryLevelPercent: 0,
        timestamp: index,
        tagUid: 'test',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryCard(history: history)),
      ),
    );
    expect(find.text('P 100° · Y 90°'), findsOneWidget);
    expect(find.text('P 95° · Y 90°'), findsNothing);
  });

  testWidgets(
    'switching from simulation stops its timer and permits restarting',
    (tester) async {
      const channel = MethodChannel('flutter_nfc_kit/method');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(const HeliostrandApp());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modo Simulación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar Simulación'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Usar NFC Real'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar Escaneo NFC'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
