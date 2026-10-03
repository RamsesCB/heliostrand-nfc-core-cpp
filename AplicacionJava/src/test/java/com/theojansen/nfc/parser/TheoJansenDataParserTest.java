package com.theojansen.nfc.parser;

import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.RobotTelemetry;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TheoJansenDataParserTest {

    @Test
    @DisplayName("Debe parsear correctamente una trama binaria válida de 12 bytes")
    void testDecodeTelemetryPayloadSuccess() throws Exception {
        TheoJansenDataParser parser = new TheoJansenDataParser();

        // Trama simulada:
        // LDRs: Norte=200, Sur=50, Oeste=100, Este=80
        // Servos: Pitch=90°, Yaw=45°
        // PolarityReversals: 4 (0x00, 0x04)
        // Voltage: 5050 mV = 5.05V (0x13, 0xBA)
        // Battery: 85%
        // Checksum CRC-8 precalculado
        byte[] mockPayload = new byte[]{
                (byte) 200, (byte) 50, (byte) 100, (byte) 80,
                (byte) 90, (byte) 45,
                (byte) 0x00, (byte) 0x04,
                (byte) 0x13, (byte) 0xBA,
                (byte) 85,
                (byte) 0x00 // Nota: se ajusta al CRC esperado según polinomio
        };

        // Calculamos byte de checksum dinámicamente para la prueba
        int crc = 0;
        for (int i = 0; i < 11; i++) {
            crc ^= (mockPayload[i] & 0xFF);
            for (int j = 0; j < 8; j++) {
                if ((crc & 0x80) != 0) crc = ((crc << 1) ^ 0x07) & 0xFF;
                else crc = (crc << 1) & 0xFF;
            }
        }
        mockPayload[11] = (byte) crc;

        RobotTelemetry telemetry = parser.decodeTelemetryPayload(mockPayload, "TAG-NFC-TEST-1234");

        assertNotNull(telemetry);
        assertEquals("TAG-NFC-TEST-1234", telemetry.getTagUid());
        assertEquals(90, telemetry.getServoPitchAngle());
        assertEquals(45, telemetry.getServoYawAngle());
        assertEquals(5.05, telemetry.getOperatingVoltage(), 0.01);
        assertEquals(85, telemetry.getBatteryLevelPercent());
        assertEquals(LightDirection.NORTE, telemetry.getPrimaryLightDirection());
    }

    @Test
    @DisplayName("Debe lanzar CorruptedPayloadException si la trama tiene CRC inválido")
    void testCorruptedChecksum() {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] invalidCrcPayload = new byte[]{
                (byte) 100, (byte) 100, (byte) 100, (byte) 100,
                (byte) 90, (byte) 90,
                (byte) 0x00, (byte) 0x02,
                (byte) 0x13, (byte) 0x88,
                (byte) 99,
                (byte) 0xFF // Checksum erróneo deliberado
        };

        assertThrows(CorruptedPayloadException.class, () -> {
            parser.decodeTelemetryPayload(invalidCrcPayload, "TAG-FAIL");
        });
    }

    @Test
    @DisplayName("Debe lanzar CorruptedPayloadException si la trama tiene longitud menor a 12 bytes")
    void testIncompletePayload() {
        TheoJansenDataParser parser = new TheoJansenDataParser();
        byte[] shortPayload = new byte[]{0x01, 0x02, 0x03};

        assertThrows(CorruptedPayloadException.class, () -> {
            parser.decodeTelemetryPayload(shortPayload, "TAG-SHORT");
        });
    }
}
