import 'dart:typed_data';

import '../models/light_direction.dart';
import '../models/motor_state.dart';
import '../models/robot_telemetry.dart';
import 'exceptions.dart';

/// Decodifica la trama binaria de 12 bytes del robot (Protocolo V2) y valida su integridad mediante CRC-8 y límites físicos.
class TheoJansenDataParser {
  static const int payloadSize = 12;

  RobotTelemetry decodeTelemetryPayload(Uint8List rawPayload, String tagUid) {
    // Validación estricta de longitud: exactamente 12 bytes
    if (rawPayload.length != payloadSize) {
      throw CorruptedPayloadException(
        'Longitud de trama inválida. Se requerían exactamente 12 bytes, recibido: ${rawPayload.length}',
      );
    }

    // 1. Verificación CRC-8 sobre los primeros 11 bytes (Bytes 0 a 10)
    final int receivedChecksum = rawPayload[11];
    if (!verifyCrc8(rawPayload, receivedChecksum)) {
      throw const CorruptedPayloadException(
        'Checksum CRC-8 inválido. Datos corruptos.',
      );
    }

    // 2. Byte 0: HeaderFlags
    final int header = rawPayload[0];
    final int version = (header >> 6) & 0x03;
    final int motorCode = (header >> 4) & 0x03;
    final int dirCode = header & 0x0F;

    final MotorState motorState;
    if (motorCode == 1) {
      motorState = MotorState.adelante;
    } else if (motorCode == 2) {
      motorState = MotorState.atras;
    } else {
      motorState = MotorState.detenido;
    }

    final LightDirection direction;
    switch (dirCode) {
      case 1: direction = LightDirection.norte; break;
      case 2: direction = LightDirection.sur; break;
      case 3: direction = LightDirection.este; break;
      case 4: direction = LightDirection.oeste; break;
      default: direction = LightDirection.equilibrado; break;
    }

    // 3. Byte 1: Secuencia de frescura
    final int sequenceNumber = rawPayload[1];

    // 4. Bytes 2 a 5: Sensores LDR (uint8)
    final int ldrNorte = rawPayload[2];
    final int ldrSur = rawPayload[3];
    final int ldrOeste = rawPayload[4];
    final int ldrEste = rawPayload[5];
    final List<int> ldrValues = [ldrNorte, ldrSur, ldrOeste, ldrEste];
    final double ldrAverage = computeAverage(ldrValues);

    // 5. Bytes 6 y 7: Servomotores Pitch y Yaw (0 a 180 deg)
    final int servoPitch = rawPayload[6];
    final int servoYaw = rawPayload[7];

    // 6. Bytes 8 y 9: Voltaje en milivoltios (uint16 Big-Endian)
    final int voltageMilliVolts = (rawPayload[8] << 8) | rawPayload[9];
    final bool batteryValid = (voltageMilliVolts > 0);
    final double operatingVoltage = batteryValid ? (voltageMilliVolts / 1000.0) : 0.0;
    final int batteryPercent = batteryValid ? calculateBatteryPercent(voltageMilliVolts) : 0;

    // 7. Byte 10: Inversiones acumuladas de marcha
    final int polarityReversals = rawPayload[10];

    // 8. Validación Semántica de Límites Físicos
    if (servoPitch > 180 || servoYaw > 180) {
      throw InvalidTelemetryException(
        'Ángulo de servomotor fuera de rango físico: Pitch=$servoPitch°, Yaw=$servoYaw°',
      );
    }
    if (batteryValid && (voltageMilliVolts < 2500 || voltageMilliVolts > 6000)) {
      throw InvalidTelemetryException(
        'Voltaje de batería fuera de límites tolerados: $voltageMilliVolts mV',
      );
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    return RobotTelemetry(
      version: version,
      sequenceNumber: sequenceNumber,
      ldrValues: ldrValues,
      ldrAverage: ldrAverage,
      primaryLightDirection: direction,
      servoPitchAngle: servoPitch,
      servoYawAngle: servoYaw,
      polarityReversalsCount: polarityReversals,
      motorDirection: motorState,
      operatingVoltage: operatingVoltage,
      batteryLevelPercent: batteryPercent,
      batteryValid: batteryValid,
      timestamp: timestamp,
      tagUid: tagUid,
    );
  }

  /// Calcula y verifica el polinomio de redundancia cíclica CRC-8 (polinomio 0x07)
  bool verifyCrc8(Uint8List data, int receivedChecksum) {
    int crc = 0x00;
    // Se procesan los primeros 11 bytes (0..10)
    for (int i = 0; i < 11; i++) {
      crc ^= (data[i] & 0xFF);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ 0x07) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
    }
    return (crc & 0xFF) == (receivedChecksum & 0xFF);
  }

  static int computeCrc8(Uint8List data, int length) {
    int crc = 0x00;
    for (int i = 0; i < length; i++) {
      crc ^= (data[i] & 0xFF);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ 0x07) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
    }
    return crc & 0xFF;
  }

  int calculateBatteryPercent(int voltageMilliVolts) {
    const int minMv = 3000;
    const int maxMv = 4200;
    if (voltageMilliVolts >= maxMv) return 100;
    if (voltageMilliVolts <= minMv) return 0;
    return (((voltageMilliVolts - minMv) * 100) ~/ (maxMv - minMv));
  }

  double computeAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    final int sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }
}
