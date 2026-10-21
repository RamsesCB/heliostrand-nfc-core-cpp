package com.ramsescb.heliostrand.desktop.ui.controller;

import com.theojansen.nfc.core.NfcEventListener;
import com.theojansen.nfc.model.RobotTelemetry;
import com.ramsescb.heliostrand.desktop.MainTrackerFrame;

import javax.swing.SwingUtilities;

public class TrackerUiController implements NfcEventListener {

    private final MainTrackerFrame mainFrame;

    public TrackerUiController(MainTrackerFrame mainFrame) {
        this.mainFrame = mainFrame;
    }

    @Override
    public void onTelemetryReceived(RobotTelemetry telemetry) {

        SwingUtilities.invokeLater(() -> {
            mainFrame.updateDashboard(telemetry);
        });
    }

    @Override
    public void onErrorEncountered(Exception ex) {
        SwingUtilities.invokeLater(() -> {
            mainFrame.showDeviceError(ex.getMessage() != null ? ex.getMessage() : ex.toString());
        });
    }
}
