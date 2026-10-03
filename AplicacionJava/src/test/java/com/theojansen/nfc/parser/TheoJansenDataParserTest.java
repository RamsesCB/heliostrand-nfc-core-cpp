package com.theojansen.nfc.parser;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

class TheoJansenDataParserTest {
    private static final TheoJansenDataParser PARSER = new TheoJansenDataParser();

    private static JsonObject loadVectorDocument() throws IOException {
        Path[] candidates = {
                Path.of("../test/vectors/golden_telemetry_vectors.json"),
                Path.of("test/vectors/golden_telemetry_vectors.json")
        };
        for (Path candidate : candidates) {
            if (Files.exists(candidate)) {
                return JsonParser.parseString(Files.readString(candidate)).getAsJsonObject();
            }
        }
        throw new IOException("No se encontró test/vectors/golden_telemetry_vectors.json");
    }

    private static byte[] hexToBytes(String hex) {
        if ((hex.length() & 1) != 0) throw new IllegalArgumentException("hex impar");
        byte[] out = new byte[hex.length() / 2];
        for (int i = 0; i < hex.length(); i += 2) {
            out[i / 2] = (byte) Integer.parseInt(hex.substring(i, i + 2), 16);
        }
        return out;
    }

    private static MotorState expectedMotor(String value) {
        return switch (value) {
            case "STOPPED" -> MotorState.DETENIDO;
            case "FORWARD" -> MotorState.ADELANTE;
            case "REVERSE" -> MotorState.ATRAS;
            default -> throw new IllegalArgumentException(value);
        };
    }

    private static LightDirection expectedDirection(String value) {
        return switch (value) {
            case "BALANCED" -> LightDirection.EQUILIBRADO;
            case "NORTH" -> LightDirection.NORTE;
            case "SOUTH" -> LightDirection.SUR;
            case "EAST" -> LightDirection.ESTE;
            case "WEST" -> LightDirection.OESTE;
            default -> throw new IllegalArgumentException(value);
        };
    }

    @Test
    void sharedGoldenVectorsAreDecodedFromJson() throws Exception {
        JsonArray vectors = loadVectorDocument().getAsJsonArray("vectors");
        int checked = 0;
        for (var element : vectors) {
            JsonObject vector = element.getAsJsonObject();
            JsonObject expected = vector.getAsJsonObject("expected");
            if (!expected.has("valid") || !expected.get("valid").getAsBoolean()) continue;

            RobotTelemetry t = PARSER.decodeTelemetryPayload(
                    hexToBytes(vector.get("hex").getAsString()),
                    "UID-" + vector.get("id").getAsString());

            assertEquals(expected.get("version").getAsInt(), t.getVersion());
            assertEquals(expected.get("sequence_number").getAsInt(), t.getSequenceNumber());
            assertEquals(expectedMotor(expected.get("motor_state").getAsString()), t.getMotorDirection());
            assertEquals(expectedDirection(expected.get("light_direction").getAsString()), t.getPrimaryLightDirection());
            assertEquals(expected.get("servo_pitch").getAsInt(), t.getServoPitchAngle());
            assertEquals(expected.get("servo_yaw").getAsInt(), t.getServoYawAngle());
            assertEquals(expected.get("battery_millivolts").getAsInt() / 1000.0,
                    t.getOperatingVoltage(), 0.001);
            assertEquals(expected.get("battery_valid").getAsBoolean(), t.isBatteryValid());
            assertEquals(expected.get("polarity_reversals").getAsInt(), t.getPolarityReversalsCount());
            checked++;
        }
        assertEquals(4, checked);
    }

    @Test
    void corruptedVectorFromSharedJsonIsRejected() throws Exception {
        JsonArray vectors = loadVectorDocument().getAsJsonArray("vectors");
        for (var element : vectors) {
            JsonObject vector = element.getAsJsonObject();
            JsonObject expected = vector.getAsJsonObject("expected");
            if (expected.has("error_type")
                    && "CORRUPTED_CRC".equals(expected.get("error_type").getAsString())) {
                byte[] payload = hexToBytes(vector.get("hex").getAsString());
                assertThrows(CorruptedPayloadException.class,
                        () -> PARSER.decodeTelemetryPayload(payload, "CRC-BAD"));
                return;
            }
        }
        fail("No existe vector CORRUPTED_CRC en el JSON compartido");
    }

    @Test
    void requiresExactlyTwelveBytes() {
        assertThrows(CorruptedPayloadException.class,
                () -> PARSER.decodeTelemetryPayload(new byte[11], "SHORT"));
        assertThrows(CorruptedPayloadException.class,
                () -> PARSER.decodeTelemetryPayload(new byte[13], "LONG"));
        assertThrows(CorruptedPayloadException.class,
                () -> PARSER.decodeTelemetryPayload(null, "NULL"));
    }

    @Test
    void rejectsUnsupportedProtocolVersion() {
        byte[] payload = validBasePayload();
        payload[0] = (byte) ((1 << 6) | (1 << 4) | 3);
        repairCrc(payload);
        assertThrows(UnsupportedProtocolVersionException.class,
                () -> PARSER.decodeTelemetryPayload(payload, "V1"));
    }

    @Test
    void rejectsReservedMotorCode() {
        byte[] payload = validBasePayload();
        payload[0] = (byte) ((2 << 6) | (3 << 4) | 3);
        repairCrc(payload);
        assertThrows(InvalidTelemetryException.class,
                () -> PARSER.decodeTelemetryPayload(payload, "MOTOR-RESERVED"));
    }

    @Test
    void rejectsReservedDirectionCode() {
        byte[] payload = validBasePayload();
        payload[0] = (byte) ((2 << 6) | (1 << 4) | 5);
        repairCrc(payload);
        assertThrows(InvalidTelemetryException.class,
                () -> PARSER.decodeTelemetryPayload(payload, "DIR-RESERVED"));
    }

    @Test
    void rejectsPhysicalRangeViolations() {
        byte[] angleBad = validBasePayload();
        angleBad[6] = (byte) 200;
        repairCrc(angleBad);
        assertThrows(InvalidTelemetryException.class,
                () -> PARSER.decodeTelemetryPayload(angleBad, "ANGLE-BAD"));

        byte[] voltageBad = validBasePayload();
        voltageBad[8] = 0x17;
        voltageBad[9] = 0x70; // 6000 mV
        repairCrc(voltageBad);
        assertThrows(InvalidTelemetryException.class,
                () -> PARSER.decodeTelemetryPayload(voltageBad, "VOLT-BAD"));
    }

    private static byte[] validBasePayload() {
        byte[] payload = hexToBytes("9301647882915A5C0F0A026A");
        repairCrc(payload);
        return payload;
    }

    private static void repairCrc(byte[] payload) {
        payload[11] = (byte) TheoJansenDataParser.computeCrc8(payload, 11);
    }
}
