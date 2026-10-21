package com.theojansen.nfc.core;

import com.theojansen.nfc.model.RobotTelemetry;
import org.junit.jupiter.api.Test;
import javax.smartcardio.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import static org.junit.jupiter.api.Assertions.*;

class NfcServiceManagerTest {
    @Test
    void missingReaderReportsErrorWithoutStartingWorker() {
        NfcServiceManager manager = new NfcServiceManager();
        AtomicInteger errors = new AtomicInteger();
        manager.startContinuousScan(new NfcEventListener() {
            public void onTelemetryReceived(RobotTelemetry telemetry) { fail("Unexpected telemetry"); }
            public void onErrorEncountered(Exception error) { errors.incrementAndGet(); }
        });
        assertEquals(1, errors.get());
        assertFalse(manager.isScanningActive());
    }

    @Test
    void disconnectedReaderDoesNotFloodTheUi() throws Exception {
        CardTerminal reader = new CardTerminal() {
            public String getName() { return "disconnected"; }
            public Card connect(String protocol) throws CardException { throw new CardException("offline"); }
            public boolean isCardPresent() { return true; }
            public boolean waitForCardPresent(long timeout) { return true; }
            public boolean waitForCardAbsent(long timeout) { return false; }
        };
        NfcServiceManager manager = new NfcServiceManager(reader);
        AtomicInteger errors = new AtomicInteger();
        CountDownLatch firstError = new CountDownLatch(1);
        try {
            manager.startContinuousScan(new NfcEventListener() {
                public void onTelemetryReceived(RobotTelemetry telemetry) { }
                public void onErrorEncountered(Exception error) {
                    errors.incrementAndGet();
                    firstError.countDown();
                }
            });
            assertTrue(firstError.await(2, TimeUnit.SECONDS));
            Thread.sleep(100);
            assertEquals(1, errors.get());
        } finally {
            manager.stopContinuousScan();
        }
        assertFalse(manager.isScanningActive());
    }
}
