#ifndef THEO_JANSEN_CONFIG_H
#define THEO_JANSEN_CONFIG_H

#include <Arduino.h>

// ====================================================================
// CONFIGURACIÓN DE PINES DE HARDWARE (Arduino Uno R3 - Pinout Definitivo)
// ====================================================================

// Sensores de Luz LDR (Entradas Analógicas)
#define PIN_LDR_NORTE        A0  // LDR Arriba (Norte)
#define PIN_LDR_SUR          A1  // LDR Abajo (Sur)
#define PIN_LDR_OESTE        A2  // LDR Izquierda (Oeste)
#define PIN_LDR_ESTE         A3  // LDR Derecha (Este)

// Sensor de Tensión Batería (Entrada Analógica con divisor resistivo 1:2)
#define PIN_BATTERY_SENSE    A4  // Divisor 100k / 100k

// Servomotores de Seguimiento Solar (PWM Timer 1)
#define PIN_SERVO_PITCH      9   // Servo Vertical (Elevación)
#define PIN_SERVO_YAW        10  // Servo Horizontal (Acimut)

// Motor DC para Mecanismo Theo Jansen (Puente H L298N)
#define PIN_MOTOR_IN1        5   // Control Dirección 1
#define PIN_MOTOR_IN2        6   // Control Dirección 2
#define PIN_MOTOR_ENABLE     3   // PWM de velocidad (Timer 2)

// Transceptor NFC PN532 (Bus SPI Hardware)
#define PIN_PN532_CS         4   // Chip Select (D4 dedicado, libera D10)
#define PIN_PN532_MOSI       11  // SPI MOSI Hardware
#define PIN_PN532_MISO       12  // SPI MISO Hardware
#define PIN_PN532_SCK        13  // SPI SCK Hardware
#define PIN_PN532_IRQ        2   // Interrupción externa INT0 (opcional)

// Indicador de Estado del Sistema (Reasignado a D7 para liberar SCK D13)
#define PIN_STATUS_LED       7   

// ====================================================================
// CONSTANTES Y PARÁMETROS OPERATIVOS
// ====================================================================

// Versión del Protocolo de Telemetría
#define PROTOCOL_VERSION_V2  2

// Rango de movimiento de los servomotores (grados)
#define SERVO_PITCH_MIN      15
#define SERVO_PITCH_MAX      165
#define SERVO_PITCH_DEFAULT  90

#define SERVO_YAW_MIN        10
#define SERVO_YAW_MAX        170
#define SERVO_YAW_DEFAULT    90

// Umbral de tolerancia de luz para seguimiento solar (0 - 255)
#define LIGHT_DEADBAND       12
#define SERVO_STEP_SIZE      2

// Calibración eléctrica de batería Li-ion (1S)
#define ADC_REF_MV           5000UL
#define R1_OHM               100000UL
#define R2_OHM               100000UL
#define BATTERY_MIN_MV       3000   // 0% Li-ion
#define BATTERY_MAX_MV       4200   // 100% Li-ion
#define BATTERY_CUTOFF_ADC   50     // Debajo de este ADC se considera desconectado

// Tamaño exacto de la trama de telemetría en bytes
#define TELEMETRY_PAYLOAD_SIZE 12

// Velocidad de transmisión serial para debug / enlace directo
#define SERIAL_BAUD_RATE     115200

// Intervalo de ciclo de tracking y telemetría
#define TRACKING_INTERVAL_MS 250
#define TELEMETRY_INTERVAL_MS 1000

// Política anti-desgaste EEPROM NTAG213 (mínimo intervalo en ms entre escrituras)
#define NFC_WRITE_THROTTLE_MS 30000UL // Máximo 1 escritura cada 30 segundos si cambia estado

#endif // THEO_JANSEN_CONFIG_H
