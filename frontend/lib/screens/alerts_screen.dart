import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

enum AlertSeverity { ok, warning, critical }

class AlertEntry {
  final int id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String sensor;
  final String time;
  bool acknowledged;

  AlertEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.sensor,
    required this.time,
    required this.acknowledged,
  });
}

class AlertRule {
  final int id;
  final String sensor;
  final String operator;
  double threshold;
  final String unit;
  AlertSeverity severity;
  bool enabled;

  AlertRule({
    required this.id,
    required this.sensor,
    required this.operator,
    required this.threshold,
    required this.unit,
    required this.severity,
    required this.enabled,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<AlertEntry> _alerts = [
    AlertEntry(
      id: 1,
      title: 'Magas hőmérséklet',
      message: 'A hőmérséklet elérte a 27.8°C-t, közel a 28°C-os határhoz.',
      severity: AlertSeverity.warning,
      sensor: 'DHT22 — Hőmérséklet',
      time: '14:32',
      acknowledged: false,
    ),
    AlertEntry(
      id: 2,
      title: 'Alacsony talajnedvesség',
      message: 'A talajnedvesség 38%-ra csökkent, az öntözőrendszer aktiválása javasolt.',
      severity: AlertSeverity.critical,
      sensor: 'Talajnedvesség szenzor',
      time: '13:15',
      acknowledged: false,
    ),
    AlertEntry(
      id: 3,
      title: 'Páratartalom normális',
      message: 'A páratartalom a célértéken belül van (62%).',
      severity: AlertSeverity.ok,
      sensor: 'DHT22 — Páratartalom',
      time: '12:00',
      acknowledged: true,
    ),
    AlertEntry(
      id: 4,
      title: 'Fényerő alacsony',
      message: 'A fényerő 4200 lux alá esett, a növénylámpa automatikusan bekapcsolt.',
      severity: AlertSeverity.warning,
      sensor: 'Fényszenzor (BH1750)',
      time: '11:47',
      acknowledged: false,
    ),
  ];

  final List<AlertRule> _rules = [
    AlertRule(
      id: 1,
      sensor: 'Hőmérséklet',
      operator: '>',
      threshold: 28,
      unit: '°C',
      severity: AlertSeverity.critical,
      enabled: true,
    ),
    AlertRule(
      id: 2,
      sensor: 'Hőmérséklet',
      operator: '<',
      threshold: 18,
      unit: '°C',
      severity: AlertSeverity.critical,
      enabled: true,
    ),
    AlertRule(
      id: 3,
      sensor: 'Talajnedvesség',
      operator: '<',
      threshold: 40,
      unit: '%',
      severity: AlertSeverity.warning,
      enabled: true,
    ),
    AlertRule(
      id: 4,
      sensor: 'Páratartalom',
      operator: '<',
      threshold: 50,
      unit: '%',
      severity: AlertSeverity.warning,
      enabled: false,
    ),
  ];

  void _acknowledge(int id) {
    setState(() {
      final alert = _alerts.firstWhere((a) => a.id == id);
      alert.acknowledged = true;
    });
  }

  void _dismiss(int id) {
    setState(() => _alerts.removeWhere((a) => a.id == id));
  }

  void _toggleRule(int id) {
    setState(() {
      final rule = _rules.firstWhere((r) => r.id == id);
      rule.enabled = !rule.enabled;
    });
  }

  int get _activeCount =>
      _alerts.where((a) => !a.acknowledged).length;

  @override
  Widget build(BuildContext context) {
return SingleChildScrollView(
  child: Column(      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Riasztás ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'kezelő',
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
                  'Aktív riasztások és szabályok kezelése',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (_activeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      '$_activeCount aktív',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Active alerts
        const Text(
          'Aktív riasztások',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        if (_alerts.isEmpty)
          _EmptyState()
        else
          ...(_alerts.isEmpty
              ? []
              : _alerts
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          alert: a,
                          onAcknowledge: () => _acknowledge(a.id),
                          onDismiss: () => _dismiss(a.id),
                        ),
                      ))
                  .toList()),

        const SizedBox(height: 24),

        // Rules
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riasztás szabályok',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${_rules.where((r) => r.enabled).length}/${_rules.length} aktív',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._rules
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RuleCard(
                    rule: r,
                    onToggle: () => _toggleRule(r.id),
                  ),
                ))
            .toList(),

        const SizedBox(height: 28),
      ],
  ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertEntry alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onDismiss;

  const _AlertCard({
    required this.alert,
    required this.onAcknowledge,
    required this.onDismiss,
  });

  Color get _borderColor {
    if (alert.acknowledged) return AppTheme.border;
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.ok:
        return AppTheme.primary;
    }
  }

  Color get _bgColor {
    if (alert.acknowledged) return Colors.white;
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFEF2F2);
      case AlertSeverity.warning:
        return const Color(0xFFFFFBEB);
      case AlertSeverity.ok:
        return AppTheme.primarySurface;
    }
  }

  Color get _iconColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.ok:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.ok:
        return Icons.check_circle_rounded;
    }
  }

  String get _severityLabel {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 'Kritikus';
      case AlertSeverity.warning:
        return 'Figyelmeztetés';
      case AlertSeverity.ok:
        return 'Rendben';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: alert.acknowledged ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: alert.acknowledged
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _severityLabel,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _iconColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alert.message,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sensors_rounded,
                        size: 10, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      alert.sensor,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 10, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      alert.time,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                if (!alert.acknowledged)
                  GestureDetector(
                    onTap: onAcknowledge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Nyugtáz',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final AlertRule rule;
  final VoidCallback onToggle;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
  });

  Color get _severityColor {
    switch (rule.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.ok:
        return AppTheme.primary;
    }
  }

  String get _severityLabel {
    switch (rule.severity) {
      case AlertSeverity.critical:
        return 'Kritikus';
      case AlertSeverity.warning:
        return 'Figyelmeztetés';
      case AlertSeverity.ok:
        return 'Rendben';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: rule.enabled ? _severityColor : AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: rule.sensor,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: rule.enabled
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text:
                        '  ${rule.operator}  ${rule.threshold.toInt()} ${rule.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: rule.enabled
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _severityLabel,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _severityColor),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Switch(
              value: rule.enabled,
              onChanged: (_) => onToggle(),
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primaryLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 40, color: AppTheme.primary),
          SizedBox(height: 10),
          Text(
            'Nincs aktív riasztás',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Minden rendszer normálisan működik.',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}