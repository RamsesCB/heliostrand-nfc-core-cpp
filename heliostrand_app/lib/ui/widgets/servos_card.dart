import 'package:flutter/material.dart';

import '../theme.dart';

class ServosCard extends StatelessWidget {
  final int pitch;
  final int yaw;
  final ValueChanged<double>? onPitchChanged;
  final ValueChanged<double>? onYawChanged;

  const ServosCard({
    super.key,
    required this.pitch,
    required this.yaw,
    this.onPitchChanged,
    this.onYawChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SolarTrackerTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SolarTrackerTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _servoItem(
              label: 'Pitch (Vertical)',
              value: pitch.toDouble().clamp(0.0, 180.0),
              accent: SolarTrackerTheme.sunPitchAmber,
              onChanged: onPitchChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _servoItem(
              label: 'Yaw (Horizontal)',
              value: yaw.toDouble().clamp(0.0, 180.0),
              accent: SolarTrackerTheme.yawSkyBlue,
              onChanged: onYawChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _servoItem({
    required String label,
    required double value,
    required Color accent,
    required ValueChanged<double>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF495057),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            '${value.round()}°',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: accent,
              inactiveTrackColor: const Color(0xFFE9ECEF),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              min: 0,
              max: 180,
              value: value,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
