package com.theojansen.nfc.parser;

import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;

/**
 * Decodifica la trama binaria de 12 bytes del robot y valida su integridad mediante CRC-8.
 */
public class TheoJansenDataParser {

    public RobotTelemetry decodeTelemetryPayload(byte[] rawPayload, String tagUid) throws CorruptedPayloadException {
        if (rawPayload == null || rawPayload.length < 12) {
            throw new CorruptedPayloadException("Trama binaria incompleta o nula. Se requerían 12 bytes.");
        }

        // 1. Verificación CRC-8
        byte receivedChecksum = rawPayload[11];
        if (!verifyCrc8(rawPayload, receivedChecksum)) {
            throw new CorruptedPayloadException("Checksum CRC-8 inválido. Datos corruptos.");
        }

        // 2. Extracción de sensores LDR (uint8)
        int ldrNorte = rawPayload[0] & 0xFF;
        int ldrSur = rawPayload[1] & 0xFF;
        int ldrOeste = rawPayload[2] & 0xFF;
        int ldrEste = rawPayload[3] & 0xFF;
        int[] ldrValues = new int[]{ldrNorte, ldrSur, ldrOeste, ldrEste};

        double ldrAverage = computeAverage(ldrValues);
        LightDirection direction = determineLightDirection(ldrNorte, ldrSur, ldrOeste, ldrEste);

        // 3. Servomotores Pitch y Yaw (uint8)
        int servoPitch = rawPayload[4] & 0xFF;
        int servoYaw = rawPayload[5] & 0xFF;

        // 4. Inversiones de polaridad (uint16 Big-Endian)
        int polarityReversals = ((rawPayload[6] & 0xFF) << 8) | (rawPayload[7] & 0xFF);

        // 5. Voltaje de operación (uint16 Big-Endian en mV -> convertido a Voltios)
        int voltageMilliVolts = ((rawPayload[8] & 0xFF) << 8) | (rawPayload[9] & 0xFF);
        double operatingVoltage = voltageMilliVolts / 1000.0;

        // 6. Nivel de batería (uint8)
        int batteryLevel = rawPayload[10] & 0xFF;

        // 7. Determinar estado de marcha del motor según inversión/movimiento
        MotorState motorState = (polarityReversals % 2 == 0) ? MotorState.ADELANTE : MotorState.ATRAS;

        long timestamp = System.currentTimeMillis();

        return new RobotTelemetry(
                ldrValues,
                ldrAverage,
                direction,
                servoPitch,
                servoYaw,
                polarityReversals,
                motorState,
                operatingVoltage,
                batteryLevel,
                timestamp,
                tagUid
        );
    }

    private boolean verifyCrc8(byte[] data, byte receivedChecksum) {
        int crc = 0x00;
        // Se procesan los primeros 11 bytes (excluyendo el byte de checksum)
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

    private double computeAverage(int... values) {
        if (values.length == 0) return 0.0;
        int sum = 0;
        for (int v : values) {
            sum += v;
        }
        return (double) sum / values.length;
    }

    private LightDirection determineLightDirection(int norte, int sur, int oeste, int este) {
        int threshold = 15; // Umbral de tolerancia de equilibrio
        int max = Math.max(Math.max(norte, sur), Math.max(oeste, este));
        int min = Math.min(Math.min(norte, sur), Math.min(oeste, este));

        if ((max - min) <= threshold) {
            return LightDirection.EQUILIBRADO;
        }
        if (max == norte) return LightDirection.NORTE;
        if (max == sur) return LightDirection.SUR;
        if (max == oeste) return LightDirection.OESTE;
        return LightDirection.ESTE;
    }
}
