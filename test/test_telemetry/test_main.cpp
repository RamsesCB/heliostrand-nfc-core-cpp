#include <unity.h>
#include <string.h>

#include "TheoJansenTelemetry.h"
#include "NfcWritePolicy.h"
#include "../generated/golden_vectors.h"

void setUp() {}
void tearDown() {}

void test_pack_matches_shared_golden_vectors() {
    for (uint8_t i = 0; i < GENERATED_GOLDEN_VECTOR_COUNT; ++i) {
        const auto &g = GENERATED_GOLDEN_VECTORS[i];
        TelemetryPacket p{};
        p.version = g.version;
        p.motorState = static_cast<TheoJansenMotorState>(g.motor);
        p.lightDirection = static_cast<TheoJansenLightDirection>(g.direction);
        p.sequenceNumber = g.sequence;
        p.ldrNorte = g.ldrN;
        p.ldrSur = g.ldrS;
        p.ldrOeste = g.ldrW;
        p.ldrEste = g.ldrE;
        p.servoPitch = g.pitch;
        p.servoYaw = g.yaw;
        p.voltageMilliVolts = g.batteryMv;
        p.batteryValid = g.batteryMv != 0;
        p.polarityReversals = g.reversals;

        uint8_t actual[12] = {0};
        packTelemetry(p, actual);
        TEST_ASSERT_EQUAL_UINT8_ARRAY_MESSAGE(g.payload, actual, 12, g.id);
        TEST_ASSERT_TRUE_MESSAGE(verifyTelemetryCRC(actual, 12), g.id);
    }
}


void test_nfc_change_detection_ignores_sequence_and_crc() {
    uint8_t previous[12] = {0x93, 1, 100, 120, 130, 145, 90, 92, 0x0F, 0x0A, 2, 0x6A};
    uint8_t current[12];
    memcpy(current, previous, 12);
    current[1] = 200;
    current[11] = 0x01;

    TEST_ASSERT_FALSE(nfcPayloadMeaningfullyChanged(
        current, previous, 8, 5, 50));

    current[0] ^= 0x10;
    TEST_ASSERT_TRUE(nfcPayloadMeaningfullyChanged(
        current, previous, 8, 5, 50));
}

void test_nfc_write_policy_enforces_minimum_and_refresh() {
    TEST_ASSERT_TRUE(nfcShouldWrite(false, 0, false, 300000UL, 900000UL));
    TEST_ASSERT_FALSE(nfcShouldWrite(true, 299999UL, true, 300000UL, 900000UL));
    TEST_ASSERT_TRUE(nfcShouldWrite(true, 300000UL, true, 300000UL, 900000UL));
    TEST_ASSERT_FALSE(nfcShouldWrite(true, 600000UL, false, 300000UL, 900000UL));
    TEST_ASSERT_TRUE(nfcShouldWrite(true, 900000UL, false, 300000UL, 900000UL));
}

void test_generation_wrap_is_ordered_modularly() {
    TEST_ASSERT_TRUE(nfcGenerationNewer(0, 255));
    TEST_ASSERT_TRUE(nfcGenerationNewer(10, 9));
    TEST_ASSERT_FALSE(nfcGenerationNewer(9, 10));
    TEST_ASSERT_FALSE(nfcGenerationNewer(42, 42));
}

void test_corrupted_crc_is_rejected() {
    TEST_ASSERT_FALSE(verifyTelemetryCRC(GENERATED_CORRUPTED_PAYLOAD, 12));
}

void test_crc_requires_exact_length() {
    uint8_t buffer[13] = {0};
    TEST_ASSERT_FALSE(verifyTelemetryCRC(buffer, 11));
    TEST_ASSERT_FALSE(verifyTelemetryCRC(buffer, 13));
}

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_pack_matches_shared_golden_vectors);
    RUN_TEST(test_nfc_change_detection_ignores_sequence_and_crc);
    RUN_TEST(test_nfc_write_policy_enforces_minimum_and_refresh);
    RUN_TEST(test_generation_wrap_is_ordered_modularly);
    RUN_TEST(test_corrupted_crc_is_rejected);
    RUN_TEST(test_crc_requires_exact_length);
    return UNITY_END();
}
