import 'dart:math' as math;
import 'dart:typed_data';

import '../models/light_direction.dart';
import '../models/motor_state.dart';
import '../models/robot_telemetry.dart';
import 'exceptions.dart';

/// Decodifica la trama binaria de 12 bytes del robot y valida su integridad mediante CRC-8.
class TheoJansenDataParser {
  static const int payloadSize = 12;

  RobotTelemetry decodeTelemetryPayload(Uint8List rawPayload, String tagUid) {
    if (rawPayload.length < payloadSize) {
      throw const CorruptedPayloadException(
        'Trama binaria incompleta o nula. Se requerían 12 bytes.',
      );
    }

    // 1. Verificación CRC-8
    final int receivedChecksum = rawPayload[11];
    if (!verifyCrc8(rawPayload, receivedChecksum)) {
      throw const CorruptedPayloadException(
        'Checksum CRC-8 inválido. Datos corruptos.',
      );
    }

    // 2. Extracción de sensores LDR (uint8)
    final int ldrNorte = rawPayload[0];
    final int ldrSur = rawPayload[1];
    final int ldrOeste = rawPayload[2];
    final int ldrEste = rawPayload[3];
    final List<int> ldrValues = [ldrNorte, ldrSur, ldrOeste, ldrEste];

    final double ldrAverage = computeAverage(ldrValues);
    final LightDirection direction = determineLightDirection(
      ldrNorte,
      ldrSur,
      ldrOeste,
      ldrEste,
    );

    // 3. Servomotores Pitch y Yaw (uint8)
    final int servoPitch = rawPayload[4];
    final int servoYaw = rawPayload[5];

    // 4. Inversiones de polaridad (uint16 Big-Endian)
    final int polarityReversals = (rawPayload[6] << 8) | rawPayload[7];

    // 5. Voltaje de operación (uint16 Big-Endian en mV -> convertido a Voltios)
    final int voltageMilliVolts = (rawPayload[8] << 8) | rawPayload[9];
    final double operatingVoltage = voltageMilliVolts / 1000.0;

    // 6. Nivel de batería (uint8)
    final int batteryLevel = rawPayload[10];

    // 7. Determinar estado de marcha del motor según paridad de inversiones
    final MotorState motorState =
        (polarityReversals % 2 == 0) ? MotorState.adelante : MotorState.atras;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    return RobotTelemetry(
      ldrValues: ldrValues,
      ldrAverage: ldrAverage,
      primaryLightDirection: direction,
      servoPitchAngle: servoPitch,
      servoYawAngle: servoYaw,
      polarityReversalsCount: polarityReversals,
      motorDirection: motorState,
      operatingVoltage: operatingVoltage,
      batteryLevelPercent: batteryLevel,
      timestamp: timestamp,
      tagUid: tagUid,
    );
  }

  /// Calcula y verifica el polinomio de redundancia cíclica CRC-8 (polinomio 0x07)
  bool verifyCrc8(Uint8List data, int receivedChecksum) {
    int crc = 0x00;
    // Se procesan los primeros 11 bytes (excluyendo el byte 11 de checksum)
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

  /// Función estática para calcular CRC-8 de cualquier búfer
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

  double computeAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    final int sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  LightDirection determineLightDirection(
    int norte,
    int sur,
    int oeste,
    int este,
  ) {
    const int threshold = 15; // Umbral de tolerancia de equilibrio
    final int maxVal = math.max(math.max(norte, sur), math.max(oeste, este));
    final int minVal = math.min(math.min(norte, sur), math.min(oeste, este));

    if ((maxVal - minVal) <= threshold) {
      return LightDirection.equilibrado;
    }
    if (maxVal == norte) return LightDirection.norte;
    if (maxVal == sur) return LightDirection.sur;
    if (maxVal == oeste) return LightDirection.oeste;
    return LightDirection.este;
  }
}
