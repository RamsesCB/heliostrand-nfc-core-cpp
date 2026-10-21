import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/light_direction.dart';
import '../../models/motor_state.dart';
import '../../models/robot_telemetry.dart';
import '../../services/nfc_service.dart';
import '../../services/report_service.dart';
import '../../services/simulation_service.dart';
import '../theme.dart';
import '../actions.dart';
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

  bool nfcEnabled = true;
  bool _isScanning = false;
  bool _isSimulationMode = false;
  bool _isMoving = false;

  double _pitch = 90.0;
  double _yaw = 90.0;
  int _inversiones = 0;
  String _statusMessage = 'Listo para escanear';
  bool _isStatusExpanded = false;

  List<int> _ldrValues = [182, 204, 196, 168];
  LightDirection _dominantDirection = LightDirection.equilibrado;

  RobotTelemetry? _latestTelemetry;
  final List<RobotTelemetry> _history = [];

  StreamSubscription? _telemetrySub;
  StreamSubscription? _simTelemetrySub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  Timer? _driftTimer;
  bool _scanActionPending = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupListeners();

    _driftTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (_isScanning) return;
      if (!mounted) return;
      setState(() {
        _ldrValues = _ldrValues.map((val) {
          final drift = (_random.nextDouble() * 12 - 6).round();
          return (val + drift).clamp(0, 255);
        }).toList();
      });
    });
  }

  void _setupListeners() {
    _telemetrySub = _nfcService.onTelemetryReceived.listen((telemetry) {
      if (!_isSimulationMode && _isScanning) {
        _receiveTelemetry(telemetry, fromNfc: true);
      }
    });
    _simTelemetrySub = _simulationService.telemetryStream.listen((telemetry) {
      if (_isSimulationMode && _isScanning) _receiveTelemetry(telemetry);
    });

    _statusSub = _nfcService.onStatusChanged.listen((msg) {
      if (!mounted) return;
      setState(() => _statusMessage = msg);
    });

    _errorSub = _nfcService.onError.listen((err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: SolarTrackerTheme.badgeRedText,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _receiveTelemetry(RobotTelemetry telemetry, {bool fromNfc = false}) {
    if (!mounted) return;
    setState(() {
      _latestTelemetry = telemetry;
      _ldrValues = List<int>.from(telemetry.ldrValues);
      _dominantDirection = telemetry.primaryLightDirection;
      _pitch = telemetry.servoPitchAngle.toDouble();
      _yaw = telemetry.servoYawAngle.toDouble();
      _inversiones = telemetry.polarityReversalsCount;
      _isMoving = telemetry.motorDirection != MotorState.detenido;
      _addToHistory(telemetry);
      if (fromNfc) {
        _statusMessage = 'Telemetría NFC recibida (${telemetry.tagUid})';
      }
    });
  }

  Future<void> _stopSources() async {
    _simulationService.stop();
    await _nfcService.stopScan();
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _isMoving = false;
    });
  }

  Future<void> _selectMenu(String value) async {
    if (value == 'sim') {
      if (_scanActionPending) return;
      _scanActionPending = true;
      try {
        await _stopSources();
        if (!mounted) return;
        _simulationService.clearManualServoAngles();
        setState(() {
          _isSimulationMode = !_isSimulationMode;
          _statusMessage = 'Listo para escanear';
        });
      } finally {
        _scanActionPending = false;
      }
    } else if (value == 'csv' || value == 'json') {
      final snapshot = List<RobotTelemetry>.of(_history);
      await runUiAction(
        context,
        () => value == 'csv'
            ? ReportService.shareCsvReport(snapshot)
            : ReportService.shareReport(snapshot),
        'No se pudo exportar el reporte.',
      );
    } else if (value == 'privacy') {
      await openExternalLink(
        context,
        Uri.parse(
          'https://github.com/RamsesCB/heliostrand-nfc-core-cpp/blob/main/heliostrand_app/PRIVACY_POLICY.md',
        ),
      );
    }
  }

  void _addToHistory(RobotTelemetry telemetry) {
    _history.insert(0, telemetry);
    if (_history.length > 500) {
      _history.removeLast();
    }
  }

  Future<void> handleScan() async {
    if (_scanActionPending) return;
    _scanActionPending = true;
    try {
      await runUiAction(context, _handleScan, 'No se pudo iniciar el escaneo.');
    } finally {
      _scanActionPending = false;
    }
  }

  Future<void> _handleScan() async {
    if (!nfcEnabled) {
      setState(() => _statusMessage = 'Activa NFC para escanear');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _statusMessage = 'Listo para escanear');
      return;
    }

    if (_isScanning) {
      await _stopSources();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isMoving = false;
          _statusMessage = 'Escaneo pausado';
        });
      }
      return;
    }

    if (_isSimulationMode) {
      _simulationService.start();
      setState(() {
        _isScanning = true;
        _statusMessage = 'Modo Simulación activo...';
        _isMoving = true;
      });
      return;
    }

    final available = await _nfcService.isNfcAvailable();
    if (!mounted) return;

    if (!available) {
      _showNfcUnavailableDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Escaneando NFC...';
      _isMoving = true;
    });

    _nfcService.startContinuousScan();
  }

  void _showNfcUnavailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lector NFC no detectado'),
        content: const Text(
          'Este dispositivo no cuenta con sensor NFC activo o se está ejecutando en emulador.\n\n'
          '¿Deseas activar el MODO SIMULACIÓN para probar todas las funciones y métricas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SolarTrackerTheme.buttonDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSimulationMode = true;
                _isScanning = true;
                _isMoving = true;
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
    _driftTimer?.cancel();
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
    final motorState =
        _latestTelemetry?.motorDirection ??
        (_isMoving ? MotorState.adelante : MotorState.detenido);
    final voltage = _latestTelemetry?.operatingVoltage ?? 0.0;
    final battery = _latestTelemetry?.batteryLevelPercent ?? 0;
    final batteryValid = _latestTelemetry?.batteryValid ?? false;

    return Scaffold(
      backgroundColor: SolarTrackerTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNfcStatusCard(),
                        const SizedBox(height: 12),
                        LdrChartCard(
                          ldrValues: _ldrValues,
                          dominantDirection: _dominantDirection,
                        ),
                        const SizedBox(height: 12),
                        ServosCard(
                          pitch: _pitch.round(),
                          yaw: _yaw.round(),
                          onPitchChanged: (val) {
                            setState(() => _pitch = val);
                            if (!_isSimulationMode) {
                              _nfcService.queueServoCommand(
                                _pitch.round(),
                                _yaw.round(),
                              );
                            }
                            if (_isSimulationMode) {
                              _simulationService.setManualServoAngles(
                                _pitch.round(),
                                _yaw.round(),
                              );
                            }
                          },
                          onYawChanged: (val) {
                            setState(() => _yaw = val);
                            if (!_isSimulationMode) {
                              _nfcService.queueServoCommand(
                                _pitch.round(),
                                _yaw.round(),
                              );
                            }
                            if (_isSimulationMode) {
                              _simulationService.setManualServoAngles(
                                _pitch.round(),
                                _yaw.round(),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        MotorBatteryCard(
                          motorState: motorState,
                          reversals: _inversiones,
                          voltage: voltage,
                          battery: battery,
                          batteryValid: batteryValid,
                          isSimulatedMoving: _isMoving,
                        ),
                        const SizedBox(height: 12),
                        HistoryCard(
                          history: _history,
                          onClear: () => setState(() => _history.clear()),
                        ),
                        const SizedBox(height: 85),
                      ],
                    ),
                  ),
                ),
                _buildStickyCta(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Solar Tracker',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SolarTrackerTheme.textDark,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Theo Jansen',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: SolarTrackerTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSimulationMode ? 'SIM' : 'NFC',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SolarTrackerTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  if (_scanActionPending) return;
                  _scanActionPending = true;
                  try {
                    setState(() => nfcEnabled = !nfcEnabled);
                    if (!nfcEnabled) {
                      await _stopSources();
                      if (mounted) {
                        setState(() => _statusMessage = 'NFC desactivado');
                      }
                    }
                  } finally {
                    _scanActionPending = false;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: nfcEnabled
                        ? SolarTrackerTheme.buttonDark
                        : const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: nfcEnabled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: SolarTrackerTheme.textSecondary,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Opciones',
                onSelected: _selectMenu,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'sim',
                    child: Row(
                      children: [
                        Icon(
                          _isSimulationMode
                              ? Icons.sensors
                              : Icons.model_training,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSimulationMode
                                ? 'Usar NFC Real'
                                : 'Modo Simulación',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_history.isNotEmpty) ...[
                    const PopupMenuItem(
                      value: 'json',
                      child: Row(
                        children: [
                          Icon(Icons.data_object, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Exportar JSON')),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Exportar CSV')),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('Política de Privacidad')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNfcStatusCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isStatusExpanded = !_isStatusExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: _isStatusExpanded
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.nfc_rounded,
                size: 16,
                color: SolarTrackerTheme.textDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: SolarTrackerTheme.textDark,
                  height: 1.3,
                ),
                maxLines: _isStatusExpanded ? null : 1,
                overflow: _isStatusExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (_isScanning) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SolarTrackerTheme.buttonDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStickyCta() {
    final active = nfcEnabled;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA).withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: handleScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: !active
                ? const Color(0xFFE9ECEF)
                : (_isScanning
                      ? SolarTrackerTheme.badgeRedText
                      : SolarTrackerTheme.buttonDark),
            foregroundColor: !active
                ? SolarTrackerTheme.textSecondary
                : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isScanning) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Escaneando... (Toca para pausar)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                const Icon(Icons.play_arrow_rounded, size: 20),
                const SizedBox(width: 6),
                Text(
                  _isSimulationMode
                      ? 'Iniciar Simulación'
                      : 'Iniciar Escaneo NFC',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
