import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/robot_telemetry.dart';
import '../../services/report_service.dart';
import '../theme.dart';

class HistoryCard extends StatelessWidget {
  final List<RobotTelemetry> history;

  const HistoryCard({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: SolarTrackerTheme.accentCyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Historial (${history.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => ReportService.shareReport(history),
                    icon: const Icon(Icons.share, size: 16, color: SolarTrackerTheme.primaryAmber),
                    label: const Text(
                      'Exportar JSON',
                      style: TextStyle(color: SolarTrackerTheme.primaryAmber, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No hay registros aún. Inicia el escaneo NFC.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length > 5 ? 5 : history.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 12),
                itemBuilder: (context, index) {
                  // Mostrar los más recientes primero
                  final item = history[history.length - 1 - index];
                  final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeFormat.format(date),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            item.tagUid,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildBadge('${item.operatingVoltage.toStringAsFixed(2)}V', Colors.blueGrey),
                          const SizedBox(width: 6),
                          _buildBadge('${item.batteryLevelPercent}%', Colors.teal),
                          const SizedBox(width: 6),
                          _buildBadge(item.primaryLightDirection.displayName, Colors.orange),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade200, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
