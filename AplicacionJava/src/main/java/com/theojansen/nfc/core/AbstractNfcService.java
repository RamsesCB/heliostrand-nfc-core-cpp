package com.theojansen.nfc.core;

import com.theojansen.nfc.parser.TheoJansenDataParser;

/**
 * Clase abstracta base para los servicios de adquisición y escaneo NFC.
 * Define el contrato del ciclo de vida del lector y la suscripción a eventos.
 */
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
