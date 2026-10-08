import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/light_direction.dart';
import '../../models/motor_state.dart';
import '../../models/robot_telemetry.dart';
import '../../services/nfc_service.dart';
import '../../services/report_service.dart';
import '../../services/simulation_service.dart';
import '../theme.dart';
import '../widgets/history_card.dart';
import '../widgets/ldr_chart_card.dart';
import '../widgets/motor_battery_card.dart';
import '../widgets/servos_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NfcService _nfcService = NfcService();
  final SimulationService _simulationService = SimulationService();

  RobotTelemetry? _latestTelemetry;
  final List<RobotTelemetry> _history = [];

  StreamSubscription? _telemetrySub;
  StreamSubscription? _simTelemetrySub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;

  String _statusMessage = 'Listo para escanear';
  bool _isScanning = false;
  bool _isSimulationMode = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _addToHistory(RobotTelemetry telemetry) {
    _history.add(telemetry);
    if (_history.length > 500) {
      _history.removeAt(0);
    }
  }

  void _setupListeners() {
    // Escucha de telemetría real NFC
    _telemetrySub = _nfcService.onTelemetryReceived.listen((telemetry) {
      if (!mounted) return;
      setState(() {
        _latestTelemetry = telemetry;
        _addToHistory(telemetry);
        _statusMessage = 'Telemetría NFC recibida (${telemetry.tagUid})';
      });
    });

    // Escucha de simulación
    _simTelemetrySub = _simulationService.telemetryStream.listen((telemetry) {
      if (!mounted) return;
      setState(() {
        _latestTelemetry = telemetry;
        _addToHistory(telemetry);
      });
    });

    // Estados y errores
    _statusSub = _nfcService.onStatusChanged.listen((msg) {
      if (!mounted) return;
      setState(() => _statusMessage = msg);
    });

    _errorSub = _nfcService.onError.listen((err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: SolarTrackerTheme.accentRed,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      // Detener
      if (_isSimulationMode) {
        _simulationService.stop();
      } else {
        await _nfcService.stopScan();
        if (!mounted) return;
      }
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Escaneo pausado.';
      });
    } else {
      // Iniciar
      if (_isSimulationMode) {
        _simulationService.start();
        setState(() {
          _isScanning = true;
          _statusMessage = 'Modo Simulación activo (Generando datos...)';
        });
      } else {
        final available = await _nfcService.isNfcAvailable();
        if (!mounted) return;
        if (!available) {
          _showNfcUnavailableDialog();
          return;
        }

        setState(() {
          _isScanning = true;
          _statusMessage = 'Acerca el tag NFC del robot...';
        });
        _nfcService.startContinuousScan();
      }
    }
  }

  void _showNfcUnavailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lector NFC no detectado'),
        content: const Text(
          'Este dispositivo no tiene sensor NFC activo o está ejecutándose en un entorno sin hardware.\n\n'
          '¿Deseas activar el MODO SIMULACIÓN para verificar el funcionamiento del dashboard y los gráficos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SolarTrackerTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSimulationMode = true;
                _isScanning = true;
                _statusMessage = 'Modo Simulación activo';
              });
              _simulationService.start();
            },
            child: const Text('Activar Simulación'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _simTelemetrySub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    unawaited(_nfcService.dispose());
    _simulationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Valores por defecto o última telemetría
    final ldrValues = _latestTelemetry?.ldrValues ?? [0, 0, 0, 0];
    final dominantDir = _latestTelemetry?.primaryLightDirection ?? LightDirection.equilibrado;
    final pitch = _latestTelemetry?.servoPitchAngle ?? 90;
    final yaw = _latestTelemetry?.servoYawAngle ?? 90;
    final motorState = _latestTelemetry?.motorDirection ?? MotorState.detenido;
    final reversals = _latestTelemetry?.polarityReversalsCount ?? 0;
    final voltage = _latestTelemetry?.operatingVoltage ?? 0.0;
    final battery = _latestTelemetry?.batteryLevelPercent ?? 0;
    final batteryValid = _latestTelemetry?.batteryValid ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.solar_power, color: SolarTrackerTheme.primaryAmber, size: 20),
              SizedBox(width: 8),
              Text(
                'Theo Jansen Solar Tracker',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          // Switch compacto para alternar Modo Simulación / NFC Real
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSimulationMode ? 'Simular' : 'NFC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isSimulationMode ? SolarTrackerTheme.primaryAmber : Colors.white60,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _isSimulationMode,
                  activeThumbColor: SolarTrackerTheme.primaryAmber,
                  onChanged: (val) {
                    if (_isScanning) {
                      _toggleScan(); // Detener antes de cambiar modo
                    }
                    setState(() => _isSimulationMode = val);
                  },
                ),
              ),
            ],
          ),
          if (_history.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.share, size: 20),
              tooltip: 'Exportar Reporte',
              padding: EdgeInsets.zero,
              onSelected: (val) {
                if (val == 'csv') {
                  ReportService.shareCsvReport(_history);
                } else {
                  ReportService.shareReport(_history);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'json',
                  child: Row(
                    children: [
                      Icon(Icons.data_object, size: 18),
                      SizedBox(width: 8),
                      Text('Exportar JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, size: 18),
                      SizedBox(width: 8),
                      Text('Exportar CSV'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Estado
            _buildStatusBar(),
            const SizedBox(height: 12),

            // 1. Gráfico de Luz LDR
            LdrChartCard(
              ldrValues: ldrValues,
              dominantDirection: dominantDir,
            ),
            const SizedBox(height: 12),

            // 2. Servomotores de Seguimiento
            ServosCard(
              pitch: pitch,
              yaw: yaw,
            ),
            const SizedBox(height: 12),

            // 3. Tracción Theo Jansen y Batería
            MotorBatteryCard(
              motorState: motorState,
              reversals: reversals,
              voltage: voltage,
              battery: battery,
              batteryValid: batteryValid,
            ),
            const SizedBox(height: 12),

            // 4. Historial y Exportación
            HistoryCard(history: _history),
            const SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isScanning ? SolarTrackerTheme.accentRed : SolarTrackerTheme.primaryAmber,
        foregroundColor: Colors.black,
        icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
        label: Text(
          _isScanning
              ? (_isSimulationMode ? 'Pausar Simulación' : 'Pausar NFC')
              : (_isSimulationMode ? 'Iniciar Simulación' : 'Iniciar Escaneo NFC'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _toggleScan,
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isScanning
            ? SolarTrackerTheme.accentGreen.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isScanning ? SolarTrackerTheme.accentGreen : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isScanning ? Icons.sensors : Icons.sensors_off,
            size: 16,
            color: _isScanning ? SolarTrackerTheme.accentGreen : Colors.white54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 12,
                color: _isScanning ? SolarTrackerTheme.accentGreen : Colors.white70,
                fontWeight: _isScanning ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isScanning)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SolarTrackerTheme.accentGreen),
              ),
            ),
        ],
      ),
    );
  }
}
