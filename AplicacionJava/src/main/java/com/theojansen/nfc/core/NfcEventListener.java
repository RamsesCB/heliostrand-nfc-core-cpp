package com.theojansen.nfc.core;

import com.theojansen.nfc.model.RobotTelemetry;

public interface NfcEventListener {
    void onTelemetryReceived(RobotTelemetry telemetry);
    void onErrorEncountered(Exception ex);
}
