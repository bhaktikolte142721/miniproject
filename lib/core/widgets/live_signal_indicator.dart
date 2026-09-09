import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders nRF24 wireless RSSI signal bars and battery telemetry pill.
class LiveSignalIndicator extends StatelessWidget {
  final int rssi; // in dBm, e.g. -60
  final int batteryPercent; // 0 - 100
  final bool isOnline;

  const LiveSignalIndicator({
    super.key,
    required this.rssi,
    required this.batteryPercent,
    this.isOnline = true,
  });

  int get _signalBars {
    if (!isOnline) return 0;
    if (rssi >= -65) return 4;
    if (rssi >= -75) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }

  Color get _batteryColor {
    if (batteryPercent > 40) return AppColors.alertStable;
    if (batteryPercent > 20) return AppColors.alertWarning;
    return AppColors.alertCritical;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _signalBars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // nRF24 RSSI Signal Bars
        Tooltip(
          message: isOnline ? 'nRF24 RSSI: $rssi dBm' : 'Node Disconnected',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final isActive = isOnline && (index < bars);
              final barHeight = 6.0 + (index * 3.5);
              return Container(
                width: 3.5,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  color: isActive
                      ? (bars >= 2 ? AppColors.primaryMint : AppColors.alertWarning)
                      : AppColors.chipInactive,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),

        // Battery Level Pill
        Tooltip(
          message: 'Node Battery: $batteryPercent%',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _batteryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _batteryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  batteryPercent <= 20
                      ? Icons.battery_alert_rounded
                      : (batteryPercent > 80
                          ? Icons.battery_full_rounded
                          : Icons.battery_charging_full_rounded),
                  size: 13,
                  color: _batteryColor,
                ),
                const SizedBox(width: 3),
                Text(
                  '$batteryPercent%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _batteryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
