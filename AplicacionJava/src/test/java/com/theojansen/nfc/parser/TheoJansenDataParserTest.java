package com.theojansen.nfc.parser;

import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TheoJansenDataParserTest {

    private byte[] hexToBytes(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                    + Character.digit(s.charAt(i + 1), 16));
        }
        return data;
    }

    @Test
    @DisplayName("Golden Vector 1: Condición nominal soleada con marcha adelante hacia el este")
    void testGoldenVector1NominalForwardEast() throws Exception {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] payload = hexToBytes("9301647882915A5C0F0A026A");

        RobotTelemetry t = parser.decodeTelemetryPayload(payload, "UID-GOLDEN-01");

        assertNotNull(t);
        assertEquals(2, t.getVersion());
        assertEquals(1, t.getSequenceNumber());
        assertEquals(MotorState.ADELANTE, t.getMotorDirection());
        assertEquals(LightDirection.ESTE, t.getPrimaryLightDirection());
        assertEquals(90, t.getServoPitchAngle());
        assertEquals(92, t.getServoYawAngle());
        assertEquals(3.85, t.getOperatingVoltage(), 0.001);
        assertTrue(t.isBatteryValid());
        assertEquals(2, t.getPolarityReversalsCount());
    }

    @Test
    @DisplayName("Golden Vector 2: Robot detenido bajo iluminación solar equilibrada")
    void testGoldenVector2StoppedBalanced() throws Exception {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] payload = hexToBytes("8002969696965A5A1004009F");

        RobotTelemetry t = parser.decodeTelemetryPayload(payload, "UID-GOLDEN-02");

        assertNotNull(t);
        assertEquals(2, t.getVersion());
        assertEquals(2, t.getSequenceNumber());
        assertEquals(MotorState.DETENIDO, t.getMotorDirection());
        assertEquals(LightDirection.EQUILIBRADO, t.getPrimaryLightDirection());
        assertEquals(90, t.getServoPitchAngle());
        assertEquals(90, t.getServoYawAngle());
        assertEquals(4.10, t.getOperatingVoltage(), 0.001);
        assertTrue(t.isBatteryValid());
        assertEquals(0, t.getPolarityReversalsCount());
    }

    @Test
    @DisplayName("Golden Vector 3: Marcha atrás hacia el sur con batería baja (3300 mV)")
    void testGoldenVector3ReverseSouthLowBat() throws Exception {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] payload = hexToBytes("A20A32DC50462D870CE4053A");

        RobotTelemetry t = parser.decodeTelemetryPayload(payload, "UID-GOLDEN-03");

        assertNotNull(t);
        assertEquals(2, t.getVersion());
        assertEquals(10, t.getSequenceNumber());
        assertEquals(MotorState.ATRAS, t.getMotorDirection());
        assertEquals(LightDirection.SUR, t.getPrimaryLightDirection());
        assertEquals(45, t.getServoPitchAngle());
        assertEquals(135, t.getServoYawAngle());
        assertEquals(3.30, t.getOperatingVoltage(), 0.001);
        assertTrue(t.isBatteryValid());
        assertEquals(5, t.getPolarityReversalsCount());
    }

    @Test
    @DisplayName("Golden Vector 4: Sensor de batería desconectado (0 mV, sensor inválido)")
    void testGoldenVector4BatteryDisconnected() throws Exception {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] payload = hexToBytes("8014646464645A5A000001AA");

        RobotTelemetry t = parser.decodeTelemetryPayload(payload, "UID-GOLDEN-04");

        assertNotNull(t);
        assertEquals(20, t.getSequenceNumber());
        assertEquals(0.0, t.getOperatingVoltage(), 0.001);
        assertFalse(t.isBatteryValid());
        assertEquals(0, t.getBatteryLevelPercent());
    }

    @Test
    @DisplayName("Debe rechazar estrictamente tramas con longitud distinta de 12 bytes")
    void testStrictPayloadLengthValidation() {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] shortPayload = new byte[11];
        byte[] longPayload = new byte[13];

        assertThrows(CorruptedPayloadException.class, () -> parser.decodeTelemetryPayload(shortPayload, "SHORT"));
        assertThrows(CorruptedPayloadException.class, () -> parser.decodeTelemetryPayload(longPayload, "LONG"));
        assertThrows(CorruptedPayloadException.class, () -> parser.decodeTelemetryPayload(null, "NULL"));
    }

    @Test
    @DisplayName("Debe lanzar CorruptedPayloadException si el CRC-8 no coincide")
    void testCorruptedCrc() {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] corrupted = hexToBytes("9301647882915A5C0F0A02FF");

        assertThrows(CorruptedPayloadException.class, () -> parser.decodeTelemetryPayload(corrupted, "CORRUPT"));
    }

    @Test
    @DisplayName("Debe lanzar InvalidTelemetryException ante valores fuera de límites físicos")
    void testSemanticRangeValidation() {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        // Pitch = 200° (> 180°), CRC recalculado
        byte[] invalidAngle = new byte[]{
                (byte) 0x80, (byte) 0x01, (byte) 100, (byte) 100, (byte) 100, (byte) 100,
                (byte) 200, (byte) 90, (byte) 0x0F, (byte) 0x00, (byte) 0x00, (byte) 0x00
        };
        // Calcular CRC correcto para que pase Nivel 1 y falle Nivel 2
        int crc = 0;
        for (int i = 0; i < 11; i++) {
            crc ^= (invalidAngle[i] & 0xFF);
            for (int j = 0; j < 8; j++) {
                if ((crc & 0x80) != 0) crc = ((crc << 1) ^ 0x07) & 0xFF;
                else crc = (crc << 1) & 0xFF;
            }
        }
        invalidAngle[11] = (byte) crc;

        assertThrows(InvalidTelemetryException.class, () -> parser.decodeTelemetryPayload(invalidAngle, "PHYSICAL-FAIL"));
    }
}
