package com.theojansen.nfc.parser;

public class UnsupportedProtocolVersionException extends InvalidTelemetryException {
    private final int receivedVersion;

    public UnsupportedProtocolVersionException(int receivedVersion) {
        super("Versión de protocolo no soportada: " + receivedVersion
                + ". Este cliente acepta únicamente V2.");
        this.receivedVersion = receivedVersion;
    }

    public int getReceivedVersion() {
        return receivedVersion;
    }
}
