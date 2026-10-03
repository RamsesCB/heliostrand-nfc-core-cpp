import 'package:flutter/material.dart';

import '../theme.dart';

class ServosCard extends StatelessWidget {
  final int pitch;
  final int yaw;

  const ServosCard({
    super.key,
    required this.pitch,
    required this.yaw,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.precision_manufacturing, color: SolarTrackerTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Servomotores (Seguimiento)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAngleGauge(
                    title: 'Pitch (Vertical)',
                    angle: pitch,
                    icon: Icons.height,
                    color: SolarTrackerTheme.primaryAmber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAngleGauge(
                    title: 'Yaw (Horizontal)',
                    angle: yaw,
                    icon: Icons.sync,
                    color: SolarTrackerTheme.accentCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleGauge({
    required String title,
    required int angle,
    required IconData icon,
    required Color color,
  }) {
    final progress = (angle / 180.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$angle°',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0°', style: TextStyle(fontSize: 10, color: Colors.white38)),
              Text('180°', style: TextStyle(fontSize: 10, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}
