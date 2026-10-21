import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// THEO JANSEN SOLAR TRACKER - DASHBOARD MINIMALISTA TRADICIONAL
///
/// ESTRUCTURA:
/// 1. Header 56px blanco con logo negro (32x32 radius 9px) + icono sol #E9A000, toggle NFC iOS (44x26)
/// 2. Status Card 48px "Listo para escanear"
/// 3. LDR Card con badge EQUILIBRADO / AJUSTANDO, 4 barras Norte/Sur/Este/Oeste (0-255)
/// 4. Servos Card con 2 sliders Pitch #E9A000 y Yaw #0EA5E9 (0-180°, trackHeight 4)
/// 5. Metrics Grid: Theo Jansen DETENIDO/MOVIENDO + Inversiones, Potencia N/D o Voltaje/Batería
/// 6. Historial con empty state y lista max 5 "P 90° · Y 90°"
/// 7. CTA sticky bottom blur, botón negro #111 h52 radius 12 "Iniciar Escaneo NFC"
///
/// CONEXIONES DE HARDWARE REAL MARCADAS CON "TODO CAMBIAR".

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ===== SERVICIOS DE PRODUCCIÓN =====
  final NfcService _nfcService = NfcService();
  final SimulationService _simulationService = SimulationService();

  // ===== ESTADOS - TODO CAMBIAR: Valores iniciales si requieres calibrar =====
  bool nfcEnabled = true; // Toggle NFC (estilo iOS en el Header)
  bool _isScanning = false;
  bool _isSimulationMode = false;
  bool _isMoving = false;

  double _pitch = 90.0; // Rango 0-180
  double _yaw = 90.0;   // Rango 0-180
  int _inversiones = 0;
  String _statusMessage = 'Listo para escanear';

  // Valores de los 4 sensores LDR [0: Norte, 1: Sur, 2: Oeste, 3: Este]
  List<int> _ldrValues = [182, 204, 196, 168];
  LightDirection _dominantDirection = LightDirection.equilibrado;

  RobotTelemetry? _latestTelemetry;
  final List<RobotTelemetry> _history = [];

  StreamSubscription? _telemetrySub;
  StreamSubscription? _simTelemetrySub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  Timer? _driftTimer;

  @override
  void initState() {
    super.initState();
    _setupListeners();

    // TODO CAMBIAR: Simulación de deriva de luz ambiental (±6) cuando no hay escaneo activo
    _driftTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (_isScanning) return;
      if (!mounted) return;
      setState(() {
        final rng = Random();
        _ldrValues = _ldrValues.map((val) {
          final drift = (rng.nextDouble() * 12 - 6).round();
          return (val + drift).clamp(0, 255);
        }).toList();
      });
    });
  }

  void _setupListeners() {
    // 1. Escucha de telemetría real NFC desde el microcontrolador
    _telemetrySub = _nfcService.onTelemetryReceived.listen((telemetry) {
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
        _statusMessage = 'Telemetría NFC recibida (${telemetry.tagUid})';
      });
    });

    // 2. Escucha de simulación para desarrollo sin hardware físico
    _simTelemetrySub = _simulationService.telemetryStream.listen((telemetry) {
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
      });
    });

    // 3. Estados y notificaciones del servicio NFC
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

  void _addToHistory(RobotTelemetry telemetry) {
    _history.insert(0, telemetry);
    if (_history.length > 500) {
      _history.removeLast();
    }
  }

  // TODO CAMBIAR: Lógica de equilibrado solar (umbral 45)
  bool get isBalanced {
    if (_dominantDirection == LightDirection.equilibrado) return true;
    if (_ldrValues.isEmpty) return true;
    return (_ldrValues.reduce(max) - _ldrValues.reduce(min)) < 45;
  }

  // TODO CAMBIAR: Disparador del escaneo NFC real / Simulación
  Future<void> handleScan() async {
    if (!nfcEnabled) {
      setState(() => _statusMessage = 'Activa NFC para escanear');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _statusMessage = 'Listo para escanear');
      return;
    }

    if (_isScanning) {
      // Pausar escaneo activo
      if (_isSimulationMode) {
        _simulationService.stop();
      } else {
        await _nfcService.stopScan();
      }
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isMoving = false;
          _statusMessage = 'Escaneo pausado';
        });
      }
      return;
    }

    // Iniciar escaneo
    if (_isSimulationMode) {
      _simulationService.start();
      setState(() {
        _isScanning = true;
        _statusMessage = 'Modo Simulación activo...';
        _isMoving = true;
      });
      return;
    }

    // Verificar disponibilidad del hardware NFC
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
    final motorState = _latestTelemetry?.motorDirection ??
        (_isMoving ? MotorState.adelante : MotorState.detenido);
    final voltage = _latestTelemetry?.operatingVoltage ?? 0.0;
    final battery = _latestTelemetry?.batteryLevelPercent ?? 0;
    final batteryValid = _latestTelemetry?.batteryValid ?? false;

    return Scaffold(
      backgroundColor: SolarTrackerTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // TODO CAMBIAR: Ancho máximo adaptable al marco del teléfono (390px centrado)
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
                          onPitchChanged: (val) => setState(() => _pitch = val),
                          onYawChanged: (val) => setState(() => _yaw = val),
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
                        const SizedBox(height: 85), // Espacio para el sticky CTA
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

  // 1. Header 56px blanco con logo negro 32x32 radius 9px + sol #E9A000, toggle NFC iOS 44x26
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SolarTrackerTheme.buttonDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  size: 16,
                  color: SolarTrackerTheme.sunPitchAmber,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Theo Jansen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SolarTrackerTheme.textDark,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Solar Tracker',
                    style: TextStyle(
                      fontSize: 12,
                      color: SolarTrackerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
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
              // Toggle NFC estilo iOS (44x26)
              GestureDetector(
                onTap: () {
                  setState(() {
                    nfcEnabled = !nfcEnabled;
                    if (!nfcEnabled && _isScanning) {
                      _isScanning = false;
                      _isMoving = false;
                      _statusMessage = 'NFC desactivado';
                      _nfcService.stopScan();
                    }
                  });
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
                    alignment:
                        nfcEnabled ? Alignment.centerRight : Alignment.centerLeft,
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
              // Menú contextual para exportaciones y opciones de sistema
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: SolarTrackerTheme.textSecondary,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Opciones',
                onSelected: (val) {
                  if (val == 'sim') {
                    setState(() {
                      _isSimulationMode = !_isSimulationMode;
                    });
                  } else if (val == 'csv') {
                    ReportService.shareCsvReport(_history);
                  } else if (val == 'json') {
                    ReportService.shareReport(_history);
                  } else if (val == 'privacy') {
                    final uri = Uri.parse(
                      'https://github.com/RamsesCB/heliostrand-nfc-core-cpp/blob/main/heliostrand_app/PRIVACY_POLICY.md',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
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
                        Text(
                          _isSimulationMode
                              ? 'Usar NFC Real'
                              : 'Modo Simulación',
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
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Política de Privacidad'),
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

  // 2. Status Card 48px "Listo para escanear"
  Widget _buildNfcStatusCard() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
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
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isScanning)
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
      ),
    );
  }

  // 7. CTA sticky bottom blur, botón negro #111 h52 radius 12 "Iniciar Escaneo NFC"
  Widget _buildStickyCta() {
    final active = nfcEnabled;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFEFEFEF)),
        ),
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
                const Text(
                  'Escaneando... (Toca para pausar)',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
