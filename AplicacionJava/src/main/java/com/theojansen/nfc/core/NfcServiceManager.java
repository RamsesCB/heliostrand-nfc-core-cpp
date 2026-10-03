package com.theojansen.nfc.core;

import com.theojansen.nfc.model.RobotTelemetry;
import com.theojansen.nfc.parser.TheoJansenDataParser;

import javax.smartcardio.*;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Gestor del hardware NFC mediante el estándar PC/SC (javax.smartcardio).
 */
public class NfcServiceManager {

    private final TheoJansenDataParser parser;
    private CardTerminal terminal;
    private ExecutorService executorService;
    private volatile boolean scanningActive = false;

    public NfcServiceManager() {
        this.parser = new TheoJansenDataParser();
    }

    public void initializeReader(String preferredTerminalName) throws NfcDeviceException {
        try {
            TerminalFactory factory = TerminalFactory.getDefault();
            List<CardTerminal> terminals = factory.terminals().list();

            if (terminals.isEmpty()) {
                throw new NfcDeviceException("No se detectaron lectores NFC PC/SC conectados por USB.");
            }

            if (preferredTerminalName != null && !preferredTerminalName.isEmpty()) {
                for (CardTerminal t : terminals) {
                    if (t.getName().contains(preferredTerminalName)) {
                        this.terminal = t;
                        break;
                    }
                }
            }

            if (this.terminal == null) {
                this.terminal = terminals.get(0); // Tomar el primer lector disponible
            }
        } catch (CardException e) {
            throw new NfcDeviceException("Error al inicializar la subcapa de tarjeta inteligente PC/SC.", e);
        }
    }

    public void startContinuousScan(NfcEventListener listener) {
        if (scanningActive) return;

        scanningActive = true;
        executorService = Executors.newSingleThreadExecutor();

        executorService.submit(() -> {
            while (scanningActive) {
                try {
                    if (terminal != null && terminal.waitForCardPresent(1000)) {
                        Card card = terminal.connect("*");
                        CardChannel channel = card.getBasicChannel();

                        // UID del Tag NFC
                        byte[] uidBytes = card.getATR().getBytes();
                        String tagUid = bytesToHex(uidBytes);

                        // Lectura APDU
                        byte[] rawPayload = readRawTelemetryBlocks(channel);

                        // Parseo de telemetría
                        RobotTelemetry telemetry = parser.decodeTelemetryPayload(rawPayload, tagUid);

                        if (listener != null) {
                            listener.onTelemetryReceived(telemetry);
                        }

                        terminal.waitForCardAbsent(2000);
                        card.disconnect(false);
                    }
                } catch (Exception e) {
                    if (scanningActive && listener != null) {
                        listener.onErrorEncountered(e);
                    }
                }
            }
        });
    }

    public void stopContinuousScan() {
        scanningActive = false;
        if (executorService != null && !executorService.isShutdown()) {
            executorService.shutdownNow();
        }
    }

    private byte[] readRawTelemetryBlocks(CardChannel channel) throws CardException {
        // Comando APDU genérico de lectura de bloque de memoria (FF B0 00 [Block] [Length])
        CommandAPDU readCommand = new CommandAPDU(0xFF, 0xB0, 0x00, 0x04, 12);
        ResponseAPDU response = channel.transmit(readCommand);

        if (response.getSW() == 0x9000) {
            return response.getData();
        } else {
            throw new CardException("Fallo al ejecutar APDU de lectura. Status Word: " + Integer.toHexString(response.getSW()));
        }
    }

    public boolean isReaderConnected() {
        try {
            return terminal != null && terminal.isCardPresent();
        } catch (CardException e) {
            return false;
        }
    }

    public boolean isScanningActive() {
        return scanningActive;
    }

    public CardTerminal getTerminal() {
        return terminal;
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }
}
