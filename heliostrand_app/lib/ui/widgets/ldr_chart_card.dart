import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/light_direction.dart';
import '../theme.dart';

class LdrChartCard extends StatelessWidget {
  final List<int> ldrValues;
  final LightDirection dominantDirection;

  const LdrChartCard({
    super.key,
    required this.ldrValues,
    required this.dominantDirection,
  });

  @override
  Widget build(BuildContext context) {
    // Array: [0: Norte, 1: Sur, 2: Oeste, 3: Este]
    final int norte = ldrValues.isNotEmpty ? ldrValues[0] : 0;
    final int sur = ldrValues.length > 1 ? ldrValues[1] : 0;
    final int este = ldrValues.length > 3 ? ldrValues[3] : 0;
    final int oeste = ldrValues.length > 2 ? ldrValues[2] : 0;

    final bars = [
      _buildBar(0, norte, dominantDirection == LightDirection.norte),
      _buildBar(1, sur, dominantDirection == LightDirection.sur),
      _buildBar(2, este, dominantDirection == LightDirection.este),
      _buildBar(3, oeste, dominantDirection == LightDirection.oeste),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wb_sunny, color: SolarTrackerTheme.primaryAmber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sensores LDR (Luz)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SolarTrackerTheme.primaryAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SolarTrackerTheme.primaryAmber),
                  ),
                  child: Text(
                    'Predominante: ${dominantDirection.displayName}',
                    style: const TextStyle(
                      color: SolarTrackerTheme.primaryAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: 255,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 64,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const titles = ['Norte', 'Sur', 'Este', 'Oeste'];
                          if (val.toInt() >= 0 && val.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                titles[val.toInt()],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: bars,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, int value, bool isDominant) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: isDominant ? SolarTrackerTheme.primaryAmber : SolarTrackerTheme.accentCyan,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 255,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}
