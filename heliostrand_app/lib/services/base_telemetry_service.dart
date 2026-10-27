import '../models/robot_telemetry.dart';

abstract class BaseTelemetryService {
  Stream<RobotTelemetry> get telemetryStream;
  void dispose();
}
