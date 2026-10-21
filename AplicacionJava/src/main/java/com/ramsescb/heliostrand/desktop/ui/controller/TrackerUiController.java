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
        if (telemetry == null || mainFrame == null) return;
        try {
            SwingUtilities.invokeLater(() -> {
                try {
                    mainFrame.updateDashboard(telemetry);
                } catch (Throwable t) {
                    java.util.logging.Logger.getLogger(TrackerUiController.class.getName())
                            .log(java.util.logging.Level.WARNING, "Error al actualizar dashboard en EDT", t);
                }
            });
        } catch (Exception ex) {
            java.util.logging.Logger.getLogger(TrackerUiController.class.getName())
                    .log(java.util.logging.Level.WARNING, "Error al encolar telemetría en EDT", ex);
        }
    }

    @Override
    public void onErrorEncountered(Exception ex) {
        if (mainFrame == null) return;
        try {
            SwingUtilities.invokeLater(() -> {
                try {
                    String msg = (ex != null && ex.getMessage() != null) ? ex.getMessage() : String.valueOf(ex);
                    mainFrame.showDeviceError(msg);
                } catch (Throwable t) {
                    java.util.logging.Logger.getLogger(TrackerUiController.class.getName())
                            .log(java.util.logging.Level.WARNING, "Error al mostrar diálogo de dispositivo", t);
                }
            });
        } catch (Exception dispatchEx) {
            java.util.logging.Logger.getLogger(TrackerUiController.class.getName())
                    .log(java.util.logging.Level.WARNING, "Error al encolar error en EDT", dispatchEx);
        }
    }
}
