package com.ramsescb.heliostrand.desktop;

import com.formdev.flatlaf.FlatLightLaf;
import com.theojansen.nfc.core.NfcServiceManager;
import com.ramsescb.heliostrand.desktop.ui.controller.TrackerUiController;

import javax.swing.SwingUtilities;

/**
 * Punto de entrada principal de la aplicación de escritorio Java Swing.
 * Aplica el tema visual FlatLaf e inicializa el controlador con el gestor NFC de hardware.
 */
public class Main {

    public static void main(String[] args) {
        // 1. Configurar el tema visual moderno FlatLaf antes de abrir la ventana.
        FlatLightLaf.setup();

        SwingUtilities.invokeLater(() -> {
            MainTrackerFrame frame = new MainTrackerFrame();
            TrackerUiController controller = new TrackerUiController(frame);
            NfcServiceManager nfcManager = new NfcServiceManager();

            // 2. Conectar el gestor NFC y el controlador de UI con el frame
            frame.initController(nfcManager, controller);

            // 3. Hacer visible la interfaz gráfica
            frame.setVisible(true);
        });
    }
}