package com.theojansen.nfc.core;

import com.theojansen.nfc.model.RobotTelemetry;
import com.theojansen.nfc.parser.TheoJansenDataParser;

import javax.smartcardio.*;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Gestor del hardware NFC mediante el estándar PC/SC (javax.smartcardio).
 * Garantiza cierre seguro de recursos en finally y obtención de UID real mediante APDU FF CA.
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
                Card card = null;
                try {
                    if (terminal != null && terminal.waitForCardPresent(1000)) {
                        card = terminal.connect("*");
                        CardChannel channel = card.getBasicChannel();

                        // UID real del Tag NFC mediante APDU estándar FF CA 00 00 00
                        String tagUid = readRealUid(channel, card);

                        // Lectura de los 12 bytes de telemetría (Páginas 4 a 6)
                        byte[] rawPayload = readRawTelemetryBlocks(channel);

                        // Decodificación y validación de integridad
                        RobotTelemetry telemetry = parser.decodeTelemetryPayload(rawPayload, tagUid);

                        if (listener != null) {
                            listener.onTelemetryReceived(telemetry);
                        }

                        terminal.waitForCardAbsent(2000);
                    }
                } catch (Exception e) {
                    if (scanningActive && listener != null) {
                        listener.onErrorEncountered(e);
                    }
                } finally {
                    if (card != null) {
                        try {
                            card.disconnect(false);
                        } catch (CardException ignored) {
                            // Ignorar error al desconectar tarjeta retirada
                        }
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

    private String readRealUid(CardChannel channel, Card card) {
        try {
            // APDU estándar PC/SC para obtener UID de tarjeta sin contacto (FF CA 00 00 00)
            CommandAPDU getUidCmd = new CommandAPDU(0xFF, 0xCA, 0x00, 0x00, 0x00);
            ResponseAPDU resp = channel.transmit(getUidCmd);
            if (resp.getSW() == 0x9000 && resp.getData().length > 0) {
                return bytesToHex(resp.getData());
            }
        } catch (Exception ignored) {
            // Fallback en lectores que no soportan FF CA
        }

        // Fallback seguro: usar ATR solo si la APDU no responde
        byte[] atrBytes = card.getATR().getBytes();
        return "ATR-" + bytesToHex(atrBytes);
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

    /**
     * Verifica si el terminal USB está reconocido y disponible por el sistema.
     */
    public boolean isReaderAvailable() {
        return terminal != null;
    }

    /**
     * Verifica si hay una tarjeta o tag NFC presente sobre el lector.
     */
    public boolean isTagPresent() {
        try {
            return terminal != null && terminal.isCardPresent();
        } catch (CardException e) {
            return false;
        }
    }

    public boolean isReaderConnected() {
        return isReaderAvailable();
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
