#include "SolarTracker.h"

#if defined(__AVR__)
#include <avr/io.h>
#endif

namespace {
uint16_t readVccMilliVolts() {
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
    const uint8_t previousAdmux = ADMUX;
    ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
    delay(2);
    ADCSRA |= _BV(ADSC);
    while (bit_is_set(ADCSRA, ADSC)) {}
    const uint16_t adc = ADC;
    ADMUX = previousAdmux;
    if (adc == 0) return (uint16_t)ADC_REF_MV_FALLBACK;
    return (uint16_t)(1125300UL / adc);
#else
    return (uint16_t)ADC_REF_MV_FALLBACK;
#endif
}
}

SolarTracker::SolarTracker()
    : currentPitch(SERVO_PITCH_DEFAULT),
      currentYaw(SERVO_YAW_DEFAULT),
      ldrNorte(0),
      ldrSur(0),
      ldrOeste(0),
      ldrEste(0),
      voltageMilliVolts(0),
      batteryValid(false),
      polarityReversals(0),
      sequenceNumber(0),
      motorState(MOTOR_ADELANTE),
      lightDirection(DIR_EQUILIBRADO) {}

void SolarTracker::begin() {

    pinMode(PIN_LDR_NORTE, INPUT);
    pinMode(PIN_LDR_SUR, INPUT);
    pinMode(PIN_LDR_OESTE, INPUT);
    pinMode(PIN_LDR_ESTE, INPUT);
    pinMode(PIN_BATTERY_SENSE, INPUT);

    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, LOW);

    pinMode(PIN_MOTOR_IN1, OUTPUT);
    pinMode(PIN_MOTOR_IN2, OUTPUT);
    pinMode(PIN_MOTOR_ENABLE, OUTPUT);
    analogWrite(PIN_MOTOR_ENABLE, 200);

    pitchServo.attach(PIN_SERVO_PITCH);
    yawServo.attach(PIN_SERVO_YAW);

    pitchServo.write(currentPitch);
    yawServo.write(currentYaw);

    setMotorState(MOTOR_ADELANTE);

    updateSensors();
}

uint8_t SolarTracker::readLdr8Bit(uint8_t pin) {
    int raw = analogRead(pin);

    return (uint8_t)(raw >> 2);
}

void SolarTracker::readPowerSensors() {

    (void)analogRead(PIN_BATTERY_SENSE);
    delayMicroseconds(ADC_SETTLING_US);

    uint32_t total = 0;
    for (uint8_t i = 0; i < BATTERY_SAMPLE_COUNT; ++i) {
        total += (uint16_t)analogRead(PIN_BATTERY_SENSE);
    }
    const uint16_t rawVoltage = (uint16_t)(total / BATTERY_SAMPLE_COUNT);

    if (rawVoltage < BATTERY_CUTOFF_ADC) {
        voltageMilliVolts = 0;
        batteryValid = false;
        return;
    }

    const uint32_t vccMv = readVccMilliVolts();
    const uint32_t adcMillivolts = ((uint32_t)rawVoltage * vccMv) / 1023UL;
    const uint32_t batteryMv =
        (adcMillivolts * (R1_OHM + R2_OHM)) / R2_OHM;

    if (batteryMv < BATTERY_VALID_MIN_MV ||
        batteryMv > BATTERY_VALID_MAX_MV) {
        voltageMilliVolts = 0;
        batteryValid = false;
        return;
    }

    voltageMilliVolts = (uint16_t)batteryMv;
    batteryValid = true;

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

    int diffVertical = (int)ldrNorte - (int)ldrSur;
    if (abs(diffVertical) > LIGHT_DEADBAND) {
        if (diffVertical > 0) {
            currentPitch = (uint8_t)constrain((int)currentPitch - SERVO_STEP_SIZE, SERVO_PITCH_MIN, SERVO_PITCH_MAX);
        } else {
            currentPitch = (uint8_t)constrain((int)currentPitch + SERVO_STEP_SIZE, SERVO_PITCH_MIN, SERVO_PITCH_MAX);
        }
        pitchServo.write(currentPitch);
    }

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

void SolarTracker::setServoAngles(uint8_t pitch, uint8_t yaw) {
    currentPitch = (uint8_t)constrain((int)pitch, SERVO_PITCH_MIN, SERVO_PITCH_MAX);
    currentYaw   = (uint8_t)constrain((int)yaw, SERVO_YAW_MIN, SERVO_YAW_MAX);
    pitchServo.write(currentPitch);
    yawServo.write(currentYaw);
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

    return packet;
}
