package com.ramsescb.heliostrand.desktop;

import com.formdev.flatlaf.FlatLightLaf;
import com.theojansen.nfc.core.NfcServiceManager;
import com.ramsescb.heliostrand.desktop.ui.controller.TrackerUiController;

import javax.swing.SwingUtilities;

public class Main {

    public static void main(String[] args) {

        FlatLightLaf.setup();

        SwingUtilities.invokeLater(() -> {
            MainTrackerFrame frame = new MainTrackerFrame();
            TrackerUiController controller = new TrackerUiController(frame);
            NfcServiceManager nfcManager = new NfcServiceManager();

            frame.initController(nfcManager, controller);

            frame.setVisible(true);
        });
    }
}
