package com.theojansen.nfc.parser;

import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;

/**
 * Decodifica la trama binaria de 12 bytes del robot (Protocolo V2) y valida su integridad mediante CRC-8 y límites físicos.
 */
public class TheoJansenDataParser {

    public static final int EXPECTED_PAYLOAD_SIZE = 12;

    public RobotTelemetry decodeTelemetryPayload(byte[] rawPayload, String tagUid) 
            throws CorruptedPayloadException, InvalidTelemetryException {
        // Validación estricta de longitud: exactamente 12 bytes
        if (rawPayload == null || rawPayload.length != EXPECTED_PAYLOAD_SIZE) {
            throw new CorruptedPayloadException("Longitud de trama inválida. Se requerían exactamente 12 bytes, recibido: "
                    + (rawPayload == null ? 0 : rawPayload.length));
        }

        // 1. Verificación CRC-8 sobre los primeros 11 bytes (Bytes 0 a 10)
        byte receivedChecksum = rawPayload[11];
        if (!verifyCrc8(rawPayload, receivedChecksum)) {
            throw new CorruptedPayloadException("Checksum CRC-8 inválido. Datos corruptos.");
        }

        // 2. Byte 0: HeaderFlags
        int header = rawPayload[0] & 0xFF;
        int version = (header >> 6) & 0x03;
        int motorCode = (header >> 4) & 0x03;
        int dirCode = header & 0x0F;

        MotorState motorState;
        if (motorCode == 1) {
            motorState = MotorState.ADELANTE;
        } else if (motorCode == 2) {
            motorState = MotorState.ATRAS;
        } else {
            motorState = MotorState.DETENIDO;
        }

        LightDirection direction;
        switch (dirCode) {
            case 1: direction = LightDirection.NORTE; break;
            case 2: direction = LightDirection.SUR; break;
            case 3: direction = LightDirection.ESTE; break;
            case 4: direction = LightDirection.OESTE; break;
            default: direction = LightDirection.EQUILIBRADO; break;
        }

        // 3. Byte 1: Secuencia de frescura
        int sequenceNumber = rawPayload[1] & 0xFF;

        // 4. Bytes 2 a 5: Sensores LDR (uint8)
        int ldrNorte = rawPayload[2] & 0xFF;
        int ldrSur = rawPayload[3] & 0xFF;
        int ldrOeste = rawPayload[4] & 0xFF;
        int ldrEste = rawPayload[5] & 0xFF;
        int[] ldrValues = new int[]{ldrNorte, ldrSur, ldrOeste, ldrEste};
        double ldrAverage = computeAverage(ldrValues);

        // 5. Bytes 6 y 7: Servomotores Pitch y Yaw (0 a 180 deg)
        int servoPitch = rawPayload[6] & 0xFF;
        int servoYaw = rawPayload[7] & 0xFF;

        // 6. Bytes 8 y 9: Voltaje en milivoltios (uint16 Big-Endian)
        int voltageMilliVolts = ((rawPayload[8] & 0xFF) << 8) | (rawPayload[9] & 0xFF);
        boolean batteryValid = (voltageMilliVolts > 0);
        double operatingVoltage = batteryValid ? (voltageMilliVolts / 1000.0) : 0.0;
        int batteryPercent = batteryValid ? calculateBatteryPercent(voltageMilliVolts) : 0;

        // 7. Byte 10: Inversiones acumuladas de marcha
        int polarityReversals = rawPayload[10] & 0xFF;

        // 8. Validación Semántica de Límites Físicos
        if (servoPitch > 180 || servoYaw > 180) {
            throw new InvalidTelemetryException("Ángulo de servomotor fuera de rango físico: Pitch=" 
                    + servoPitch + "°, Yaw=" + servoYaw + "°");
        }
        if (batteryValid && (voltageMilliVolts < 2500 || voltageMilliVolts > 6000)) {
            throw new InvalidTelemetryException("Voltaje de batería fuera de límites tolerados: " 
                    + voltageMilliVolts + " mV");
        }

        long timestamp = System.currentTimeMillis();

        return new RobotTelemetry(
                version,
                sequenceNumber,
                ldrValues,
                ldrAverage,
                direction,
                servoPitch,
                servoYaw,
                polarityReversals,
                motorState,
                operatingVoltage,
                batteryPercent,
                batteryValid,
                timestamp,
                tagUid
        );
    }

    public boolean verifyCrc8(byte[] data, byte receivedChecksum) {
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

    private int calculateBatteryPercent(int voltageMilliVolts) {
        int minMv = 3000;
        int maxMv = 4200;
        if (voltageMilliVolts >= maxMv) return 100;
        if (voltageMilliVolts <= minMv) return 0;
        return (int)(((long)(voltageMilliVolts - minMv) * 100L) / (maxMv - minMv));
    }

    private double computeAverage(int... values) {
        if (values.length == 0) return 0.0;
        int sum = 0;
        for (int v : values) {
            sum += v;
        }
        return (double) sum / values.length;
    }
}
