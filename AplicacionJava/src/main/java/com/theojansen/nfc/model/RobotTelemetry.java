package com.theojansen.nfc.model;

import java.util.Arrays;

/**
 * Objeto de dominio inmutable que encapsula las lecturas del robot en un instante determinado.
 */
public final class RobotTelemetry {
    private final int[] ldrValues;
    private final double ldrAverage;
    private final LightDirection primaryLightDirection;
    private final int servoPitchAngle;
    private final int servoYawAngle;
    private final int polarityReversalsCount;
    private final MotorState motorDirection;
    private final double operatingVoltage;
    private final int batteryLevelPercent;
    private final long timestamp;
    private final String tagUid;

    public RobotTelemetry(int[] ldrValues, double ldrAverage, LightDirection primaryLightDirection,
                          int servoPitchAngle, int servoYawAngle, int polarityReversalsCount,
                          MotorState motorDirection, double operatingVoltage, int batteryLevelPercent,
                          long timestamp, String tagUid) {
        this.ldrValues = ldrValues != null ? ldrValues.clone() : new int[0];
        this.ldrAverage = ldrAverage;
        this.primaryLightDirection = primaryLightDirection;
        this.servoPitchAngle = servoPitchAngle;
        this.servoYawAngle = servoYawAngle;
        this.polarityReversalsCount = polarityReversalsCount;
        this.motorDirection = motorDirection;
        this.operatingVoltage = operatingVoltage;
        this.batteryLevelPercent = batteryLevelPercent;
        this.timestamp = timestamp;
        this.tagUid = tagUid;
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

    public long getTimestamp() {
        return timestamp;
    }

    public String getTagUid() {
        return tagUid;
    }

    @Override
    public String toString() {
        return "RobotTelemetry{" +
                "tagUid='" + tagUid + '\'' +
                ", ldrAverage=" + ldrAverage +
                ", primaryLightDirection=" + primaryLightDirection +
                ", servoPitch=" + servoPitchAngle +
                "°, servoYaw=" + servoYawAngle +
                "°, voltage=" + operatingVoltage + "V" +
                ", battery=" + batteryLevelPercent + "%" +
                '}';
    }
}
