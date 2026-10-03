package com.theojansen.nfc.parser;

import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;

public class TheoJansenDataParser {
    public static final int EXPECTED_PAYLOAD_SIZE = 12;
    public static final int SUPPORTED_PROTOCOL_VERSION = 2;

    public RobotTelemetry decodeTelemetryPayload(byte[] rawPayload, String tagUid)
            throws CorruptedPayloadException, InvalidTelemetryException {
        if (rawPayload == null || rawPayload.length != EXPECTED_PAYLOAD_SIZE) {
            throw new CorruptedPayloadException(
                    "Longitud de trama inválida. Se requieren exactamente 12 bytes; recibido: "
                            + (rawPayload == null ? 0 : rawPayload.length));
        }

        final byte receivedChecksum = rawPayload[11];
        if (!verifyCrc8(rawPayload, receivedChecksum)) {
            throw new CorruptedPayloadException("Checksum CRC-8 inválido. Datos corruptos.");
        }

        final int header = rawPayload[0] & 0xFF;
        final int version = (header >> 6) & 0x03;
        final int motorCode = (header >> 4) & 0x03;
        final int dirCode = header & 0x0F;

        if (version != SUPPORTED_PROTOCOL_VERSION) {
            throw new UnsupportedProtocolVersionException(version);
        }

        final MotorState motorState = switch (motorCode) {
            case 0 -> MotorState.DETENIDO;
            case 1 -> MotorState.ADELANTE;
            case 2 -> MotorState.ATRAS;
            default -> throw new InvalidTelemetryException(
                    "Código de estado de motor reservado/no soportado: " + motorCode);
        };

        final LightDirection direction = switch (dirCode) {
            case 0 -> LightDirection.EQUILIBRADO;
            case 1 -> LightDirection.NORTE;
            case 2 -> LightDirection.SUR;
            case 3 -> LightDirection.ESTE;
            case 4 -> LightDirection.OESTE;
            default -> throw new InvalidTelemetryException(
                    "Código de dirección lumínica reservado/no soportado: " + dirCode);
        };

        final int sequenceNumber = rawPayload[1] & 0xFF;

        final int[] ldrValues = new int[]{
                rawPayload[2] & 0xFF,
                rawPayload[3] & 0xFF,
                rawPayload[4] & 0xFF,
                rawPayload[5] & 0xFF
        };
        final double ldrAverage = computeAverage(ldrValues);

        final int servoPitch = rawPayload[6] & 0xFF;
        final int servoYaw = rawPayload[7] & 0xFF;
        if (servoPitch > 180 || servoYaw > 180) {
            throw new InvalidTelemetryException(
                    "Ángulo de servomotor fuera de rango: Pitch="
                            + servoPitch + "°, Yaw=" + servoYaw + "°");
        }

        final int voltageMilliVolts =
                ((rawPayload[8] & 0xFF) << 8) | (rawPayload[9] & 0xFF);
        final boolean batteryValid = voltageMilliVolts > 0;
        if (batteryValid && (voltageMilliVolts < 2500 || voltageMilliVolts > 5000)) {
            throw new InvalidTelemetryException(
                    "Voltaje de batería fuera del rango admisible del hardware 1S: "
                            + voltageMilliVolts + " mV");
        }

        final double operatingVoltage =
                batteryValid ? voltageMilliVolts / 1000.0 : 0.0;
        final int batteryPercent =
                batteryValid ? calculateBatteryPercent(voltageMilliVolts) : 0;
        final int polarityReversals = rawPayload[10] & 0xFF;

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
                System.currentTimeMillis(),
                tagUid
        );
    }

    public boolean verifyCrc8(byte[] data, byte receivedChecksum) {
        if (data == null || data.length < 11) return false;
        return computeCrc8(data, 11) == (receivedChecksum & 0xFF);
    }

    public static int computeCrc8(byte[] data, int length) {
        int crc = 0x00;
        for (int i = 0; i < length; i++) {
            crc ^= data[i] & 0xFF;
            for (int j = 0; j < 8; j++) {
                crc = (crc & 0x80) != 0
                        ? ((crc << 1) ^ 0x07) & 0xFF
                        : (crc << 1) & 0xFF;
            }
        }
        return crc & 0xFF;
    }

    private int calculateBatteryPercent(int voltageMilliVolts) {
        final int minMv = 3000;
        final int maxMv = 4200;
        if (voltageMilliVolts >= maxMv) return 100;
        if (voltageMilliVolts <= minMv) return 0;
        return (int) (((long) (voltageMilliVolts - minMv) * 100L) / (maxMv - minMv));
    }

    private double computeAverage(int... values) {
        if (values.length == 0) return 0.0;
        int sum = 0;
        for (int value : values) sum += value;
        return (double) sum / values.length;
    }
}
