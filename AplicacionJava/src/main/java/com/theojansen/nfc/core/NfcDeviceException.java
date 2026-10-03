package com.theojansen.nfc.core;

public class NfcDeviceException extends Exception {
    public NfcDeviceException(String message, Throwable cause) {
        super(message, cause);
    }

    public NfcDeviceException(String message) {
        super(message);
    }
}
