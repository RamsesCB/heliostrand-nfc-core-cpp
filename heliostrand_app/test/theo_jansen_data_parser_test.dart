import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/models/motor_state.dart';
import 'package:heliostrand_app/parser/exceptions.dart';
import 'package:heliostrand_app/parser/theo_jansen_data_parser.dart';

Uint8List hexToBytes(String hex) {
  if (hex.length.isOdd) throw ArgumentError('hex impar');
  return Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}

Map<String, dynamic> loadVectorDocument() {
  final candidates = <File>[
    File('../test/vectors/golden_telemetry_vectors.json'),
    File('test/vectors/golden_telemetry_vectors.json'),
  ];
  final file = candidates.firstWhere(
    (candidate) => candidate.existsSync(),
    orElse: () => throw StateError(
      'No se encontró test/vectors/golden_telemetry_vectors.json',
    ),
  );
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

MotorState expectedMotor(String value) => switch (value) {
      'STOPPED' => MotorState.detenido,
      'FORWARD' => MotorState.adelante,
      'REVERSE' => MotorState.atras,
      _ => throw ArgumentError(value),
    };

LightDirection expectedDirection(String value) => switch (value) {
      'BALANCED' => LightDirection.equilibrado,
      'NORTH' => LightDirection.norte,
      'SOUTH' => LightDirection.sur,
      'EAST' => LightDirection.este,
      'WEST' => LightDirection.oeste,
      _ => throw ArgumentError(value),
    };

void repairCrc(Uint8List payload) {
  payload[11] = TheoJansenDataParser.computeCrc8(payload, 11);
}

Uint8List validBasePayload() =>
    hexToBytes('9301647882915A5C0F0A026A');

void main() {
  group('Protocol V2 shared contract', () {
    test('decodes every valid vector from the shared JSON file', () {
      final parser = TheoJansenDataParser();
      final vectors =
          loadVectorDocument()['vectors']! as List<dynamic>;
      var checked = 0;

      for (final raw in vectors) {
        final vector = raw as Map<String, dynamic>;
        final expected =
            vector['expected']! as Map<String, dynamic>;
        if (expected['valid'] != true) continue;

        final telemetry = parser.decodeTelemetryPayload(
          hexToBytes(vector['hex']! as String),
          'UID-${vector['id']}',
        );

        expect(telemetry.version, expected['version']);
        expect(telemetry.sequenceNumber, expected['sequence_number']);
        expect(
          telemetry.motorDirection,
          expectedMotor(expected['motor_state']! as String),
        );
        expect(
          telemetry.primaryLightDirection,
          expectedDirection(expected['light_direction']! as String),
        );
        expect(telemetry.servoPitchAngle, expected['servo_pitch']);
        expect(telemetry.servoYawAngle, expected['servo_yaw']);
        expect(
          telemetry.operatingVoltage,
          closeTo((expected['battery_millivolts']! as num) / 1000.0, 0.001),
        );
        expect(telemetry.batteryValid, expected['battery_valid']);
        checked++;
      }

      expect(checked, 4);
    });

    test('rejects the corrupted CRC vector from shared JSON', () {
      final parser = TheoJansenDataParser();
      final vectors =
          loadVectorDocument()['vectors']! as List<dynamic>;
      final corrupted = vectors
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (vector) =>
                (vector['expected'] as Map<String, dynamic>)['error_type'] ==
                'CORRUPTED_CRC',
          );

      expect(
        () => parser.decodeTelemetryPayload(
          hexToBytes(corrupted['hex']! as String),
          'CRC-BAD',
        ),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });

    test('requires exactly 12 bytes', () {
      final parser = TheoJansenDataParser();
      expect(
        () => parser.decodeTelemetryPayload(Uint8List(11), 'SHORT'),
        throwsA(isA<CorruptedPayloadException>()),
      );
      expect(
        () => parser.decodeTelemetryPayload(Uint8List(13), 'LONG'),
        throwsA(isA<CorruptedPayloadException>()),
      );
    });

    test('rejects unsupported protocol versions', () {
      final parser = TheoJansenDataParser();
      final payload = validBasePayload();
      payload[0] = (1 << 6) | (1 << 4) | 3;
      repairCrc(payload);

      expect(
        () => parser.decodeTelemetryPayload(payload, 'V1'),
        throwsA(isA<UnsupportedProtocolVersionException>()),
      );
    });

    test('rejects reserved motor and direction codes', () {
      final parser = TheoJansenDataParser();

      final motorReserved = validBasePayload();
      motorReserved[0] = (2 << 6) | (3 << 4) | 3;
      repairCrc(motorReserved);
      expect(
        () => parser.decodeTelemetryPayload(motorReserved, 'MOTOR'),
        throwsA(isA<InvalidTelemetryException>()),
      );

      final directionReserved = validBasePayload();
      directionReserved[0] = (2 << 6) | (1 << 4) | 5;
      repairCrc(directionReserved);
      expect(
        () => parser.decodeTelemetryPayload(directionReserved, 'DIR'),
        throwsA(isA<InvalidTelemetryException>()),
      );
    });

    test('rejects physical range violations', () {
      final parser = TheoJansenDataParser();

      final angle = validBasePayload();
      angle[6] = 200;
      repairCrc(angle);
      expect(
        () => parser.decodeTelemetryPayload(angle, 'ANGLE'),
        throwsA(isA<InvalidTelemetryException>()),
      );

      final voltage = validBasePayload();
      voltage[8] = 0x17;
      voltage[9] = 0x70; // 6000 mV
      repairCrc(voltage);
      expect(
        () => parser.decodeTelemetryPayload(voltage, 'VOLT'),
        throwsA(isA<InvalidTelemetryException>()),
      );
    });
  });
}
