import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/robot_telemetry.dart';

class ReportService {
  static Future<String> generateJsonString(List<RobotTelemetry> history) async {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(history.map((t) => t.toJson()).toList());
  }

  static String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(RegExp(r'[",\r\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }

  static String generateCsvString(List<RobotTelemetry> history) {
    const header = <String>[
      'version',
      'sequenceNumber',
      'timestamp',
      'tagUid',
      'ldrNorth',
      'ldrSouth',
      'ldrWest',
      'ldrEast',
      'ldrAverage',
      'direction',
      'pitchAngle',
      'yawAngle',
      'voltageMv',
      'batteryPercent',
      'batteryValid',
      'polarityReversals',
      'motorState',
    ];

    final rows = <List<Object?>>[header];
    for (final t in history) {
      rows.add(<Object?>[
        t.version,
        t.sequenceNumber,
        t.timestamp,
        t.tagUid,
        t.ldrValues.isNotEmpty ? t.ldrValues[0] : 0,
        t.ldrValues.length > 1 ? t.ldrValues[1] : 0,
        t.ldrValues.length > 2 ? t.ldrValues[2] : 0,
        t.ldrValues.length > 3 ? t.ldrValues[3] : 0,
        t.ldrAverage.toStringAsFixed(2),
        t.primaryLightDirection.displayName,
        t.servoPitchAngle,
        t.servoYawAngle,
        t.batteryValid ? (t.operatingVoltage * 1000).round() : 0,
        t.batteryValid ? t.batteryLevelPercent : 0,
        t.batteryValid,
        t.polarityReversalsCount,
        t.motorDirection.displayName,
      ]);
    }

    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static Future<File> saveReportToFile(List<RobotTelemetry> history) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/telemetria_theojansen_$timestamp.json');
    return file.writeAsString(await generateJsonString(history));
  }

  static Future<File> saveCsvReportToFile(List<RobotTelemetry> history) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/telemetria_theojansen_$timestamp.csv');
    return file.writeAsString(generateCsvString(history));
  }

  static Future<void> shareReport(List<RobotTelemetry> history) async {
    if (history.isEmpty) return;
    final file = await saveReportToFile(history);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte JSON de telemetría (${history.length} lecturas)',
        subject: 'Reporte Telemetría Heliostrand (JSON)',
      ),
    );
  }

  static Future<void> shareCsvReport(List<RobotTelemetry> history) async {
    if (history.isEmpty) return;
    final file = await saveCsvReportToFile(history);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte CSV de telemetría (${history.length} lecturas)',
        subject: 'Reporte Telemetría Heliostrand (CSV)',
      ),
    );
  }
}
