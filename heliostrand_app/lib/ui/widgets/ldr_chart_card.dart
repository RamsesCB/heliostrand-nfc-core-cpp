import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/light_direction.dart';
import '../theme.dart';

class LdrItemData {
  final String id;
  final int value;
  final bool isDominant;

  const LdrItemData(this.id, this.value, {this.isDominant = false});
}

class LdrChartCard extends StatelessWidget {
  final List<int> ldrValues;
  final LightDirection dominantDirection;

  const LdrChartCard({
    super.key,
    required this.ldrValues,
    required this.dominantDirection,
  });

  bool get isBalanced {
    if (dominantDirection == LightDirection.equilibrado) return true;
    if (ldrValues.isEmpty) return true;
    final maxVal = ldrValues.reduce(max);
    final minVal = ldrValues.reduce(min);
    return (maxVal - minVal) < 45;
  }

  @override
  Widget build(BuildContext context) {
    // Orden de hardware: [0: Norte, 1: Sur, 2: Oeste, 3: Este]
    final int norte = ldrValues.isNotEmpty ? ldrValues[0] : 0;
    final int sur = ldrValues.length > 1 ? ldrValues[1] : 0;
    final int este = ldrValues.length > 3 ? ldrValues[3] : 0;
    final int oeste = ldrValues.length > 2 ? ldrValues[2] : 0;

    final sensors = [
      LdrItemData('Norte', norte, isDominant: dominantDirection == LightDirection.norte),
      LdrItemData('Sur', sur, isDominant: dominantDirection == LightDirection.sur),
      LdrItemData('Este', este, isDominant: dominantDirection == LightDirection.este),
      LdrItemData('Oeste', oeste, isDominant: dominantDirection == LightDirection.oeste),
    ];

    final balanced = isBalanced;

    return Container(
      decoration: BoxDecoration(
        color: SolarTrackerTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SolarTrackerTheme.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 18,
                      color: SolarTrackerTheme.sunPitchAmber,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sensores LDR (Luz)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SolarTrackerTheme.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: balanced
                      ? SolarTrackerTheme.badgeGreenBg
                      : SolarTrackerTheme.badgeAmberBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  balanced ? 'EQUILIBRADO' : 'AJUSTANDO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: balanced
                        ? SolarTrackerTheme.badgeGreenText
                        : SolarTrackerTheme.badgeAmberText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sensors.map((ldr) {
                final heightFactor = (ldr.value / 255.0).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutQuad,
                          height: (100 * heightFactor).clamp(8.0, 100.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ldr.isDominant
                                ? SolarTrackerTheme.sunPitchAmber.withValues(alpha: 0.35)
                                : const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(8),
                            border: ldr.isDominant
                                ? Border.all(
                                    color: SolarTrackerTheme.sunPitchAmber,
                                    width: 1.2,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ldr.id,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: SolarTrackerTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ldr.value}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: SolarTrackerTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
