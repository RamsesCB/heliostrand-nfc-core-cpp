package com.theojansen.nfc.parser;

/**
 * Excepción lanzada cuando la trama tiene CRC válido pero viola límites físicos admisibles.
 */
public class InvalidTelemetryException extends Exception {
    public InvalidTelemetryException(String message) {
        super(message);
    }
}
