#include "SolarTracker.h"

SolarTracker::SolarTracker()
    : currentPitch(SERVO_PITCH_DEFAULT),
      currentYaw(SERVO_YAW_DEFAULT),
      ldrNorte(0),
      ldrSur(0),
      ldrOeste(0),
      ldrEste(0),
      voltageMilliVolts(0),
      batteryPercent(0),
      batteryValid(false),
      polarityReversals(0),
      sequenceNumber(0),
      motorState(MOTOR_ADELANTE),
      lightDirection(DIR_EQUILIBRADO) {}

void SolarTracker::begin() {
    // Configurar pines de LDRs y batería
    pinMode(PIN_LDR_NORTE, INPUT);
    pinMode(PIN_LDR_SUR, INPUT);
    pinMode(PIN_LDR_OESTE, INPUT);
    pinMode(PIN_LDR_ESTE, INPUT);
    pinMode(PIN_BATTERY_SENSE, INPUT);

    // Configurar LED de estado reasignado a D7
    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, LOW);

    // Configurar pines del motor Theo Jansen
    pinMode(PIN_MOTOR_IN1, OUTPUT);
    pinMode(PIN_MOTOR_IN2, OUTPUT);
    pinMode(PIN_MOTOR_ENABLE, OUTPUT);
    analogWrite(PIN_MOTOR_ENABLE, 200); // Velocidad de crucero PWM

    // Inicializar servomotores
    pitchServo.attach(PIN_SERVO_PITCH);
    yawServo.attach(PIN_SERVO_YAW);

    pitchServo.write(currentPitch);
    yawServo.write(currentYaw);

    // Inicializar tracción
    setMotorState(MOTOR_ADELANTE);

    // Primera lectura de sensores
    updateSensors();
}

uint8_t SolarTracker::readLdr8Bit(uint8_t pin) {
    int raw = analogRead(pin); // 0 a 1023
    // Mapear cuantizado: 10-bit ADC (0..1023) a 8-bit (0..255)
    return (uint8_t)(raw >> 2);
}

void SolarTracker::readPowerSensors() {
    int rawVoltage = analogRead(PIN_BATTERY_SENSE);
    
    // Si la lectura es inferior al umbral, el sensor está desconectado o en cortocircuito
    if (rawVoltage < BATTERY_CUTOFF_ADC) {
        voltageMilliVolts = 0;
        batteryPercent = 0;
        batteryValid = false;
    } else {
        // Cálculo eléctrico real a través del divisor de tensión (R1=100k, R2=100k)
        // Vadc = Vin * R2 / (R1 + R2)  ==> Vin = Vadc * (R1 + R2) / R2
        uint32_t adcMillivolts = ((uint32_t)rawVoltage * ADC_REF_MV) / 1023UL;
        voltageMilliVolts = (uint16_t)((adcMillivolts * (R1_OHM + R2_OHM)) / R2_OHM);
        batteryValid = true;

        // Porcentaje para batería Li-ion (Rango estándar: 3.0V a 4.2V)
        if (voltageMilliVolts >= BATTERY_MAX_MV) {
            batteryPercent = 100;
        } else if (voltageMilliVolts <= BATTERY_MIN_MV) {
            batteryPercent = 0;
        } else {
            batteryPercent = (uint8_t)(((uint32_t)(voltageMilliVolts - BATTERY_MIN_MV) * 100UL) / (BATTERY_MAX_MV - BATTERY_MIN_MV));
        }
    }
}

void SolarTracker::computeLightDirection() {
    int diffVert = abs((int)ldrNorte - (int)ldrSur);
    int diffHoriz = abs((int)ldrEste - (int)ldrOeste);

    if (diffVert <= LIGHT_DEADBAND && diffHoriz <= LIGHT_DEADBAND) {
        lightDirection = DIR_EQUILIBRADO;
        return;
    }

    uint8_t maxVal = ldrNorte;
    lightDirection = DIR_NORTE;

    if (ldrSur > maxVal) {
        maxVal = ldrSur;
        lightDirection = DIR_SUR;
    }
    if (ldrEste > maxVal) {
        maxVal = ldrEste;
        lightDirection = DIR_ESTE;
    }
    if (ldrOeste > maxVal) {
        maxVal = ldrOeste;
        lightDirection = DIR_OESTE;
    }
}

void SolarTracker::updateSensors() {
    ldrNorte = readLdr8Bit(PIN_LDR_NORTE);
    ldrSur   = readLdr8Bit(PIN_LDR_SUR);
    ldrOeste = readLdr8Bit(PIN_LDR_OESTE);
    ldrEste  = readLdr8Bit(PIN_LDR_ESTE);

    readPowerSensors();
    computeLightDirection();
}

void SolarTracker::updateTracking() {
    updateSensors();

    // 1. Control de elevación (Pitch): Norte vs Sur con constrain seguro
    int diffVertical = (int)ldrNorte - (int)ldrSur;
    if (abs(diffVertical) > LIGHT_DEADBAND) {
        if (diffVertical > 0) {
            currentPitch = (uint8_t)constrain((int)currentPitch - SERVO_STEP_SIZE, SERVO_PITCH_MIN, SERVO_PITCH_MAX);
        } else {
            currentPitch = (uint8_t)constrain((int)currentPitch + SERVO_STEP_SIZE, SERVO_PITCH_MIN, SERVO_PITCH_MAX);
        }
        pitchServo.write(currentPitch);
    }

    // 2. Control de azimut (Yaw): Este vs Oeste con constrain seguro
    int diffHorizontal = (int)ldrEste - (int)ldrOeste;
    if (abs(diffHorizontal) > LIGHT_DEADBAND) {
        if (diffHorizontal > 0) {
            currentYaw = (uint8_t)constrain((int)currentYaw + SERVO_STEP_SIZE, SERVO_YAW_MIN, SERVO_YAW_MAX);
        } else {
            currentYaw = (uint8_t)constrain((int)currentYaw - SERVO_STEP_SIZE, SERVO_YAW_MIN, SERVO_YAW_MAX);
        }
        yawServo.write(currentYaw);
    }
}

void SolarTracker::setMotorState(TheoJansenMotorState newState) {
    // Incrementar inversiones estrictamente ante un cambio efectivo de marcha entre ADELANTE y ATRAS
    if ((motorState == MOTOR_ADELANTE && newState == MOTOR_ATRAS) ||
        (motorState == MOTOR_ATRAS && newState == MOTOR_ADELANTE)) {
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
    packet.version = PROTOCOL_VERSION_V2;
    packet.motorState = motorState;
    packet.lightDirection = lightDirection;
    packet.sequenceNumber = sequenceNumber++;
    packet.ldrNorte = ldrNorte;
    packet.ldrSur = ldrSur;
    packet.ldrOeste = ldrOeste;
    packet.ldrEste = ldrEste;
    packet.servoPitch = currentPitch;
    packet.servoYaw = currentYaw;
    packet.voltageMilliVolts = voltageMilliVolts;
    packet.batteryValid = batteryValid;
    packet.polarityReversals = polarityReversals;
    packet.checksumCRC8 = 0; // Se calcula en packTelemetry

    return packet;
}
