package com.ramsescb.heliostrand.desktop;

import com.ramsescb.heliostrand.desktop.ui.controller.TrackerUiController;
import com.theojansen.nfc.core.NfcDeviceException;
import com.theojansen.nfc.core.NfcEventListener;
import com.theojansen.nfc.core.NfcServiceManager;
import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;

import javax.swing.SwingUtilities;
import javax.swing.SwingWorker;
import java.awt.GraphicsEnvironment;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeFalse;

@Timeout(10)
class MainTrackerFrameSessionTest {
    private RecordingFrame frame;
    private FakeReader reader;

    @BeforeEach
    void createFrame() throws Exception {
        assumeFalse(GraphicsEnvironment.isHeadless(), "Run with xvfb-run to exercise Swing lifecycle");
        reader = new FakeReader();
        SwingUtilities.invokeAndWait(() -> {
            frame = new RecordingFrame();
            frame.addNotify();
            frame.initController(reader, new TrackerUiController(frame));
        });
    }

    @AfterEach
    void disposeFrame() throws Exception {
        if (frame != null) SwingUtilities.invokeAndWait(frame::dispose);
    }

    @Test
    void startingSimulationStopsAnActiveReaderAndPauseStopsBoth() throws Exception {
        reader.active = true;
        SwingUtilities.invokeAndWait(() -> {
            frame.toggleSimulation();
            assertFalse(reader.active);
            assertTrue(flag("simulationActive"));
            assertTrue(flag("scanning"));
            frame.toggleSimulation();
            assertFalse(flag("simulationActive"));
            assertFalse(flag("scanning"));
        });
    }

    @Test
    void startingNfcStopsSimulationAndLateInitializationCannotRestartIt() throws Exception {
        CountDownLatch workerDone = new CountDownLatch(1);
        SwingUtilities.invokeAndWait(() -> {
            frame.toggleSimulation();
            invoke("startScanningProcess");
            assertFalse(flag("simulationActive"));
            SwingWorker<?, ?> worker = (SwingWorker<?, ?>) field("initializationWorker");
            worker.addPropertyChangeListener(event -> {
                if (event.getNewValue() == SwingWorker.StateValue.DONE) workerDone.countDown();
            });
        });
        assertTrue(reader.entered.await(2, TimeUnit.SECONDS));
        SwingUtilities.invokeAndWait(frame::toggleSimulation);
        assertTrue(reader.finished.await(2, TimeUnit.SECONDS));
        assertTrue(workerDone.await(2, TimeUnit.SECONDS));
        SwingUtilities.invokeAndWait(() -> {
            assertTrue(flag("simulationActive"));
            assertEquals(0, reader.starts.get());
            assertFalse(reader.active);
        });
    }

    @Test
    void queuedEventsFromAnOldSessionAreDiscardedOnTheEdt() throws Exception {
        AtomicBoolean current = new AtomicBoolean(true);
        TrackerUiController controller = new TrackerUiController(frame).scoped(current::get);
        RobotTelemetry telemetry = new RobotTelemetry(2, 1, new int[]{1, 2, 3, 4}, 2.5,
                LightDirection.NORTE, 90, 90, 0, MotorState.DETENIDO, 3.7, 50, true, 0L, "TEST");
        SwingUtilities.invokeAndWait(() -> {
            controller.onTelemetryReceived(telemetry);
            controller.onErrorEncountered(new Exception("old reader"));
            current.set(false);
        });
        SwingUtilities.invokeAndWait(() -> {
            assertEquals(0, frame.samples);
            assertEquals(0, frame.errors);
            current.set(true);
            controller.onTelemetryReceived(telemetry);
        });
        SwingUtilities.invokeAndWait(() -> assertEquals(1, frame.samples));
    }

    private boolean flag(String name) { return (boolean) field(name); }

    private Object field(String name) {
        try {
            Field field = MainTrackerFrame.class.getDeclaredField(name);
            field.setAccessible(true);
            return field.get(frame);
        } catch (ReflectiveOperationException ex) { throw new AssertionError(ex); }
    }

    private void invoke(String name) {
        try {
            Method method = MainTrackerFrame.class.getDeclaredMethod(name);
            method.setAccessible(true);
            method.invoke(frame);
        } catch (ReflectiveOperationException ex) { throw new AssertionError(ex); }
    }

    private static final class RecordingFrame extends MainTrackerFrame {
        int samples;
        int errors;
        @Override public void updateDashboard(RobotTelemetry telemetry) { samples++; }
        @Override public void showDeviceError(String message) { errors++; }
    }

    private static final class FakeReader extends NfcServiceManager {
        final CountDownLatch entered = new CountDownLatch(1);
        final CountDownLatch finished = new CountDownLatch(1);
        final AtomicInteger starts = new AtomicInteger();
        volatile boolean active;
        @Override public void initializeReader(String preferredTerminalName) throws NfcDeviceException {
            entered.countDown();
            try {
                new CountDownLatch(1).await(5, TimeUnit.SECONDS);
            } catch (InterruptedException ex) {
                Thread.currentThread().interrupt();
            } finally { finished.countDown(); }
        }
        @Override public void startContinuousScan(NfcEventListener listener) {
            starts.incrementAndGet();
            active = true;
        }
        @Override public void stopContinuousScan() { active = false; }
    }
}
