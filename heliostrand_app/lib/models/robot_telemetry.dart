import 'light_direction.dart';
import 'motor_state.dart';

/// Objeto de dominio inmutable que encapsula las lecturas del robot en un instante determinado.
class RobotTelemetry {
  final List<int> ldrValues;
  final double ldrAverage;
  final LightDirection primaryLightDirection;
  final int servoPitchAngle;
  final int servoYawAngle;
  final int polarityReversalsCount;
  final MotorState motorDirection;
  final double operatingVoltage;
  final int batteryLevelPercent;
  final int timestamp;
  final String tagUid;

  const RobotTelemetry({
    required this.ldrValues,
    required this.ldrAverage,
    required this.primaryLightDirection,
    required this.servoPitchAngle,
    required this.servoYawAngle,
    required this.polarityReversalsCount,
    required this.motorDirection,
    required this.operatingVoltage,
    required this.batteryLevelPercent,
    required this.timestamp,
    required this.tagUid,
  });

  Map<String, dynamic> toJson() {
    return {
      'tagUid': tagUid,
      'timestamp': timestamp,
      'ldrValues': ldrValues,
      'ldrAverage': ldrAverage,
      'primaryLightDirection': primaryLightDirection.displayName,
      'servoPitchAngle': servoPitchAngle,
      'servoYawAngle': servoYawAngle,
      'polarityReversalsCount': polarityReversalsCount,
      'motorDirection': motorDirection.displayName,
      'operatingVoltage': operatingVoltage,
      'batteryLevelPercent': batteryLevelPercent,
    };
  }

  factory RobotTelemetry.fromJson(Map<String, dynamic> json) {
    return RobotTelemetry(
      ldrValues: List<int>.from(json['ldrValues'] as List),
      ldrAverage: (json['ldrAverage'] as num).toDouble(),
      primaryLightDirection: LightDirection.values.firstWhere(
        (e) => e.displayName == json['primaryLightDirection'],
        orElse: () => LightDirection.equilibrado,
      ),
      servoPitchAngle: json['servoPitchAngle'] as int,
      servoYawAngle: json['servoYawAngle'] as int,
      polarityReversalsCount: json['polarityReversalsCount'] as int,
      motorDirection: MotorState.values.firstWhere(
        (e) => e.displayName == json['motorDirection'],
        orElse: () => MotorState.detenido,
      ),
      operatingVoltage: (json['operatingVoltage'] as num).toDouble(),
      batteryLevelPercent: json['batteryLevelPercent'] as int,
      timestamp: json['timestamp'] as int,
      tagUid: json['tagUid'] as String,
    );
  }

  @override
  String toString() {
    return 'RobotTelemetry(tag: $tagUid, ldrAvg: $ldrAverage, dir: ${primaryLightDirection.displayName}, pitch: $servoPitchAngle, yaw: $servoYawAngle, volt: ${operatingVoltage}V, bat: $batteryLevelPercent%)';
  }
}
