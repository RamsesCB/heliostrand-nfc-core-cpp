package com.ramsescb.heliostrand.desktop;

import com.theojansen.nfc.core.NfcDeviceException;
import com.theojansen.nfc.core.NfcServiceManager;
import com.theojansen.nfc.model.LightDirection;
import com.theojansen.nfc.model.MotorState;
import com.theojansen.nfc.model.RobotTelemetry;
import com.ramsescb.heliostrand.desktop.ui.controller.TrackerUiController;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.formdev.flatlaf.FlatLaf;
import com.formdev.flatlaf.FlatLightLaf;
import com.formdev.flatlaf.FlatDarkLaf;
import com.formdev.flatlaf.FlatDarculaLaf;
import com.formdev.flatlaf.intellijthemes.FlatArcDarkIJTheme;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.chart.renderer.category.StandardBarPainter;
import org.jfree.data.category.DefaultCategoryDataset;

import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JProgressBar;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.SwingConstants;
import javax.swing.SwingWorker;
import javax.swing.UIManager;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.Paint;
import java.io.FileWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Random;
import java.util.concurrent.ExecutionException;

public class MainTrackerFrame extends JFrame {

    private static final java.util.logging.Logger logger =
            java.util.logging.Logger.getLogger(MainTrackerFrame.class.getName());

    private static final int MAX_IN_MEMORY_SAMPLES = 500;

    private JButton btnToggleScan;
    private JButton btnToggleSimulate;
    private JButton btnExportReport;
    private JButton btnClearHistory;
    private JComboBox<String> comboThemes;
    private JLabel lblStatusBadge;

    private JProgressBar barPitch;
    private JProgressBar barYaw;
    private JLabel lblMotorState;
    private JLabel lblReversalsCount;
    private JLabel lblVoltage;
    private JProgressBar barBattery;

    private JPanel chartContainerPanel;
    private JTable historyTable;
    private DefaultCategoryDataset ldrDataset;
    private JFreeChart ldrChart;
    private ChartPanel chartPanel;

    private boolean scanning = false;
    private volatile long acquisitionGeneration;
    private SwingWorker<Void, Void> initializationWorker;
    private final List<RobotTelemetry> sessionHistory = new ArrayList<>();
    private final SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");

    private static final int LDR_SAMPLE_COUNT = 5;
    private static final String[] LDR_SERIES_LABELS = {
            "Muestra 1 (t-4)",
            "Muestra 2 (t-3)",
            "Muestra 3 (t-2)",
            "Muestra 4 (t-1)",
            "Muestra 5 (Actual)"
    };
    private final List<int[]> ldrSampleHistory = new ArrayList<>();

    private void initLdrHistory() {
        synchronized (ldrSampleHistory) {
            ldrSampleHistory.clear();
            for (int i = 0; i < LDR_SAMPLE_COUNT; i++) {
                ldrSampleHistory.add(new int[]{0, 0, 0, 0});
            }
        }
    }

    private NfcServiceManager nfcServiceManager;
    private TrackerUiController uiController;
    private Thread simulationThread;
    private volatile boolean simulationActive = false;
    private javax.swing.JDialog errorDialog;

    public MainTrackerFrame() {
        setTitle("Heliostrand · Solar Tracker & Telemetría NFC");
        setupWindowIcon();
        initComponents();
        setupCharts();
        applyModernStyles();

        setSize(1120, 880);
        setMinimumSize(new Dimension(980, 750));
        setLocationRelativeTo(null);
    }

    private void setupWindowIcon() {
        try {
            java.net.URL iconUrl = getClass().getResource("/icons/logo_robot_64.png");
            if (iconUrl != null) {
                setIconImage(new ImageIcon(iconUrl).getImage());
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "No se pudo cargar el icono de la ventana", ex);
        }
    }

    private void initComponents() {
        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        JPanel rootPanel = new JPanel(new BorderLayout(0, 10));
        rootPanel.setBorder(BorderFactory.createEmptyBorder(12, 14, 12, 14));
        setContentPane(rootPanel);

        JPanel northContainer = new JPanel();
        northContainer.setLayout(new BoxLayout(northContainer, BoxLayout.Y_AXIS));

        northContainer.add(createHeaderPanel());
        northContainer.add(Box.createVerticalStrut(10));
        northContainer.add(createToolBarPanel());
        northContainer.add(Box.createVerticalStrut(12));
        northContainer.add(createMetricsPanel());

        rootPanel.add(northContainer, BorderLayout.NORTH);

        JPanel centerPanel = new JPanel(new GridLayout(2, 1, 0, 12));

        chartContainerPanel = new JPanel(new BorderLayout());
        chartContainerPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(0xE2, 0xE8, 0xF0)),
                "Sensores LDR (Norte / Sur / Este / Oeste) - Historial de Muestras (Ventana de 5 Lecturas)",
                javax.swing.border.TitledBorder.DEFAULT_JUSTIFICATION,
                javax.swing.border.TitledBorder.DEFAULT_POSITION,
                new Font("Segoe UI", Font.BOLD, 13)
        ));
        centerPanel.add(chartContainerPanel);

        historyTable = new JTable();
        historyTable.setModel(new DefaultTableModel(
                new Object[][]{},
                new String[]{
                        "Hora", "Voltaje (V)", "Batería (%)", "Pitch", "Yaw", "LDR Dominante", "Motor", "Tag UID"
                }
        ) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        });

        JScrollPane scrollTable = new JScrollPane(historyTable);
        scrollTable.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(0xE2, 0xE8, 0xF0)),
                "Historial de Telemetría (Últimas Muestras)",
                javax.swing.border.TitledBorder.DEFAULT_JUSTIFICATION,
                javax.swing.border.TitledBorder.DEFAULT_POSITION,
                new Font("Segoe UI", Font.BOLD, 13)
        ));
        centerPanel.add(scrollTable);

        rootPanel.add(centerPanel, BorderLayout.CENTER);
    }

    private JPanel createHeaderPanel() {
        JPanel header = new JPanel(new BorderLayout(15, 0));
        header.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(0, 0, 1, 0, new Color(0xE2, 0xE8, 0xF0)),
                BorderFactory.createEmptyBorder(6, 6, 12, 6)
        ));

        JPanel titlePanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 12, 0));

        JLabel lblLogo = new JLabel();
        try {
            java.net.URL logoUrl = getClass().getResource("/icons/logo_robot_64.png");
            if (logoUrl != null) {
                ImageIcon original = new ImageIcon(logoUrl);
                Image scaled = original.getImage().getScaledInstance(48, 48, Image.SCALE_SMOOTH);
                lblLogo.setIcon(new ImageIcon(scaled));
            }
        } catch (Exception e) {
            logger.log(java.util.logging.Level.FINE, "Logo no disponible", e);
        }
        titlePanel.add(lblLogo);

        JPanel textTitles = new JPanel(new GridLayout(2, 1, 0, 2));
        JLabel lblTitle = new JLabel("Solar Tracker");
        lblTitle.setFont(new Font("Segoe UI", Font.BOLD, 20));

        JLabel lblSub = new JLabel("Heliostrand · Theo Jansen Robotics · Telemetría NFC V2");
        lblSub.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblSub.setForeground(new Color(0x64, 0x74, 0x8B));

        textTitles.add(lblTitle);
        textTitles.add(lblSub);
        titlePanel.add(textTitles);

        header.add(titlePanel, BorderLayout.WEST);

        JPanel rightPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 8));

        lblStatusBadge = new JLabel("● Lector Inactivo");
        lblStatusBadge.setFont(new Font("Segoe UI", Font.BOLD, 12));
        lblStatusBadge.setForeground(new Color(0x64, 0x74, 0x8B));
        rightPanel.add(lblStatusBadge);

        comboThemes = new JComboBox<>(new String[]{
                "☀️ Tema Claro",
                "🌙 Tema Darcula",
                "🌑 Tema Oscuro",
                "🎨 Arc Dark"
        });
        comboThemes.setSelectedIndex(0);
        comboThemes.setFocusable(false);
        comboThemes.putClientProperty("JComponent.roundRect", true);
        comboThemes.addActionListener(e -> changeTheme(comboThemes.getSelectedIndex()));
        rightPanel.add(comboThemes);

        header.add(rightPanel, BorderLayout.EAST);
        return header;
    }

    private JPanel createToolBarPanel() {
        JPanel toolBarPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 0));

        btnToggleScan = new JButton("▶ Iniciar Escaneo");
        btnToggleScan.setFont(new Font("Segoe UI", Font.BOLD, 13));
        btnToggleScan.putClientProperty("JButton.buttonType", "roundRect");
        btnToggleScan.addActionListener(this::btnToggleScanActionPerformed);
        toolBarPanel.add(btnToggleScan);

        btnToggleSimulate = new JButton("⚡ Simular Telemetría");
        btnToggleSimulate.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        btnToggleSimulate.putClientProperty("JButton.buttonType", "roundRect");
        btnToggleSimulate.addActionListener(e -> toggleSimulation());
        toolBarPanel.add(btnToggleSimulate);

        btnExportReport = new JButton("💾 Exportar Reporte (JSON)");
        btnExportReport.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        btnExportReport.putClientProperty("JButton.buttonType", "roundRect");
        btnExportReport.addActionListener(this::btnExportReportActionPerformed);
        toolBarPanel.add(btnExportReport);

        btnClearHistory = new JButton("🗑 Limpiar Historial");
        btnClearHistory.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        btnClearHistory.putClientProperty("JButton.buttonType", "roundRect");
        btnClearHistory.addActionListener(e -> clearHistory());
        toolBarPanel.add(btnClearHistory);

        return toolBarPanel;
    }

    private JPanel createMetricsPanel() {
        JPanel topMetricsPanel = new JPanel(new GridLayout(1, 3, 14, 0));

        JPanel servoPanel = new JPanel(new GridLayout(2, 2, 8, 8));
        servoPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(0xE2, 0xE8, 0xF0)),
                "Servomotores Biaxiales",
                javax.swing.border.TitledBorder.DEFAULT_JUSTIFICATION,
                javax.swing.border.TitledBorder.DEFAULT_POSITION,
                new Font("Segoe UI", Font.BOLD, 12)
        ));

        JLabel jLabel1 = new JLabel("Pitch (Vertical):");
        jLabel1.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        servoPanel.add(jLabel1);

        barPitch = new JProgressBar(0, 180);
        barPitch.setStringPainted(true);
        barPitch.setValue(90);
        barPitch.setString("90°");
        barPitch.setForeground(new Color(0xD9, 0x77, 0x06));
        servoPanel.add(barPitch);

        JLabel jLabel2 = new JLabel("Yaw (Horizontal):");
        jLabel2.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        servoPanel.add(jLabel2);

        barYaw = new JProgressBar(0, 180);
        barYaw.setStringPainted(true);
        barYaw.setValue(90);
        barYaw.setString("90°");
        barYaw.setForeground(new Color(0x02, 0x84, 0xC7));
        servoPanel.add(barYaw);

        topMetricsPanel.add(servoPanel);

        JPanel motorPolarityPanel = new JPanel(new GridLayout(2, 1, 4, 4));
        motorPolarityPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(0xE2, 0xE8, 0xF0)),
                "Cinemática Theo Jansen",
                javax.swing.border.TitledBorder.DEFAULT_JUSTIFICATION,
                javax.swing.border.TitledBorder.DEFAULT_POSITION,
                new Font("Segoe UI", Font.BOLD, 12)
        ));

        lblMotorState = new JLabel("DETENIDO", SwingConstants.CENTER);
        lblMotorState.setFont(new Font("Segoe UI", Font.BOLD, 16));
        lblMotorState.setForeground(new Color(0x64, 0x74, 0x8B));
        motorPolarityPanel.add(lblMotorState);

        lblReversalsCount = new JLabel("Inversiones de Marcha: 0", SwingConstants.CENTER);
        lblReversalsCount.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        motorPolarityPanel.add(lblReversalsCount);

        topMetricsPanel.add(motorPolarityPanel);

        JPanel powerPanel = new JPanel(new GridLayout(2, 2, 8, 8));
        powerPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(0xE2, 0xE8, 0xF0)),
                "Alimentación y Batería",
                javax.swing.border.TitledBorder.DEFAULT_JUSTIFICATION,
                javax.swing.border.TitledBorder.DEFAULT_POSITION,
                new Font("Segoe UI", Font.BOLD, 12)
        ));

        JLabel lblVoltTitle = new JLabel("Voltaje Operativo:");
        lblVoltTitle.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        powerPanel.add(lblVoltTitle);

        lblVoltage = new JLabel("0.00 V");
        lblVoltage.setFont(new Font("Segoe UI", Font.BOLD, 15));
        powerPanel.add(lblVoltage);

        JLabel lblBatTitle = new JLabel("Batería Li-ion 1S:");
        lblBatTitle.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        powerPanel.add(lblBatTitle);

        barBattery = new JProgressBar(0, 100);
        barBattery.setStringPainted(true);
        barBattery.setValue(0);
        barBattery.setString("N/D");
        barBattery.setForeground(new Color(0x10, 0xB9, 0x81));
        powerPanel.add(barBattery);

        topMetricsPanel.add(powerPanel);
        return topMetricsPanel;
    }

    private void applyModernStyles() {
        try {
            historyTable.setRowHeight(28);
            historyTable.setFont(new Font("Segoe UI", Font.PLAIN, 12));
            historyTable.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 12));

            DefaultTableCellRenderer centerRenderer = new DefaultTableCellRenderer();
            centerRenderer.setHorizontalAlignment(SwingConstants.CENTER);
            for (int i = 0; i < historyTable.getColumnCount(); i++) {
                historyTable.getColumnModel().getColumn(i).setCellRenderer(centerRenderer);
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "Error al configurar tabla moderna", ex);
        }
    }

    public void changeTheme(int index) {
        try {
            if (comboThemes != null && comboThemes.getSelectedIndex() != index) {
                comboThemes.setSelectedIndex(index);
            }
            if (index == 0) {
                FlatLightLaf.setup();
            } else if (index == 1) {
                FlatDarculaLaf.setup();
            } else if (index == 2) {
                FlatDarkLaf.setup();
            } else if (index == 3) {
                FlatArcDarkIJTheme.setup();
            }
            FlatLaf.updateUI();
            updateChartTheme();
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.SEVERE, "Error al cambiar tema visual", ex);
        }
    }

    private void setupCharts() {
        try {
            initLdrHistory();
            ldrDataset = new DefaultCategoryDataset();
            for (String series : LDR_SERIES_LABELS) {
                ldrDataset.addValue(0, series, "Norte");
                ldrDataset.addValue(0, series, "Sur");
                ldrDataset.addValue(0, series, "Este");
                ldrDataset.addValue(0, series, "Oeste");
            }

            ldrChart = ChartFactory.createBarChart(
                    null, "Sensor LDR", "Lectura ADC (0-255)",
                    ldrDataset, PlotOrientation.VERTICAL,
                    false, true, false);

            chartPanel = new ChartPanel(ldrChart);
            chartPanel.setPreferredSize(new Dimension(600, 260));
            chartContainerPanel.setLayout(new BorderLayout());
            chartContainerPanel.add(chartPanel, BorderLayout.CENTER);

            updateChartTheme();
            chartContainerPanel.revalidate();
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.SEVERE, "Error al configurar componentes JFreeChart", ex);
        }
    }

    private void updateChartTheme() {
        if (ldrChart == null) return;
        try {
            CategoryPlot plot = ldrChart.getCategoryPlot();
            Color bg = UIManager.getColor("Panel.background");
            if (bg == null) bg = Color.WHITE;

            ldrChart.setBackgroundPaint(bg);
            plot.setBackgroundPaint(bg);
            plot.setOutlineVisible(false);

            boolean isDark = FlatLaf.isLafDark();
            Color gridColor = isDark ? new Color(0x33, 0x41, 0x55) : new Color(0xE2, 0xE8, 0xF0);
            Color textColor = isDark ? new Color(0xEA, 0xEE, 0xF6) : new Color(0x1E, 0x29, 0x3B);

            plot.setRangeGridlinePaint(gridColor);
            plot.setDomainGridlinePaint(gridColor);

            plot.getDomainAxis().setTickLabelPaint(textColor);
            plot.getDomainAxis().setLabelPaint(textColor);
            plot.getDomainAxis().setTickLabelFont(new Font("Segoe UI", Font.BOLD, 12));
            plot.getDomainAxis().setCategoryMargin(0.18);

            NumberAxis rangeAxis = (NumberAxis) plot.getRangeAxis();
            rangeAxis.setAutoRange(false);
            rangeAxis.setRange(0.0, 255.0);
            rangeAxis.setTickLabelPaint(textColor);
            rangeAxis.setLabelPaint(textColor);
            rangeAxis.setTickLabelFont(new Font("Segoe UI", Font.PLAIN, 11));

            Color baseColor = isDark ? new Color(0x38, 0xBD, 0xF8) : new Color(0x25, 0x63, 0xEB);
            Color[] sensorBases = new Color[]{baseColor, baseColor, baseColor, baseColor};

            CustomBarRenderer renderer = new CustomBarRenderer(sensorBases);
            plot.setRenderer(renderer);
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "Error al actualizar tema del gráfico", ex);
        }
    }

    public void initController(NfcServiceManager nfcServiceManager, TrackerUiController uiController) {
        this.nfcServiceManager = nfcServiceManager;
        this.uiController = uiController;
    }

    private void btnToggleScanActionPerformed(java.awt.event.ActionEvent evt) {
        if (!scanning) {
            startScanningProcess();
        } else {
            stopScanningProcess();
        }
    }

    private void clearHistory() {
        try {
            sessionHistory.clear();
            DefaultTableModel model = (DefaultTableModel) historyTable.getModel();
            model.setRowCount(0);

            initLdrHistory();
            if (ldrDataset != null) {
                for (String series : LDR_SERIES_LABELS) {
                    ldrDataset.setValue(0, series, "Norte");
                    ldrDataset.setValue(0, series, "Sur");
                    ldrDataset.setValue(0, series, "Este");
                    ldrDataset.setValue(0, series, "Oeste");
                }
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "Error al limpiar historial", ex);
        }
    }

    private void btnExportReportActionPerformed(java.awt.event.ActionEvent evt) {
        try {
            if (sessionHistory.isEmpty()) {
                JOptionPane.showMessageDialog(this, "No hay registros en el historial para exportar.",
                        "Historial vacío", JOptionPane.INFORMATION_MESSAGE);
                return;
            }

            JFileChooser fileChooser = new JFileChooser();
            fileChooser.setSelectedFile(new java.io.File("reporte_telemetria.json"));
            int result = fileChooser.showSaveDialog(this);
            if (result != JFileChooser.APPROVE_OPTION) {
                return;
            }

            final java.io.File destination = fileChooser.getSelectedFile();
            final List<RobotTelemetry> snapshot = List.copyOf(sessionHistory);
            btnExportReport.setEnabled(false);

            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() throws Exception {
                    Gson gson = new GsonBuilder().setPrettyPrinting().create();
                    try (FileWriter writer = new FileWriter(destination, java.nio.charset.StandardCharsets.UTF_8)) {
                        gson.toJson(snapshot, writer);
                    }
                    return null;
                }

                @Override
                protected void done() {
                    btnExportReport.setEnabled(true);
                    try {
                        get();
                        JOptionPane.showMessageDialog(MainTrackerFrame.this,
                                "Reporte exportado correctamente en:\n" + destination.getAbsolutePath(),
                                "Exportación Exitosa", JOptionPane.INFORMATION_MESSAGE);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        showDeviceError("La exportación fue interrumpida.");
                    } catch (ExecutionException e) {
                        showDeviceError("No se pudo guardar el reporte: " +
                                (e.getCause() != null ? e.getCause().getMessage() : e.getMessage()));
                    }
                }
            }.execute();
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.SEVERE, "Error inesperado al preparar exportación", ex);
            showDeviceError("Ocurrió un error inesperado al exportar: " + ex.getMessage());
        }
    }

    private void startScanningProcess() {
        stopScanningProcess();
        final long generation = acquisitionGeneration;
        try {
            if (nfcServiceManager == null) {
                nfcServiceManager = new NfcServiceManager();
            }
            if (uiController == null) {
                uiController = new TrackerUiController(this);
            }

            btnToggleScan.setEnabled(false);
            initializationWorker = new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() throws NfcDeviceException {
                    nfcServiceManager.initializeReader(null);
                    return null;
                }

                @Override
                protected void done() {
                    if (generation != acquisitionGeneration || !isDisplayable()) return;
                    initializationWorker = null;
                    btnToggleScan.setEnabled(true);
                    try {
                        get();
                        nfcServiceManager.startContinuousScan(
                                uiController.scoped(() -> generation == acquisitionGeneration));
                        scanning = true;
                        btnToggleScan.setText("⏸ Pausar Escaneo");
                        lblStatusBadge.setText("● Escaneando NFC");
                        lblStatusBadge.setForeground(new Color(0x16, 0xA3, 0x4A));
                        JOptionPane.showMessageDialog(MainTrackerFrame.this,
                                "Lector NFC inicializado correctamente.\nEscaneando tags en segundo plano...",
                                "NFC Conectado", JOptionPane.INFORMATION_MESSAGE);
                    } catch (InterruptedException ex) {
                        Thread.currentThread().interrupt();
                        showDeviceError("La inicialización fue interrumpida.");
                    } catch (ExecutionException ex) {
                        String errMsg = (ex.getCause() != null) ? ex.getCause().getMessage() : ex.getMessage();
                        int option = JOptionPane.showConfirmDialog(MainTrackerFrame.this,
                                errMsg + "\n\n¿Desea iniciar en MODO SIMULACIÓN para verificar la telemetría en el dashboard?",
                                "Lector NFC no detectado", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                        if (generation != acquisitionGeneration || !isDisplayable()) return;
                        if (option == JOptionPane.YES_OPTION) {
                            startSimulation();
                            scanning = true;
                            btnToggleScan.setText("⏸ Pausar Simulación");
                            lblStatusBadge.setText("● Simulación Activa");
                            lblStatusBadge.setForeground(new Color(0x25, 0x63, 0xEB));
                        } else {
                            scanning = false;
                            btnToggleScan.setText("▶ Iniciar Escaneo");
                            lblStatusBadge.setText("● Lector Inactivo");
                            lblStatusBadge.setForeground(new Color(0x64, 0x74, 0x8B));
                        }
                    } catch (RuntimeException ex) {
                        stopScanningProcess();
                        showDeviceError("No se pudo iniciar el escaneo: " + ex.getMessage());
                    }
                }
            };
            initializationWorker.execute();
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.SEVERE, "Error al iniciar proceso de escaneo", ex);
            stopScanningProcess();
            showDeviceError("No se pudo iniciar el escaneo: " + ex.getMessage());
        }
    }

    private void stopScanningProcess() {
        acquisitionGeneration++;
        if (initializationWorker != null) {
            initializationWorker.cancel(true);
            initializationWorker = null;
        }
        btnToggleScan.setEnabled(true);
        try {
            scanning = false;
            btnToggleScan.setText("▶ Iniciar Escaneo");
            lblStatusBadge.setText("● Pausado");
            lblStatusBadge.setForeground(new Color(0x64, 0x74, 0x8B));

            if (nfcServiceManager != null) {
                nfcServiceManager.stopContinuousScan();
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "Error al detener escaneo", ex);
        } finally {
            stopSimulation();
        }
    }

    public void toggleSimulation() {
        if (simulationActive) {
            stopScanningProcess();
        } else {
            startSimulation();
        }
    }

    private void startSimulation() {
        stopScanningProcess();
        final long generation = acquisitionGeneration;
        if (uiController == null) {
            uiController = new TrackerUiController(this);
        }
        simulationActive = true;
        scanning = true;
        btnToggleScan.setText("⏸ Pausar Simulación");
        btnToggleSimulate.setText("⏸ Pausar Simulación");
        lblStatusBadge.setText("● Simulación Activa");
        lblStatusBadge.setForeground(new Color(0x25, 0x63, 0xEB));
        final TrackerUiController simulationController =
                uiController.scoped(() -> generation == acquisitionGeneration);
        simulationThread = new Thread(() -> {
            Random random = new Random();
            int reversals = 0;
            int sequence = 0;
            final String simulatedUid = "SIM-TAG-DESKTOP-0001";
            MotorState mState = MotorState.ADELANTE;

            while (simulationActive && generation == acquisitionGeneration) {
                try {
                    int[] ldr = {
                            random.nextInt(256),
                            random.nextInt(256),
                            random.nextInt(256),
                            random.nextInt(256)
                    };

                    LightDirection dir;
                    if (random.nextInt(10) == 0) {
                        int balanced = 100 + random.nextInt(40);
                        java.util.Arrays.fill(ldr, balanced);
                        dir = LightDirection.EQUILIBRADO;
                    } else {
                        int maxLdr = Math.max(Math.max(ldr[0], ldr[1]), Math.max(ldr[2], ldr[3]));
                        if (maxLdr == ldr[0]) dir = LightDirection.NORTE;
                        else if (maxLdr == ldr[1]) dir = LightDirection.SUR;
                        else if (maxLdr == ldr[2]) dir = LightDirection.OESTE;
                        else dir = LightDirection.ESTE;
                    }

                    int pitch = 15 + random.nextInt(151);
                    int yaw = 10 + random.nextInt(161);

                    if (random.nextInt(8) == 0) {
                        mState = (mState == MotorState.ADELANTE)
                                ? MotorState.ATRAS : MotorState.ADELANTE;
                        reversals = (reversals + 1) & 0xFF;
                    } else if (random.nextInt(12) == 0) {
                        mState = MotorState.DETENIDO;
                    }

                    int voltageMv = 3200 + random.nextInt(1001);
                    double voltage = voltageMv / 1000.0;
                    int battery = Math.max(0, Math.min(100,
                            ((voltageMv - 3000) * 100) / 1200));

                    RobotTelemetry telemetry = new RobotTelemetry(
                            2,
                            sequence++ & 0xFF,
                            ldr,
                            (ldr[0] + ldr[1] + ldr[2] + ldr[3]) / 4.0,
                            dir,
                            pitch,
                            yaw,
                            reversals,
                            mState,
                            voltage,
                            battery,
                            true,
                            System.currentTimeMillis(),
                            simulatedUid
                    );

                    simulationController.onTelemetryReceived(telemetry);

                    Thread.sleep(1500);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                } catch (Exception loopEx) {
                    logger.log(java.util.logging.Level.WARNING, "Error en ciclo de simulación", loopEx);
                }
            }
        }, "SimulationNfcThread");
        simulationThread.setDaemon(true);
        simulationThread.start();
    }

    private void stopSimulation() {
        try {
            simulationActive = false;
            if (btnToggleSimulate != null) {
                btnToggleSimulate.setText("⚡ Simular Telemetría");
            }
            if (simulationThread != null && simulationThread.isAlive()) {
                simulationThread.interrupt();
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.FINE, "Error al detener hilo de simulación", ex);
        }
    }

    public void updateDashboard(RobotTelemetry telemetry) {
        if (telemetry == null) return;
        try {

            int[] valores = telemetry.getLdrValues();
            if (valores != null && valores.length >= 4 && ldrDataset != null) {

                int[] currentSample = new int[]{valores[0], valores[1], valores[3], valores[2]};

                synchronized (ldrSampleHistory) {
                    if (ldrSampleHistory.size() >= LDR_SAMPLE_COUNT) {
                        ldrSampleHistory.remove(0);
                    }
                    ldrSampleHistory.add(currentSample);

                    for (int i = 0; i < ldrSampleHistory.size(); i++) {
                        int[] sample = ldrSampleHistory.get(i);
                        String series = LDR_SERIES_LABELS[i];
                        ldrDataset.setValue(sample[0], series, "Norte");
                        ldrDataset.setValue(sample[1], series, "Sur");
                        ldrDataset.setValue(sample[2], series, "Este");
                        ldrDataset.setValue(sample[3], series, "Oeste");
                    }
                }
            }

            barPitch.setValue(telemetry.getServoPitchAngle());
            barPitch.setString(telemetry.getServoPitchAngle() + "°");
            barYaw.setValue(telemetry.getServoYawAngle());
            barYaw.setString(telemetry.getServoYawAngle() + "°");

            MotorState motor = telemetry.getMotorDirection();
            if (motor == MotorState.ADELANTE) {
                lblMotorState.setText("▶ ADELANTE");
                lblMotorState.setForeground(new Color(0x16, 0xA3, 0x4A));
            } else if (motor == MotorState.ATRAS) {
                lblMotorState.setText("◀ ATRÁS (INVERSO)");
                lblMotorState.setForeground(new Color(0x25, 0x63, 0xEB));
            } else {
                lblMotorState.setText("■ DETENIDO");
                lblMotorState.setForeground(new Color(0x64, 0x74, 0x8B));
            }
            lblReversalsCount.setText("Inversiones de Marcha: " + telemetry.getPolarityReversalsCount());

            if (telemetry.isBatteryValid()) {
                lblVoltage.setText(String.format(java.util.Locale.US, "%.2f V", telemetry.getOperatingVoltage()));
                int bat = telemetry.getBatteryLevelPercent();
                barBattery.setValue(bat);
                barBattery.setString(bat + "%");
                if (bat > 40) {
                    barBattery.setForeground(new Color(0x10, 0xB9, 0x81));
                } else if (bat >= 20) {
                    barBattery.setForeground(new Color(0xF5, 0x9E, 0x0B));
                } else {
                    barBattery.setForeground(new Color(0xEF, 0x44, 0x44));
                }
            } else {
                lblVoltage.setText("N/D");
                barBattery.setValue(0);
                barBattery.setString("N/D");
                barBattery.setForeground(new Color(0x94, 0xA3, 0xB8));
            }

            DefaultTableModel model = (DefaultTableModel) historyTable.getModel();
            model.addRow(new Object[]{
                    timeFormat.format(new Date(telemetry.getTimestamp())),
                    String.format(java.util.Locale.US, "%.2f", telemetry.getOperatingVoltage()),
                    telemetry.getBatteryLevelPercent() + "%",
                    telemetry.getServoPitchAngle() + "°",
                    telemetry.getServoYawAngle() + "°",
                    telemetry.getPrimaryLightDirection() != null ? telemetry.getPrimaryLightDirection().name() : "N/A",
                    telemetry.getMotorDirection().name(),
                    telemetry.getTagUid() != null ? telemetry.getTagUid() : "-"
            });

            sessionHistory.add(telemetry);
            while (sessionHistory.size() > MAX_IN_MEMORY_SAMPLES) {
                sessionHistory.remove(0);
            }
            while (model.getRowCount() > MAX_IN_MEMORY_SAMPLES) {
                model.removeRow(0);
            }
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "Error al procesar actualización en dashboard", ex);
        }
    }

    public void showDeviceError(String message) {
        try {
            if (errorDialog != null && errorDialog.isShowing()) return;
            JOptionPane pane = new JOptionPane(message, JOptionPane.WARNING_MESSAGE);
            errorDialog = pane.createDialog(this, "Aviso de Dispositivo / NFC");
            errorDialog.setModal(false);
            errorDialog.setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
            errorDialog.setVisible(true);
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.WARNING, "No se pudo desplegar diálogo de error", ex);
        }
    }

    @Override
    public void dispose() {
        try {
            stopScanningProcess();
            if (errorDialog != null) errorDialog.dispose();
        } catch (Exception ex) {
            logger.log(java.util.logging.Level.FINE, "Error durante dispose de MainTrackerFrame", ex);
        } finally {
            super.dispose();
        }
    }

    private static class CustomBarRenderer extends BarRenderer {
        private final Color[] sensorBaseColors;
        private final float[] seriesAlphas = {0.25f, 0.40f, 0.60f, 0.80f, 1.0f};

        public CustomBarRenderer(Color[] sensorBaseColors) {
            this.sensorBaseColors = sensorBaseColors;
            setBarPainter(new StandardBarPainter());
            setShadowVisible(false);
            setDrawBarOutline(false);
            setItemMargin(0.04);
        }

        @Override
        public Paint getItemPaint(int row, int column) {
            Color base = (sensorBaseColors != null && column >= 0 && column < sensorBaseColors.length)
                    ? sensorBaseColors[column]
                    : new Color(0x38, 0xBD, 0xF8);

            float alpha = (row >= 0 && row < seriesAlphas.length) ? seriesAlphas[row] : 1.0f;
            return new Color(
                    base.getRed() / 255.0f,
                    base.getGreen() / 255.0f,
                    base.getBlue() / 255.0f,
                    alpha
            );
        }
    }
}
