package com.theojansen.nfc.parser;

public class CorruptedPayloadException extends Exception {
    public CorruptedPayloadException(String message) {
        super(message);
    }
}
