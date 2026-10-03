import 'dart:typed_data';

import '../models/light_direction.dart';
import '../models/motor_state.dart';
import '../models/robot_telemetry.dart';
import 'exceptions.dart';

class TheoJansenDataParser {
  static const int payloadSize = 12;
  static const int supportedProtocolVersion = 2;

  RobotTelemetry decodeTelemetryPayload(Uint8List rawPayload, String tagUid) {
    if (rawPayload.length != payloadSize) {
      throw CorruptedPayloadException(
        'Longitud de trama inválida. Se requieren exactamente 12 bytes; recibido: ${rawPayload.length}',
      );
    }

    final receivedChecksum = rawPayload[11];
    if (!verifyCrc8(rawPayload, receivedChecksum)) {
      throw const CorruptedPayloadException(
        'Checksum CRC-8 inválido. Datos corruptos.',
      );
    }

    final header = rawPayload[0];
    final version = (header >> 6) & 0x03;
    final motorCode = (header >> 4) & 0x03;
    final dirCode = header & 0x0F;

    if (version != supportedProtocolVersion) {
      throw UnsupportedProtocolVersionException(version);
    }

    final MotorState motorState;
    switch (motorCode) {
      case 0:
        motorState = MotorState.detenido;
      case 1:
        motorState = MotorState.adelante;
      case 2:
        motorState = MotorState.atras;
      default:
        throw InvalidTelemetryException(
          'Código de motor reservado/no soportado: $motorCode',
        );
    }

    final LightDirection direction;
    switch (dirCode) {
      case 0:
        direction = LightDirection.equilibrado;
      case 1:
        direction = LightDirection.norte;
      case 2:
        direction = LightDirection.sur;
      case 3:
        direction = LightDirection.este;
      case 4:
        direction = LightDirection.oeste;
      default:
        throw InvalidTelemetryException(
          'Código de dirección lumínica reservado/no soportado: $dirCode',
        );
    }

    final sequenceNumber = rawPayload[1];
    final ldrValues = <int>[
      rawPayload[2],
      rawPayload[3],
      rawPayload[4],
      rawPayload[5],
    ];
    final ldrAverage = computeAverage(ldrValues);

    final servoPitch = rawPayload[6];
    final servoYaw = rawPayload[7];
    if (servoPitch > 180 || servoYaw > 180) {
      throw InvalidTelemetryException(
        'Ángulo de servomotor fuera de rango: Pitch=$servoPitch°, Yaw=$servoYaw°',
      );
    }

    final voltageMilliVolts = (rawPayload[8] << 8) | rawPayload[9];
    final batteryValid = voltageMilliVolts > 0;
    if (batteryValid &&
        (voltageMilliVolts < 2500 || voltageMilliVolts > 5000)) {
      throw InvalidTelemetryException(
        'Voltaje fuera del rango admisible del hardware 1S: $voltageMilliVolts mV',
      );
    }

    final operatingVoltage =
        batteryValid ? voltageMilliVolts / 1000.0 : 0.0;
    final batteryPercent =
        batteryValid ? calculateBatteryPercent(voltageMilliVolts) : 0;

    return RobotTelemetry(
      version: version,
      sequenceNumber: sequenceNumber,
      ldrValues: ldrValues,
      ldrAverage: ldrAverage,
      primaryLightDirection: direction,
      servoPitchAngle: servoPitch,
      servoYawAngle: servoYaw,
      polarityReversalsCount: rawPayload[10],
      motorDirection: motorState,
      operatingVoltage: operatingVoltage,
      batteryLevelPercent: batteryPercent,
      batteryValid: batteryValid,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      tagUid: tagUid,
    );
  }

  bool verifyCrc8(Uint8List data, int receivedChecksum) {
    if (data.length < 11) return false;
    return computeCrc8(data, 11) == (receivedChecksum & 0xFF);
  }

  static int computeCrc8(Uint8List data, int length) {
    var crc = 0;
    for (var i = 0; i < length; i++) {
      crc ^= data[i] & 0xFF;
      for (var j = 0; j < 8; j++) {
        crc = (crc & 0x80) != 0
            ? ((crc << 1) ^ 0x07) & 0xFF
            : (crc << 1) & 0xFF;
      }
    }
    return crc & 0xFF;
  }

  int calculateBatteryPercent(int voltageMilliVolts) {
    const minMv = 3000;
    const maxMv = 4200;
    if (voltageMilliVolts >= maxMv) return 100;
    if (voltageMilliVolts <= minMv) return 0;
    return ((voltageMilliVolts - minMv) * 100) ~/ (maxMv - minMv);
  }

  double computeAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
