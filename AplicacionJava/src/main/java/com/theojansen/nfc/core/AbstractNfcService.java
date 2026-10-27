package com.theojansen.nfc.core;

import com.theojansen.nfc.parser.TheoJansenDataParser;

public abstract class AbstractNfcService {

    protected final TheoJansenDataParser parser;

    public AbstractNfcService(TheoJansenDataParser parser) {
        this.parser = (parser != null) ? parser : new TheoJansenDataParser();
    }

    public TheoJansenDataParser getParser() {
        return parser;
    }

    public abstract void initializeReader(String preferredTerminalName) throws NfcDeviceException;

    public abstract void startContinuousScan(NfcEventListener listener);

    public abstract void stopContinuousScan();

    public abstract boolean isScanningActive();

    public abstract boolean isReaderAvailable();
}
