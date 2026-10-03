package com.theojansen.nfc.model;

import java.util.Arrays;

/**
 * Objeto de dominio inmutable que encapsula las lecturas del robot (Protocolo V2).
 */
public final class RobotTelemetry {
    private final int version;
    private final int sequenceNumber;
    private final int[] ldrValues;
    private final double ldrAverage;
    private final LightDirection primaryLightDirection;
    private final int servoPitchAngle;
    private final int servoYawAngle;
    private final int polarityReversalsCount;
    private final MotorState motorDirection;
    private final double operatingVoltage;
    private final int batteryLevelPercent;
    private final boolean batteryValid;
    private final long timestamp;
    private final String tagUid;

    public RobotTelemetry(int version, int sequenceNumber, int[] ldrValues, double ldrAverage,
                          LightDirection primaryLightDirection, int servoPitchAngle, int servoYawAngle,
                          int polarityReversalsCount, MotorState motorDirection, double operatingVoltage,
                          int batteryLevelPercent, boolean batteryValid, long timestamp, String tagUid) {
        this.version = version;
        this.sequenceNumber = sequenceNumber;
        this.ldrValues = ldrValues != null ? ldrValues.clone() : new int[0];
        this.ldrAverage = ldrAverage;
        this.primaryLightDirection = primaryLightDirection;
        this.servoPitchAngle = servoPitchAngle;
        this.servoYawAngle = servoYawAngle;
        this.polarityReversalsCount = polarityReversalsCount;
        this.motorDirection = motorDirection;
        this.operatingVoltage = operatingVoltage;
        this.batteryLevelPercent = batteryLevelPercent;
        this.batteryValid = batteryValid;
        this.timestamp = timestamp;
        this.tagUid = tagUid;
    }

    // Constructor de retrocompatibilidad
    public RobotTelemetry(int[] ldrValues, double ldrAverage, LightDirection primaryLightDirection,
                          int servoPitchAngle, int servoYawAngle, int polarityReversalsCount,
                          MotorState motorDirection, double operatingVoltage, int batteryLevelPercent,
                          long timestamp, String tagUid) {
        this(2, 0, ldrValues, ldrAverage, primaryLightDirection, servoPitchAngle, servoYawAngle,
                polarityReversalsCount, motorDirection, operatingVoltage, batteryLevelPercent,
                operatingVoltage > 0.05, timestamp, tagUid);
    }

    public int getVersion() {
        return version;
    }

    public int getSequenceNumber() {
        return sequenceNumber;
    }

    public int[] getLdrValues() {
        return ldrValues.clone();
    }

    public double getLdrAverage() {
        return ldrAverage;
    }

    public LightDirection getPrimaryLightDirection() {
        return primaryLightDirection;
    }

    public int getServoPitchAngle() {
        return servoPitchAngle;
    }

    public int getServoYawAngle() {
        return servoYawAngle;
    }

    public int getPolarityReversalsCount() {
        return polarityReversalsCount;
    }

    public MotorState getMotorDirection() {
        return motorDirection;
    }

    public double getOperatingVoltage() {
        return operatingVoltage;
    }

    public int getBatteryLevelPercent() {
        return batteryLevelPercent;
    }

    public boolean isBatteryValid() {
        return batteryValid;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public String getTagUid() {
        return tagUid;
    }

    @Override
    public String toString() {
        return "RobotTelemetry{" +
                "version=" + version +
                ", seq=" + sequenceNumber +
                ", tagUid='" + tagUid + '\'' +
                ", ldrAverage=" + ldrAverage +
                ", direction=" + primaryLightDirection +
                ", motor=" + motorDirection +
                ", pitch=" + servoPitchAngle + "°" +
                ", yaw=" + servoYawAngle + "°" +
                ", voltage=" + (batteryValid ? operatingVoltage + "V" : "N/D") +
                ", battery=" + (batteryValid ? batteryLevelPercent + "%" : "N/D") +
                '}';
    }
}
