import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/robot_telemetry.dart';

/// Servicio para exportar y compartir reportes de telemetría en JSON.
class ReportService {
  static Future<String> generateJsonString(List<RobotTelemetry> history) async {
    const encoder = JsonEncoder.withIndent('  ');
    final data = history.map((t) => t.toJson()).toList();
    return encoder.convert(data);
  }

  static Future<File> saveReportToFile(List<RobotTelemetry> history) async {
    final jsonContent = await generateJsonString(history);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/telemetria_theojansen_$timestamp.json');
    return await file.writeAsString(jsonContent);
  }

  static Future<void> shareReport(List<RobotTelemetry> history) async {
    if (history.isEmpty) return;
    final file = await saveReportToFile(history);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte de Telemetría Theo Jansen Solar Tracker (${history.length} lecturas)',
        subject: 'Reporte Telemetría Theo Jansen NFC',
      ),
    );
  }
}
