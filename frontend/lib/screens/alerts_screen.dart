import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';

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
  @override
  void initState() {
    super.initState();
    _loadAlerts(showLoading: true);
  }

  Future<void> _loadAlerts({bool showLoading = false}) async {
    try {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final hasDevice = await ApiService.hasClaimedDevice();

      if (!mounted) return;

      if (!hasDevice) {
        setState(() {
          _hasNoDevice = true;
          _alerts = [];
          _isLoading = false;
          _error = null;
        });
        return;
      }

      final alerts = await ApiService.getAlerts();

      if (!mounted) return;

      setState(() {
        _hasNoDevice = false;
        _error = null;

        _alerts = alerts.map<AlertEntry>((a) {
          return AlertEntry(
            id: a['id'],
            title: a['title'],
            message: a['message'],
            severity: _parseSeverity(a['severity']),
            sensor: a['sensor'] ?? '',
            time: a['created_at'].toString(),
            acknowledged: a['acknowledged'] ?? false,
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Nem sikerült betölteni a riasztásokat: $e';
        _isLoading = false;
        _hasNoDevice = false;
      });
    }
  }

  AlertSeverity _parseSeverity(String value) {
    switch (value) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.ok;
    }
  }

  List<AlertEntry> _alerts = [];

  bool _isLoading = true;
  String? _error;
  bool _hasNoDevice = false;

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

  Future<void> _acknowledge(int id) async {
    try {
      await ApiService.acknowledgeAlert(id);
      await _loadAlerts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nem sikerült nyugtázni a riasztást: $e')),
      );
    }
  }

  Future<void> _dismiss(int id) async {
    try {
      await ApiService.deleteAlert(id);

      setState(() {
        _alerts.removeWhere((a) => a.id == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nem sikerült törölni a riasztást: $e')),
      );
    }
  }

  Future<void> _deleteAllAlerts() async {
    if (_alerts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Összes riasztás törlése'),
        content: const Text(
          'Biztosan törölni szeretnéd az összes riasztást? Ez az adatbázisból is törli őket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteAllAlerts();

      setState(() {
        _alerts.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nem sikerült törölni a riasztásokat: $e')),
      );
    }
  }

  void _toggleRule(int id) {
    setState(() {
      final rule = _rules.firstWhere((r) => r.id == id);
      rule.enabled = !rule.enabled;
    });
  }

  int get _activeCount => _alerts.where((a) => !a.acknowledged).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasNoDevice) {
      return _NoDeviceAlertsCard(
        onRefresh: () => _loadAlerts(showLoading: true),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktív riasztások',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_alerts.isNotEmpty)
                TextButton.icon(
                  onPressed: _deleteAllAlerts,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Összes törlése'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

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

class _NoDeviceAlertsCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoDeviceAlertsCard({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nincs ESP32 hozzárendelve',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A riasztások a saját ESP32 eszköz szenzoradatai alapján '
                'jönnek létre. Először rendelj hozzá egy ESP32-t a '
                'Beállítások oldalon, majd a rendszer itt fogja megjeleníteni '
                'a hőmérséklet, páratartalom, talajnedvesség és víztartály '
                'riasztásokat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Újraellenőrzés'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 10, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      alert.time,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
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
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
