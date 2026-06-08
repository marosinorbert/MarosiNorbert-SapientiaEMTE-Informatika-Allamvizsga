import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<_Device> _devices = [
    _Device(
      name: 'Szellőzés',
      description: 'Levegő keringtetés és klíma szabályozás',
      icon: Icons.air_rounded,
      isOn: true,
      isAuto: true,
      uptimeHours: 14,
      scheduleOn: const TimeOfDay(hour: 7, minute: 0),
      scheduleOff: const TimeOfDay(hour: 21, minute: 0),
      autoCondition: 'Ha hőmérséklet > 26°C',
    ),
    _Device(
      name: 'Öntözőrendszer',
      description: 'Automatikus öntözés',
      icon: Icons.water_drop_rounded,
      isOn: false,
      isAuto: false,
      uptimeHours: 3,
      scheduleOn: const TimeOfDay(hour: 8, minute: 0),
      scheduleOff: const TimeOfDay(hour: 8, minute: 30),
      autoCondition: 'Ha talajnedvesség < 40%',
    ),
    _Device(
      name: 'Növénylámpa',
      description: 'Kiegészítő világítás',
      icon: Icons.light_mode_rounded,
      isOn: true,
      isAuto: true,
      uptimeHours: 8,
      scheduleOn: const TimeOfDay(hour: 6, minute: 0),
      scheduleOff: const TimeOfDay(hour: 20, minute: 0),
      autoCondition: 'Ha fényerő < 5000 lux',
    ),
    _Device(
      name: 'Fűtés',
      description: 'Hőmérséklet szabályozás',
      icon: Icons.local_fire_department_rounded,
      isOn: false,
      isAuto: true,
      uptimeHours: 0,
      scheduleOn: const TimeOfDay(hour: 5, minute: 0),
      scheduleOff: const TimeOfDay(hour: 9, minute: 0),
      autoCondition: 'Ha hőmérséklet < 18°C',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Eszköz ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'vezérlés',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manuális és automatikus eszközvezérlés ütemezővel',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),

          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auto módban az eszközöket a szenzor adatok és az ütemező vezérlik. '
                    'Manuális módban te döntöd el mikor kapcsol be/ki.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Device cards
          ...List.generate(
            _devices.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DeviceCard(
                device: _devices[i],
                onToggleMode: () => setState(
                    () => _devices[i].isAuto = !_devices[i].isAuto),
                onToggleOnOff: () =>
                    setState(() => _devices[i].isOn = !_devices[i].isOn),
                onScheduleOnChanged: (t) =>
                    setState(() => _devices[i].scheduleOn = t),
                onScheduleOffChanged: (t) =>
                    setState(() => _devices[i].scheduleOff = t),
              ),
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _Device {
  final String name;
  final String description;
  final IconData icon;
  bool isOn;
  bool isAuto;
  final int uptimeHours;
  TimeOfDay scheduleOn;
  TimeOfDay scheduleOff;
  final String autoCondition;

  _Device({
    required this.name,
    required this.description,
    required this.icon,
    required this.isOn,
    required this.isAuto,
    required this.uptimeHours,
    required this.scheduleOn,
    required this.scheduleOff,
    required this.autoCondition,
  });
}

class _DeviceCard extends StatelessWidget {
  final _Device device;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleOnOff;
  final Function(TimeOfDay) onScheduleOnChanged;
  final Function(TimeOfDay) onScheduleOffChanged;

  const _DeviceCard({
    required this.device,
    required this.onToggleMode,
    required this.onToggleOnOff,
    required this.onScheduleOnChanged,
    required this.onScheduleOffChanged,
  });

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row
          Row(
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
                  device.icon,
                  color: device.isOn
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      device.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Üzemóra badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${device.uptimeHours}h',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Mode + ON/OFF row — WRAP helyett
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // MODE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MÓD',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModeButton(
                          label: '⚡ Auto',
                          isSelected: device.isAuto,
                          onTap: () {
                            if (!device.isAuto) onToggleMode();
                          },
                        ),
                        const SizedBox(width: 2),
                        _ModeButton(
                          label: '✋ Manuális',
                          isSelected: !device.isAuto,
                          onTap: () {
                            if (device.isAuto) onToggleMode();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // STATE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ÁLLAPOT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        device.isOn ? 'BE' : 'KI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: device.isOn
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: device.isOn,
                          onChanged: device.isAuto
                              ? null
                              : (_) => onToggleOnOff(),
                          activeColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primaryLight,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Scheduler row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  'ÜTEMEZŐ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(width: 10),
                _TimeButton(
                  label: 'Be',
                  time: _formatTime(device.scheduleOn),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: device.scheduleOn,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) onScheduleOnChanged(t);
                  },
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                _TimeButton(
                  label: 'Ki',
                  time: _formatTime(device.scheduleOff),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: device.scheduleOff,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) onScheduleOffChanged(t);
                  },
                ),
              ],
            ),
          ),

          // Auto condition
          if (device.isAuto) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 12, color: AppTheme.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Auto: ${device.autoCondition}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}