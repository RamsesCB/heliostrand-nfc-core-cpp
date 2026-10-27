package com.ramsescb.heliostrand.desktop;

import com.formdev.flatlaf.FlatLightLaf;
import com.theojansen.nfc.core.NfcServiceManager;
import com.ramsescb.heliostrand.desktop.ui.controller.TrackerUiController;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import java.awt.Dimension;
import java.util.logging.Level;
import java.util.logging.Logger;

public class Main {

    private static final Logger logger = Logger.getLogger(Main.class.getName());

    public static void main(String[] args) {
        try {

            UIManager.put("Button.arc", 10);
            UIManager.put("Component.arc", 10);
            UIManager.put("ProgressBar.arc", 10);
            UIManager.put("TextComponent.arc", 8);
            UIManager.put("ScrollBar.showButtons", false);
            UIManager.put("ScrollBar.width", 12);
            UIManager.put("Table.rowHeight", 28);
            UIManager.put("Table.intercellSpacing", new Dimension(0, 1));
            UIManager.put("Table.showHorizontalLines", true);
            UIManager.put("Table.showVerticalLines", false);

            FlatLightLaf.setup();
        } catch (Throwable t) {
            logger.log(Level.WARNING, "No se pudo inicializar FlatLightLaf; se usará el Look and Feel por defecto.", t);
        }

        SwingUtilities.invokeLater(() -> {
            try {
                MainTrackerFrame frame = new MainTrackerFrame();
                TrackerUiController controller = new TrackerUiController(frame);
                NfcServiceManager nfcManager = new NfcServiceManager();

                frame.initController(nfcManager, controller);
                frame.setVisible(true);

                if (args != null) {
                    for (String arg : args) {
                        if ("--darcula".equalsIgnoreCase(arg)) {
                            frame.changeTheme(1);
                        } else if ("--dark".equalsIgnoreCase(arg)) {
                            frame.changeTheme(2);
                        } else if ("--arc-dark".equalsIgnoreCase(arg)) {
                            frame.changeTheme(3);
                        }
                        if ("--simulate".equalsIgnoreCase(arg) || "-s".equalsIgnoreCase(arg) || "--sim".equalsIgnoreCase(arg)) {
                            frame.toggleSimulation();
                        }
                    }
                }
            } catch (Throwable t) {
                logger.log(Level.SEVERE, "Error crítico al inicializar la ventana principal", t);
            }
        });
    }
}
