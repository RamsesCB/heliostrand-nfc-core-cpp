import 'package:flutter/material.dart';

import '../../models/motor_state.dart';
import '../theme.dart';

class MotorBatteryCard extends StatelessWidget {
  final MotorState motorState;
  final int reversals;
  final double voltage;
  final int battery;
  final bool batteryValid;

  const MotorBatteryCard({
    super.key,
    required this.motorState,
    required this.reversals,
    required this.voltage,
    required this.battery,
    required this.batteryValid,
  });

  @override
  Widget build(BuildContext context) {
    final batteryColor =
        batteryValid ? _getBatteryColor(battery) : Colors.white54;

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: SolarTrackerTheme.accentGreen,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Theo Jansen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMotorColor(motorState).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getMotorColor(motorState)),
                    ),
                    child: Center(
                      child: Text(
                        motorState.displayName,
                        style: TextStyle(
                          color: _getMotorColor(motorState),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Inversiones: $reversals',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: SolarTrackerTheme.primaryAmber,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Potencia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        batteryValid ? '${voltage.toStringAsFixed(2)} V' : 'N/D',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            batteryValid
                                ? _getBatteryIcon(battery)
                                : Icons.battery_unknown,
                            size: 16,
                            color: batteryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            batteryValid ? '$battery%' : 'N/D',
                            style: TextStyle(
                              color: batteryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: batteryValid
                          ? (battery / 100.0).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getMotorColor(MotorState state) {
    switch (state) {
      case MotorState.adelante:
        return SolarTrackerTheme.accentGreen;
      case MotorState.atras:
        return SolarTrackerTheme.primaryAmber;
      case MotorState.detenido:
        return SolarTrackerTheme.accentRed;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return SolarTrackerTheme.accentGreen;
    if (level > 20) return SolarTrackerTheme.primaryAmber;
    return SolarTrackerTheme.accentRed;
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }
}
