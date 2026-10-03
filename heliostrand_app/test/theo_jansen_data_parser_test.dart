import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/models/motor_state.dart';
import 'package:heliostrand_app/models/robot_telemetry.dart';
import 'package:heliostrand_app/parser/exceptions.dart';
import 'package:heliostrand_app/parser/theo_jansen_data_parser.dart';

void main() {
  group('TheoJansenDataParser Dart Unit Tests', () {
    test('Debe parsear correctamente una trama binaria válida de 12 bytes', () {
      final parser = TheoJansenDataParser();

      // Trama simulada idéntica a la prueba de Java:
      // LDRs: Norte=200, Sur=50, Oeste=100, Este=80
      // Servos: Pitch=90°, Yaw=45°
      // PolarityReversals: 4 (0x00, 0x04)
      // Voltage: 5050 mV = 5.05V (0x13, 0xBA)
      // Battery: 85%
      final mockPayload = Uint8List.fromList([
        200, 50, 100, 80,
        90, 45,
        0x00, 0x04,
        0x13, 0xBA,
        85,
        0x00,
      ]);

      // Calculamos CRC-8 sobre los primeros 11 bytes
      final crc = TheoJansenDataParser.computeCrc8(mockPayload, 11);
      mockPayload[11] = crc;

      final RobotTelemetry telemetry = parser.decodeTelemetryPayload(
        mockPayload,
        'TAG-NFC-TEST-1234',
      );

      expect(telemetry.tagUid, equals('TAG-NFC-TEST-1234'));
      expect(telemetry.servoPitchAngle, equals(90));
      expect(telemetry.servoYawAngle, equals(45));
      expect(telemetry.operatingVoltage, closeTo(5.05, 0.01));
      expect(telemetry.batteryLevelPercent, equals(85));
      expect(telemetry.primaryLightDirection, equals(LightDirection.norte));
      expect(telemetry.motorDirection, equals(MotorState.adelante));
      expect(telemetry.polarityReversalsCount, equals(4));
    });

    test('Debe lanzar CorruptedPayloadException si el CRC es inválido', () {
      final parser = TheoJansenDataParser();
      final corruptedPayload = Uint8List.fromList([
        100, 100, 100, 100,
        90, 90,
        0x00, 0x02,
        0x13, 0x88,
        99,
        0xFF, // Checksum erróneo
      ]);

      expect(
        () => parser.decodeTelemetryPayload(corruptedPayload, 'TAG-FAIL'),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });

    test('Debe lanzar CorruptedPayloadException si la trama tiene menos de 12 bytes', () {
      final parser = TheoJansenDataParser();
      final shortPayload = Uint8List.fromList([1, 2, 3]);

      expect(
        () => parser.decodeTelemetryPayload(shortPayload, 'TAG-SHORT'),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });
  });
}
