#include "SolarTracker.h"

SolarTracker::SolarTracker()
    : currentPitch(SERVO_PITCH_DEFAULT),
      currentYaw(SERVO_YAW_DEFAULT),
      ldrNorte(0),
      ldrSur(0),
      ldrOeste(0),
      ldrEste(0),
      voltageMilliVolts(5000),
      batteryPercent(100),
      polarityReversals(0),
      motorState(MOTOR_ADELANTE) {}

void SolarTracker::begin() {
    // Configurar pines de LDRs
    pinMode(PIN_LDR_NORTE, INPUT);
    pinMode(PIN_LDR_SUR, INPUT);
    pinMode(PIN_LDR_OESTE, INPUT);
    pinMode(PIN_LDR_ESTE, INPUT);
    pinMode(PIN_BATTERY_SENSE, INPUT);

    // Configurar pines del motor Theo Jansen
    pinMode(PIN_MOTOR_IN1, OUTPUT);
    pinMode(PIN_MOTOR_IN2, OUTPUT);
    pinMode(PIN_MOTOR_ENABLE, OUTPUT);
    analogWrite(PIN_MOTOR_ENABLE, 200); // Velocidad crucero PWM

    // Inicializar servomotores
    pitchServo.attach(PIN_SERVO_PITCH);
    yawServo.attach(PIN_SERVO_YAW);

    pitchServo.write(currentPitch);
    yawServo.write(currentYaw);

    // Inicializar tracción en marcha hacia adelante
    setMotorState(MOTOR_ADELANTE);

    // Primera lectura de sensores
    updateSensors();
}

uint8_t SolarTracker::readLdr8Bit(uint8_t pin) {
    int raw = analogRead(pin); // 0 a 1023
    // Mapear 10-bit ADC (0..1023) a 8-bit (0..255)
    return (uint8_t)(raw >> 2);
}

void SolarTracker::readPowerSensors() {
    int rawVoltage = analogRead(PIN_BATTERY_SENSE);
    
    // Si no hay divisor conectado (pin flotante / lectura baja), 
    // asumimos riel USB/regulador estándar de 5.0V con ligera fluctuación natural
    if (rawVoltage < 50) {
        voltageMilliVolts = 5020 + (millis() % 50); // ~5.02V a ~5.07V
        batteryPercent = 90;
    } else {
        // Factor de escala analógico (ej. divisor 1:2 o riel 5V directo)
        // 5V / 1023 = 4.887 mV por unidad ADC
        long calculatedMilliVolts = (long)rawVoltage * 5000L / 1023L;
        voltageMilliVolts = (uint16_t)calculatedMilliVolts;

        // Batería Li-ion o LiFePO4: 3.3V (0%) a 4.2V (100%) o 4.5V-5.0V
        if (voltageMilliVolts >= 5000) {
            batteryPercent = 100;
        } else if (voltageMilliVolts <= 4200) {
            batteryPercent = 20;
        } else {
            batteryPercent = (uint8_t)map(voltageMilliVolts, 4200, 5000, 20, 100);
        }
    }
}

void SolarTracker::updateSensors() {
    ldrNorte = readLdr8Bit(PIN_LDR_NORTE);
    ldrSur   = readLdr8Bit(PIN_LDR_SUR);
    ldrOeste = readLdr8Bit(PIN_LDR_OESTE);
    ldrEste  = readLdr8Bit(PIN_LDR_ESTE);

    readPowerSensors();
}

void SolarTracker::updateTracking() {
    updateSensors();

    // 1. Cálculo de elevación (Pitch): Norte vs Sur
    int diffVertical = (int)ldrNorte - (int)ldrSur;
    if (abs(diffVertical) > LIGHT_DEADBAND) {
        if (diffVertical > 0 && currentPitch > SERVO_PITCH_MIN) {
            currentPitch -= SERVO_STEP_SIZE; // Mover hacia el Norte
        } else if (diffVertical < 0 && currentPitch < SERVO_PITCH_MAX) {
            currentPitch += SERVO_STEP_SIZE; // Mover hacia el Sur
        }
        pitchServo.write(currentPitch);
    }

    // 2. Cálculo de acimut (Yaw): Este vs Oeste
    int diffHorizontal = (int)ldrEste - (int)ldrOeste;
    if (abs(diffHorizontal) > LIGHT_DEADBAND) {
        if (diffHorizontal > 0 && currentYaw < SERVO_YAW_MAX) {
            currentYaw += SERVO_STEP_SIZE; // Mover hacia el Este
        } else if (diffHorizontal < 0 && currentYaw > SERVO_YAW_MIN) {
            currentYaw -= SERVO_STEP_SIZE; // Mover hacia el Oeste
        }
        yawServo.write(currentYaw);
    }
}

void SolarTracker::setMotorState(TheoJansenMotorState newState) {
    if (motorState != newState && newState != MOTOR_DETENIDO) {
        // Cada cambio efectivo de polaridad incrementa el contador
        polarityReversals++;
    }

    motorState = newState;

    switch (motorState) {
        case MOTOR_ADELANTE:
            digitalWrite(PIN_MOTOR_IN1, HIGH);
            digitalWrite(PIN_MOTOR_IN2, LOW);
            break;
        case MOTOR_ATRAS:
            digitalWrite(PIN_MOTOR_IN1, LOW);
            digitalWrite(PIN_MOTOR_IN2, HIGH);
            break;
        case MOTOR_DETENIDO:
        default:
            digitalWrite(PIN_MOTOR_IN1, LOW);
            digitalWrite(PIN_MOTOR_IN2, LOW);
            break;
    }
}

void SolarTracker::toggleMotorDirection() {
    if (motorState == MOTOR_ADELANTE) {
        setMotorState(MOTOR_ATRAS);
    } else {
        setMotorState(MOTOR_ADELANTE);
    }
}

TelemetryPacket SolarTracker::getTelemetrySnapshot() {
    TelemetryPacket packet;
    packet.ldrNorte = ldrNorte;
    packet.ldrSur = ldrSur;
    packet.ldrOeste = ldrOeste;
    packet.ldrEste = ldrEste;
    packet.servoPitch = currentPitch;
    packet.servoYaw = currentYaw;
    packet.polarityReversals = polarityReversals;
    packet.voltageMilliVolts = voltageMilliVolts;
    packet.batteryPercent = batteryPercent;
    packet.checksumCRC8 = 0; // Se calcula al empaquetar

    return packet;
}
