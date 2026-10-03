import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/models/motor_state.dart';
import 'package:heliostrand_app/models/robot_telemetry.dart';
import 'package:heliostrand_app/parser/exceptions.dart';
import 'package:heliostrand_app/parser/theo_jansen_data_parser.dart';

Uint8List hexToBytes(String hex) {
  final clean = hex.trim();
  final bytes = Uint8List(clean.length ~/ 2);
  for (int i = 0; i < clean.length; i += 2) {
    bytes[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

void main() {
  group('TheoJansenDataParser Protocol V2 Tests', () {
    test('Golden Vector 1: Condición nominal soleada con marcha adelante hacia el este', () {
      final parser = TheoJansenDataParser();
      final payload = hexToBytes('9301647882915A5C0F0A026A');

      final RobotTelemetry t = parser.decodeTelemetryPayload(payload, 'UID-GOLDEN-01');

      expect(t.version, equals(2));
      expect(t.sequenceNumber, equals(1));
      expect(t.motorDirection, equals(MotorState.adelante));
      expect(t.primaryLightDirection, equals(LightDirection.este));
      expect(t.servoPitchAngle, equals(90));
      expect(t.servoYawAngle, equals(92));
      expect(t.operatingVoltage, closeTo(3.85, 0.001));
      expect(t.batteryValid, isTrue);
      expect(t.polarityReversalsCount, equals(2));
    });

    test('Golden Vector 2: Robot detenido bajo iluminación solar equilibrada', () {
      final parser = TheoJansenDataParser();
      final payload = hexToBytes('8002969696965A5A1004009F');

      final RobotTelemetry t = parser.decodeTelemetryPayload(payload, 'UID-GOLDEN-02');

      expect(t.version, equals(2));
      expect(t.sequenceNumber, equals(2));
      expect(t.motorDirection, equals(MotorState.detenido));
      expect(t.primaryLightDirection, equals(LightDirection.equilibrado));
      expect(t.servoPitchAngle, equals(90));
      expect(t.servoYawAngle, equals(90));
      expect(t.operatingVoltage, closeTo(4.10, 0.001));
      expect(t.batteryValid, isTrue);
      expect(t.polarityReversalsCount, equals(0));
    });

    test('Golden Vector 3: Marcha atrás hacia el sur con batería baja (3300 mV)', () {
      final parser = TheoJansenDataParser();
      final payload = hexToBytes('A20A32DC50462D870CE4053A');

      final RobotTelemetry t = parser.decodeTelemetryPayload(payload, 'UID-GOLDEN-03');

      expect(t.version, equals(2));
      expect(t.sequenceNumber, equals(10));
      expect(t.motorDirection, equals(MotorState.atras));
      expect(t.primaryLightDirection, equals(LightDirection.sur));
      expect(t.servoPitchAngle, equals(45));
      expect(t.servoYawAngle, equals(135));
      expect(t.operatingVoltage, closeTo(3.30, 0.001));
      expect(t.batteryValid, isTrue);
      expect(t.polarityReversalsCount, equals(5));
    });

    test('Golden Vector 4: Sensor de batería desconectado (0 mV, sensor inválido)', () {
      final parser = TheoJansenDataParser();
      final payload = hexToBytes('8014646464645A5A000001AA');

      final RobotTelemetry t = parser.decodeTelemetryPayload(payload, 'UID-GOLDEN-04');

      expect(t.sequenceNumber, equals(20));
      expect(t.operatingVoltage, equals(0.0));
      expect(t.batteryValid, isFalse);
      expect(t.batteryLevelPercent, equals(0));
    });

    test('Debe rechazar estrictamente tramas con longitud distinta de 12 bytes', () {
      final parser = TheoJansenDataParser();
      final shortPayload = Uint8List(11);
      final longPayload = Uint8List(13);

      expect(
        () => parser.decodeTelemetryPayload(shortPayload, 'SHORT'),
        throwsA(isA<CorruptedPayloadException>()),
      );
      expect(
        () => parser.decodeTelemetryPayload(longPayload, 'LONG'),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });

    test('Debe lanzar CorruptedPayloadException ante CRC-8 corrupto', () {
      final parser = TheoJansenDataParser();
      final corrupted = hexToBytes('9301647882915A5C0F0A02FF');

      expect(
        () => parser.decodeTelemetryPayload(corrupted, 'CORRUPT'),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });

    test('Debe lanzar InvalidTelemetryException ante valores fuera de límites físicos', () {
      final parser = TheoJansenDataParser();
      // Pitch = 200° (> 180°), CRC válido
      final invalidAngle = Uint8List.fromList([
        0x80, 0x01, 100, 100, 100, 100,
        200, 90, 0x0F, 0x00, 0x00, 0x00
      ]);
      final crc = TheoJansenDataParser.computeCrc8(invalidAngle, 11);
      invalidAngle[11] = crc;

      expect(
        () => parser.decodeTelemetryPayload(invalidAngle, 'PHYSICAL-FAIL'),
        throwsA(isA<InvalidTelemetryException>()),
      );
    });
  });
}
