import 'dart:async';
import 'dart:math' as math;

import '../models/light_direction.dart';
import '../models/motor_state.dart';
import '../models/robot_telemetry.dart';

/// Servicio de simulación de telemetría para pruebas sin hardware físico.
class SimulationService {
  Timer? _timer;
  final math.Random _random = math.Random();
  int _reversals = 0;
  bool _active = false;

  final StreamController<RobotTelemetry> _telemetryController =
      StreamController<RobotTelemetry>.broadcast();

  Stream<RobotTelemetry> get telemetryStream => _telemetryController.stream;
  bool get isActive => _active;

  void start({Duration interval = const Duration(milliseconds: 1500)}) {
    if (_active) return;
    _active = true;

    _timer = Timer.periodic(interval, (_) {
      final int norte = _random.nextInt(256);
      final int sur = _random.nextInt(256);
      final int oeste = _random.nextInt(256);
      final int este = _random.nextInt(256);
      final ldr = [norte, sur, oeste, este];

      final maxVal = math.max(math.max(norte, sur), math.max(oeste, este));
      LightDirection dir;
      if (maxVal == norte) {
        dir = LightDirection.norte;
      } else if (maxVal == sur) {
        dir = LightDirection.sur;
      } else if (maxVal == oeste) {
        dir = LightDirection.oeste;
      } else {
        dir = LightDirection.este;
      }

      final int pitch = 45 + _random.nextInt(90);
      final int yaw = _random.nextInt(181);

      if (_random.nextInt(4) == 0) {
        _reversals++;
      }
      final motorState =
          (_reversals % 2 == 0) ? MotorState.adelante : MotorState.atras;

      final double voltage = 4.85 + (_random.nextDouble() * 0.40);
      final int battery = 70 + _random.nextInt(31);

      final telemetry = RobotTelemetry(
        ldrValues: ldr,
        ldrAverage: (norte + sur + oeste + este) / 4.0,
        primaryLightDirection: dir,
        servoPitchAngle: pitch,
        servoYawAngle: yaw,
        polarityReversalsCount: _reversals,
        motorDirection: motorState,
        operatingVoltage: double.parse(voltage.toStringAsFixed(2)),
        batteryLevelPercent: battery,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        tagUid: 'SIM-TAG-MOB-${_random.nextInt(9999).toString().padLeft(4, "0")}',
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
