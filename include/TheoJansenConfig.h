#ifndef THEO_JANSEN_CONFIG_H
#define THEO_JANSEN_CONFIG_H

#include <Arduino.h>

// Hardware target: Arduino Uno R3 / ATmega328P
#define PIN_LDR_NORTE        A0
#define PIN_LDR_SUR          A1
#define PIN_LDR_OESTE        A2
#define PIN_LDR_ESTE         A3
#define PIN_BATTERY_SENSE    A4

#define PIN_SERVO_PITCH      9
#define PIN_SERVO_YAW        10

#define PIN_MOTOR_IN1        5
#define PIN_MOTOR_IN2        6
#define PIN_MOTOR_ENABLE     3

#define PIN_PN532_CS         4
#define PIN_PN532_MOSI       11
#define PIN_PN532_MISO       12
#define PIN_PN532_SCK        13
#define PIN_PN532_IRQ        2

#define PIN_STATUS_LED       7

#define PROTOCOL_VERSION_V2  2

#define SERVO_PITCH_MIN      15
#define SERVO_PITCH_MAX      165
#define SERVO_PITCH_DEFAULT  90
#define SERVO_YAW_MIN        10
#define SERVO_YAW_MAX        170
#define SERVO_YAW_DEFAULT    90

#define LIGHT_DEADBAND       12
#define SERVO_STEP_SIZE      2

// Battery hardware: 1S Li-ion, 20k/20k divider + 100 nF from A4 to GND.
// 20k || 20k = 10k source impedance, matching the ATmega328P ADC guidance.
#define R1_OHM                   20000UL
#define R2_OHM                   20000UL
#define BATTERY_MIN_MV           3000
#define BATTERY_MAX_MV           4200
#define BATTERY_VALID_MIN_MV     2500
#define BATTERY_VALID_MAX_MV     5000
#define BATTERY_CUTOFF_ADC       25
#define BATTERY_SAMPLE_COUNT     8
#define ADC_SETTLING_US          250
#define ADC_REF_MV_FALLBACK      5000UL

#define TELEMETRY_PAYLOAD_SIZE   12
#define SERIAL_BAUD_RATE         115200

#define TRACKING_INTERVAL_MS     250
#define TELEMETRY_INTERVAL_MS    1000

// NTAG213 endurance policy.
// First write is immediate. Subsequent writes require at least 5 minutes.
// Unchanged state is refreshed only every 15 minutes.
#define NFC_WRITE_MIN_INTERVAL_MS        300000UL
#define NFC_PERIODIC_REFRESH_MS          900000UL
#define NFC_WRITE_RETRY_BACKOFF_MS       5000UL
#define NFC_LDR_DELTA_THRESHOLD          8
#define NFC_SERVO_DELTA_DEG              5
#define NFC_BATTERY_DELTA_MV             50
#define NFC_ENFORCE_EXPECTED_UID          0
#if NFC_ENFORCE_EXPECTED_UID
static const uint8_t NFC_EXPECTED_UID[7] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
#endif
#define NFC_LOCK_FIRST_TAG_PER_BOOT      1

#endif
