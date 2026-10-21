import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/robot_telemetry.dart';
import '../../services/report_service.dart';
import '../theme.dart';

class HistoryCard extends StatelessWidget {
  final List<RobotTelemetry> history;
  final VoidCallback? onClear;

  const HistoryCard({
    super.key,
    required this.history,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final recentItems = history.reversed.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: SolarTrackerTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SolarTrackerTheme.cardBorder),
      ),
      child: Column(
        children: [
          // Header de la tarjeta de historial
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: SolarTrackerTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SolarTrackerTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${history.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: SolarTrackerTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (history.isNotEmpty)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ReportService.shareReport(history),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'Exportar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SolarTrackerTheme.sunPitchAmber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 11,
                              color: SolarTrackerTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Estado vacío o Lista de registros
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, 22),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: SolarTrackerTheme.textTertiary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay registros aún',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SolarTrackerTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Los escaneos NFC aparecerán aquí',
                    style: TextStyle(
                      fontSize: 11,
                      color: SolarTrackerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentItems.map((item) {
              final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
              final timeStr = timeFormat.format(date);
              final p = item.servoPitchAngle;
              final y = item.servoYawAngle;

              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF6F6F6)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'P $p° · Y $y°',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: SolarTrackerTheme.textDark,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: SolarTrackerTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
