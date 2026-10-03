#ifndef THEO_JANSEN_CONFIG_H
#define THEO_JANSEN_CONFIG_H

#include <Arduino.h>

// ====================================================================
// CONFIGURACIÓN DE PINES DE HARDWARE (Arduino Uno)
// ====================================================================

// Sensores de Luz LDR (Entradas Analógicas)
#define PIN_LDR_NORTE        A0  // LDR Arriba (Norte)
#define PIN_LDR_SUR          A1  // LDR Abajo (Sur)
#define PIN_LDR_OESTE        A2  // LDR Izquierda (Oeste)
#define PIN_LDR_ESTE         A3  // LDR Derecha (Este)

// Sensor de Voltaje / Batería (Entrada Analógica)
#define PIN_BATTERY_SENSE    A4  // Divisor de tensión o monitoreo de riel

// Servomotores de Seguimiento Solar (PWM)
#define PIN_SERVO_PITCH      9   // Servo Vertical (Elevación)
#define PIN_SERVO_YAW        10  // Servo Horizontal (Acimut)

// Motor DC para Mecanismo Theo Jansen (Puente H)
#define PIN_MOTOR_IN1        5   // Control Dirección 1
#define PIN_MOTOR_IN2        6   // Control Dirección 2
#define PIN_MOTOR_ENABLE     3   // PWM de velocidad (opcional / jumper)

// Indicador de Estado
#define PIN_STATUS_LED       13  // LED Integrado

// ====================================================================
// CONSTANTES Y PARÁMETROS OPERATIVOS
// ====================================================================

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

// Tamaño exacto de la trama de telemetría en bytes
#define TELEMETRY_PAYLOAD_SIZE 12

// Velocidad de transmisión serial para debug / enlace directo
#define SERIAL_BAUD_RATE     115200

// Intervalo de ciclo de telemetría y tracking (milisegundos)
#define TRACKING_INTERVAL_MS 250
#define TELEMETRY_INTERVAL_MS 1000

#endif // THEO_JANSEN_CONFIG_H
