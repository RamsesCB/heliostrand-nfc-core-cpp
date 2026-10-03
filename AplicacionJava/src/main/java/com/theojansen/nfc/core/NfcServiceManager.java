package com.theojansen.nfc.core;

import com.theojansen.nfc.model.RobotTelemetry;
import com.theojansen.nfc.parser.TheoJansenDataParser;

import javax.smartcardio.*;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class NfcServiceManager {
    private static final int SLOT_A_BASE_PAGE = 4;
    private static final int SLOT_B_BASE_PAGE = 8;

    private final TheoJansenDataParser parser;
    private final Map<String, Integer> lastSequenceByTag = new ConcurrentHashMap<>();
    private CardTerminal terminal;
    private ExecutorService executorService;
    private volatile boolean scanningActive = false;

    private record NfcSlot(byte[] payload, int generation) {}

    public NfcServiceManager() {
        this.parser = new TheoJansenDataParser();
    }

    public void initializeReader(String preferredTerminalName) throws NfcDeviceException {
        try {
            TerminalFactory factory = TerminalFactory.getDefault();
            List<CardTerminal> terminals = factory.terminals().list();
            if (terminals.isEmpty()) {
                throw new NfcDeviceException("No se detectaron lectores NFC PC/SC.");
            }

            terminal = null;
            if (preferredTerminalName != null && !preferredTerminalName.isBlank()) {
                for (CardTerminal candidate : terminals) {
                    if (candidate.getName().contains(preferredTerminalName)) {
                        terminal = candidate;
                        break;
                    }
                }
            }
            if (terminal == null) terminal = terminals.get(0);
        } catch (CardException e) {
            throw new NfcDeviceException("Error al inicializar PC/SC.", e);
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

                        String tagUid = readRealUid(channel, card);
                        RobotTelemetry telemetry = readLatestTelemetry(channel, tagUid);

                        if (isFreshForTag(telemetry) && listener != null) {
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
                            // Tag may already have left the RF field.
                        }
                    }
                }
            }
        });
    }

    private RobotTelemetry readLatestTelemetry(CardChannel channel, String tagUid)
            throws Exception {
        NfcSlot slotA = readSlot(channel, SLOT_A_BASE_PAGE);
        NfcSlot slotB = readSlot(channel, SLOT_B_BASE_PAGE);

        if (slotA == null && slotB == null) {
            throw new CardException("No existe ningún slot Heliostrand válido en el NTAG213.");
        }

        NfcSlot primary;
        NfcSlot fallback;
        if (slotA == null) {
            primary = slotB;
            fallback = null;
        } else if (slotB == null) {
            primary = slotA;
            fallback = null;
        } else if (generationNewer(slotA.generation(), slotB.generation())) {
            primary = slotA;
            fallback = slotB;
        } else {
            primary = slotB;
            fallback = slotA;
        }

        try {
            return parser.decodeTelemetryPayload(primary.payload(), tagUid);
        } catch (Exception primaryFailure) {
            if (fallback != null) {
                return parser.decodeTelemetryPayload(fallback.payload(), tagUid);
            }
            throw primaryFailure;
        }
    }

    private NfcSlot readSlot(CardChannel channel, int basePage) throws CardException {
        byte[] raw = readPages(channel, basePage);
        if (raw == null || raw.length < 16) return null;

        int magic0 = raw[12] & 0xFF;
        int magic1 = raw[13] & 0xFF;
        int generation = raw[14] & 0xFF;
        int complement = raw[15] & 0xFF;

        if (magic0 != 0x48 || magic1 != 0x53 ||
                complement != ((~generation) & 0xFF)) {
            return null;
        }

        byte[] payload = Arrays.copyOfRange(raw, 0, 12);
        if (!parser.verifyCrc8(payload, payload[11])) return null;
        return new NfcSlot(payload, generation);
    }

    private byte[] readPages(CardChannel channel, int basePage) throws CardException {
        CommandAPDU bulk = new CommandAPDU(0xFF, 0xB0, 0x00, basePage, 16);
        ResponseAPDU response = channel.transmit(bulk);
        if (response.getSW() == 0x9000 && response.getData().length >= 16) {
            return Arrays.copyOf(response.getData(), 16);
        }

        byte[] out = new byte[16];
        for (int page = 0; page < 4; page++) {
            CommandAPDU single =
                    new CommandAPDU(0xFF, 0xB0, 0x00, basePage + page, 4);
            ResponseAPDU part = channel.transmit(single);
            if (part.getSW() != 0x9000 || part.getData().length < 4) {
                return null;
            }
            System.arraycopy(part.getData(), 0, out, page * 4, 4);
        }
        return out;
    }

    private static boolean generationNewer(int candidate, int reference) {
        int diff = (candidate - reference) & 0xFF;
        return diff != 0 && diff < 128;
    }

    private boolean isFreshForTag(RobotTelemetry telemetry) {
        String uid = telemetry.getTagUid();
        int sequence = telemetry.getSequenceNumber();
        Integer previous = lastSequenceByTag.put(uid, sequence);
        return previous == null || previous != sequence;
    }

    public void stopContinuousScan() {
        scanningActive = false;
        if (executorService != null && !executorService.isShutdown()) {
            executorService.shutdownNow();
        }
    }

    private String readRealUid(CardChannel channel, Card card) {
        try {
            CommandAPDU getUidCmd = new CommandAPDU(0xFF, 0xCA, 0x00, 0x00, 0x00);
            ResponseAPDU response = channel.transmit(getUidCmd);
            if (response.getSW() == 0x9000 && response.getData().length > 0) {
                return bytesToHex(response.getData());
            }
        } catch (Exception ignored) {
            // Some PC/SC readers do not implement FF CA.
        }
        return "ATR-" + bytesToHex(card.getATR().getBytes());
    }

    public boolean isReaderAvailable() {
        return terminal != null;
    }

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
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(String.format("%02X", b));
        return sb.toString();
    }
}
