import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/robot_telemetry.dart';

/// Servicio para exportar y compartir reportes de telemetría en JSON y CSV.
class ReportService {
  static Future<String> generateJsonString(List<RobotTelemetry> history) async {
    const encoder = JsonEncoder.withIndent('  ');
    final data = history.map((t) => t.toJson()).toList();
    return encoder.convert(data);
  }

  static String generateCsvString(List<RobotTelemetry> history) {
    final sb = StringBuffer();
    sb.writeln(
      'version,sequenceNumber,timestamp,tagUid,ldrNorth,ldrSouth,ldrWest,ldrEast,ldrAverage,direction,pitchAngle,yawAngle,voltageMv,batteryPercent,batteryValid,polarityReversals,motorState',
    );
    for (final t in history) {
      final ldrN = t.ldrValues.isNotEmpty ? t.ldrValues[0] : 0;
      final ldrS = t.ldrValues.length > 1 ? t.ldrValues[1] : 0;
      final ldrW = t.ldrValues.length > 2 ? t.ldrValues[2] : 0;
      final ldrE = t.ldrValues.length > 3 ? t.ldrValues[3] : 0;
      sb.writeln(
        '${t.version},${t.sequenceNumber},${t.timestamp},"${t.tagUid}",$ldrN,$ldrS,$ldrW,$ldrE,${t.ldrAverage.toStringAsFixed(2)},${t.primaryLightDirection.displayName},${t.servoPitchAngle},${t.servoYawAngle},${t.batteryValid ? (t.operatingVoltage * 1000).toInt() : 0},${t.batteryValid ? t.batteryLevelPercent : 0},${t.batteryValid},${t.polarityReversalsCount},${t.motorDirection.displayName}',
      );
    }
    return sb.toString();
  }

  static Future<File> saveReportToFile(List<RobotTelemetry> history) async {
    final jsonContent = await generateJsonString(history);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/telemetria_theojansen_$timestamp.json');
    return await file.writeAsString(jsonContent);
  }

  static Future<File> saveCsvReportToFile(List<RobotTelemetry> history) async {
    final csvContent = generateCsvString(history);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/telemetria_theojansen_$timestamp.csv');
    return await file.writeAsString(csvContent);
  }

  static Future<void> shareReport(List<RobotTelemetry> history) async {
    if (history.isEmpty) return;
    final file = await saveReportToFile(history);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte de Telemetría Theo Jansen Solar Tracker JSON (${history.length} lecturas)',
        subject: 'Reporte Telemetría Theo Jansen NFC (JSON)',
      ),
    );
  }

  static Future<void> shareCsvReport(List<RobotTelemetry> history) async {
    if (history.isEmpty) return;
    final file = await saveCsvReportToFile(history);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte de Telemetría Theo Jansen Solar Tracker CSV (${history.length} lecturas)',
        subject: 'Reporte Telemetría Theo Jansen NFC (CSV)',
      ),
    );
  }
}
