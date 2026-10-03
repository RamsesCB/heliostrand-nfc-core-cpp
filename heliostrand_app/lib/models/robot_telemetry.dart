import 'light_direction.dart';
import 'motor_state.dart';

/// Objeto de dominio inmutable que encapsula las lecturas del robot (Protocolo V2).
class RobotTelemetry {
  final int version;
  final int sequenceNumber;
  final List<int> ldrValues;
  final double ldrAverage;
  final LightDirection primaryLightDirection;
  final int servoPitchAngle;
  final int servoYawAngle;
  final int polarityReversalsCount;
  final MotorState motorDirection;
  final double operatingVoltage;
  final int batteryLevelPercent;
  final bool batteryValid;
  final int timestamp;
  final String tagUid;

  const RobotTelemetry({
    this.version = 2,
    this.sequenceNumber = 0,
    required this.ldrValues,
    required this.ldrAverage,
    required this.primaryLightDirection,
    required this.servoPitchAngle,
    required this.servoYawAngle,
    required this.polarityReversalsCount,
    required this.motorDirection,
    required this.operatingVoltage,
    required this.batteryLevelPercent,
    this.batteryValid = true,
    required this.timestamp,
    required this.tagUid,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'sequenceNumber': sequenceNumber,
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
      'batteryValid': batteryValid,
    };
  }

  factory RobotTelemetry.fromJson(Map<String, dynamic> json) {
    return RobotTelemetry(
      version: json['version'] as int? ?? 2,
      sequenceNumber: json['sequenceNumber'] as int? ?? 0,
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
      batteryValid: json['batteryValid'] as bool? ?? true,
      timestamp: json['timestamp'] as int,
      tagUid: json['tagUid'] as String,
    );
  }

  @override
  String toString() {
    return 'RobotTelemetry(v$version, seq: $sequenceNumber, tag: $tagUid, dir: ${primaryLightDirection.displayName}, motor: ${motorDirection.displayName}, pitch: $servoPitchAngle°, yaw: $servoYawAngle°, volt: ${batteryValid ? "${operatingVoltage}V" : "N/D"}, bat: ${batteryValid ? "$batteryLevelPercent%" : "N/D"})';
  }
}
