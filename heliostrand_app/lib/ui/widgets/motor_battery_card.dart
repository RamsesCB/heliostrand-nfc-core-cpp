import 'package:flutter/material.dart';

import '../../models/motor_state.dart';
import '../theme.dart';

class MotorBatteryCard extends StatelessWidget {
  final MotorState motorState;
  final int reversals;
  final double voltage;
  final int battery;
  final bool batteryValid;
  final bool? isSimulatedMoving;

  const MotorBatteryCard({
    super.key,
    required this.motorState,
    required this.reversals,
    required this.voltage,
    required this.battery,
    required this.batteryValid,
    this.isSimulatedMoving,
  });

  bool get isMoving => isSimulatedMoving ?? (motorState != MotorState.detenido);

  @override
  Widget build(BuildContext context) {
    final moving = isMoving;

    return Row(
      children: [
        // 1. Tarjeta Mecanismo Theo Jansen
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: SolarTrackerTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SolarTrackerTheme.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Theo Jansen',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SolarTrackerTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: moving
                            ? SolarTrackerTheme.badgeGreenBg
                            : SolarTrackerTheme.badgeRedBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        moving ? 'MOVIENDO' : 'DETENIDO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: moving
                              ? SolarTrackerTheme.badgeGreenText
                              : SolarTrackerTheme.badgeRedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  moving
                      ? (motorState != MotorState.detenido
                          ? motorState.displayName
                          : '12 rpm')
                      : '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: SolarTrackerTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Inversiones: $reversals',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SolarTrackerTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Tarjeta Potencia y Batería
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: SolarTrackerTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SolarTrackerTheme.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Potencia',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SolarTrackerTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  batteryValid ? '${voltage.toStringAsFixed(2)} V' : 'N/D',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: SolarTrackerTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  batteryValid
                      ? 'Batería $battery% · ${battery >= 20 ? 'Óptima' : 'Baja'}'
                      : 'Batería N/D · Esperando NFC',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SolarTrackerTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
