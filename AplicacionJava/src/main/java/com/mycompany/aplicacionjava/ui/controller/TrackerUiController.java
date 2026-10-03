package com.mycompany.aplicacionjava.ui.controller;

import com.theojansen.nfc.core.NfcEventListener;
import com.theojansen.nfc.model.RobotTelemetry;
import com.mycompany.aplicacionjava.MainTrackerFrame;

import javax.swing.SwingUtilities;

/**
 * Controlador intermediario que recibe eventos del hilo de fondo de Jenny
 * (NfcServiceManager) y despacha las actualizaciones a la interfaz gráfica,
 * garantizando que toda modificación visual ocurra en el EDT (Event Dispatch Thread).
 */
public class TrackerUiController implements NfcEventListener {

    private final MainTrackerFrame mainFrame;

    public TrackerUiController(MainTrackerFrame mainFrame) {
        this.mainFrame = mainFrame;
    }

    /**
     * Captura el evento asíncrono (llega en el hilo de escaneo de Jenny)
     * y delega la actualización visual al hilo de eventos de Swing.
     */
    @Override
    public void onTelemetryReceived(RobotTelemetry telemetry) {
        // Protección estricta del hilo de interfaz gráfica (EDT)
        SwingUtilities.invokeLater(() -> {
            mainFrame.updateDashboard(telemetry);
        });
    }

    /**
     * Muestra alertas en pantalla (ej. desconexión del lector, trama corrupta o fallos de APDU)
     * mediante diálogos no bloqueantes en el EDT.
     */
    @Override
    public void onErrorEncountered(Exception ex) {
        SwingUtilities.invokeLater(() -> {
            mainFrame.showDeviceError(ex.getMessage() != null ? ex.getMessage() : ex.toString());
        });
    }
}