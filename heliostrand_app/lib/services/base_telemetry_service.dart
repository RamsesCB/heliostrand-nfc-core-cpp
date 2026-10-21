import '../models/robot_telemetry.dart';

/// Interfaz o clase abstracta base para los proveedores de telemetría del robot.
/// Implementada tanto por el transceptor físico NFC como por el simulador de hardware.
abstract class BaseTelemetryService {
  Stream<RobotTelemetry> get telemetryStream;
  void dispose();
}
