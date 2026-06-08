import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final DeviceState device;
  final VoidCallback onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onToggle,
  });

  IconData get _icon {
    switch (device.icon) {
      case 'ventilation':
        return Icons.air_rounded;
      case 'irrigation':
        return Icons.water_drop_rounded;
      case 'lamp':
        return Icons.light_mode_rounded;
      case 'heating':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.device_unknown_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: device.isOn
                  ? AppTheme.primaryLight
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: device.isOn ? AppTheme.primary : AppTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
  device.name,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
  device.description,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FittedBox(
  child: Row(
    children: [
      Text(
        device.isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: device.isOn ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: device.isOn,
                onChanged: (_) => onToggle(),
                activeColor: AppTheme.primary,
                activeTrackColor: AppTheme.primaryLight,
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}