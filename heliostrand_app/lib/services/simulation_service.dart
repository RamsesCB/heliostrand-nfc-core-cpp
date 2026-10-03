import 'dart:async';
import 'dart:math' as math;

import '../models/light_direction.dart';
import '../models/motor_state.dart';
import '../models/robot_telemetry.dart';

class SimulationService {
  Timer? _timer;
  final math.Random _random = math.Random();
  int _reversals = 0;
  int _sequence = 0;
  bool _active = false;
  MotorState _motorState = MotorState.adelante;

  static const String _simulatedUid = 'SIM-TAG-MOBILE-0001';

  final StreamController<RobotTelemetry> _telemetryController =
      StreamController<RobotTelemetry>.broadcast();

  Stream<RobotTelemetry> get telemetryStream => _telemetryController.stream;
  bool get isActive => _active;

  void start({Duration interval = const Duration(milliseconds: 1500)}) {
    if (_active) return;
    _active = true;

    _timer = Timer.periodic(interval, (_) {
      final ldr = List<int>.generate(4, (_) => _random.nextInt(256));

      final LightDirection direction;
      if (_random.nextInt(10) == 0) {
        final balanced = 100 + _random.nextInt(40);
        for (var i = 0; i < ldr.length; i++) {
          ldr[i] = balanced;
        }
        direction = LightDirection.equilibrado;
      } else {
        final maxValue = ldr.reduce(math.max);
        final index = ldr.indexOf(maxValue);
        direction = <LightDirection>[
          LightDirection.norte,
          LightDirection.sur,
          LightDirection.oeste,
          LightDirection.este,
        ][index];
      }

      if (_random.nextInt(8) == 0) {
        _motorState = _motorState == MotorState.adelante
            ? MotorState.atras
            : MotorState.adelante;
        _reversals = (_reversals + 1) & 0xFF;
      } else if (_random.nextInt(12) == 0) {
        _motorState = MotorState.detenido;
      }

      final voltageMv = 3200 + _random.nextInt(1001);
      final battery = (((voltageMv - 3000) * 100) ~/ 1200).clamp(0, 100);

      final telemetry = RobotTelemetry(
        version: 2,
        sequenceNumber: _sequence++ & 0xFF,
        ldrValues: ldr,
        ldrAverage: ldr.reduce((a, b) => a + b) / 4.0,
        primaryLightDirection: direction,
        servoPitchAngle: 15 + _random.nextInt(151),
        servoYawAngle: 10 + _random.nextInt(161),
        polarityReversalsCount: _reversals,
        motorDirection: _motorState,
        operatingVoltage: voltageMv / 1000.0,
        batteryLevelPercent: battery,
        batteryValid: true,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        tagUid: _simulatedUid,
      );

      _telemetryController.add(telemetry);
    });
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _telemetryController.close();
  }
}
