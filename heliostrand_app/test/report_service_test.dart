import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/models/light_direction.dart';
import 'package:heliostrand_app/models/motor_state.dart';
import 'package:heliostrand_app/models/robot_telemetry.dart';
import 'package:heliostrand_app/services/report_service.dart';

void main() {
  test('CSV escapes quotes, commas and line breaks with CRLF records', () {
    final telemetry = RobotTelemetry(
      version: 2,
      sequenceNumber: 7,
      ldrValues: const [10, 20, 30, 40],
      ldrAverage: 25,
      primaryLightDirection: LightDirection.este,
      servoPitchAngle: 90,
      servoYawAngle: 91,
      polarityReversalsCount: 2,
      motorDirection: MotorState.adelante,
      operatingVoltage: 3.85,
      batteryLevelPercent: 70,
      batteryValid: true,
      timestamp: 123456789,
      tagUid: 'TAG,"A"\nB',
    );

    final csv = ReportService.generateCsvString([telemetry]);

    expect(csv.endsWith('\r\n'), isTrue);
    expect(csv.contains('"TAG,""A""\nB"'), isTrue);
    expect(csv.split('\r\n').first.startsWith('version,sequenceNumber'), isTrue);
  });
}
