import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dart:async';

enum LogType { device, sensor, alert, system }

class LogEntry {
  final int id;
  final LogType type;
  final String title;
  final String description;
  final DateTime timestamp;

  const LogEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();
  LogType? _selectedType;
  DateTime? _selectedDate;
  String _searchQuery = '';

  List<LogEntry> _allEntries = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadLogs(),
    );
  }

  List<LogEntry> get _filtered {
    return _allEntries.where((e) {
      final matchType = _selectedType == null || e.type == _selectedType;
      final matchSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchDate = _selectedDate == null ||
          (e.timestamp.year == _selectedDate!.year &&
              e.timestamp.month == _selectedDate!.month &&
              e.timestamp.day == _selectedDate!.day);
      return matchType && matchSearch && matchDate;
    }).toList();
  }

  // Group by date
  Map<String, List<LogEntry>> get _grouped {
    final Map<String, List<LogEntry>> map = {};
    for (final e in _filtered) {
      final key = _dateLabel(e.timestamp);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day)
      return 'Ma';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1)
      return 'Tegnap';
    return '${dt.year}. ${_month(dt.month)} ${dt.day}.';
  }

  String _month(int m) {
    const months = [
      '',
      'jan.',
      'feb.',
      'már.',
      'ápr.',
      'máj.',
      'jún.',
      'júl.',
      'aug.',
      'szep.',
      'okt.',
      'nov.',
      'dec.'
    ];
    return months[m];
  }

  Color _typeColor(LogType t) {
    switch (t) {
      case LogType.device:
        return AppTheme.primary;
      case LogType.sensor:
        return const Color(0xFF60A5FA);
      case LogType.alert:
        return const Color(0xFFEF4444);
      case LogType.system:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _typeIcon(LogType t) {
    switch (t) {
      case LogType.device:
        return Icons.devices_rounded;
      case LogType.sensor:
        return Icons.sensors_rounded;
      case LogType.alert:
        return Icons.notifications_rounded;
      case LogType.system:
        return Icons.developer_board_rounded;
    }
  }

  String _typeLabel(LogType t) {
    switch (t) {
      case LogType.device:
        return 'Eszköz';
      case LogType.sensor:
        return 'Szenzor';
      case LogType.alert:
        return 'Riasztás';
      case LogType.system:
        return 'Rendszer';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await ApiService.getLogs();

      setState(() {
        _allEntries = logs.map<LogEntry>((log) {
          return LogEntry(
            id: log['id'],
            type: _parseLogType(log['type']),
            title: log['title'],
            description: log['description'] ?? '',
            timestamp: DateTime.parse(log['created_at']),
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült betölteni a naplót: $e';
        _isLoading = false;
      });
    }
  }

  LogType _parseLogType(String type) {
    switch (type) {
      case 'device':
        return LogType.device;
      case 'sensor':
        return LogType.sensor;
      case 'alert':
        return LogType.alert;
      default:
        return LogType.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Esemény ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'napló',
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
            'Rendszer-, eszköz- és szenzoresemények előzményei',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // Search + Date filter row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Keresés...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppTheme.textSecondary),
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date picker button
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme:
                            const ColorScheme.light(primary: AppTheme.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  _selectedDate == null
                      ? 'Dátum'
                      : '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedDate != null
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  side: BorderSide(
                    color: _selectedDate != null
                        ? AppTheme.primary
                        : AppTheme.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  tooltip: 'Dátumszűrő törlése',
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Összes',
                  isSelected: _selectedType == null,
                  color: AppTheme.textPrimary,
                  onTap: () => setState(() => _selectedType = null),
                ),
                const SizedBox(width: 8),
                ...LogType.values.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _typeLabel(t),
                      isSelected: _selectedType == t,
                      color: _typeColor(t),
                      onTap: () => setState(
                          () => _selectedType = _selectedType == t ? null : t),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Result count
          Text(
            '${_filtered.length} esemény',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 20),

          // Timeline grouped by date
          if (_filtered.isEmpty)
            _EmptyLog()
          else
            ...dateKeys.map((dateKey) {
              final entries = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Divider(color: AppTheme.border)),
                      ],
                    ),
                  ),
                  // Timeline entries
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left timeline line
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Container(
                                width: 2,
                                color: AppTheme.border,
                              ),
                            ],
                          ),
                        ),
                        // Entries
                        Expanded(
                          child: Column(
                            children: entries
                                .map((e) => _TimelineEntry(
                                      entry: e,
                                      color: _typeColor(e.type),
                                      icon: _typeIcon(e.type),
                                      typeLabel: _typeLabel(e.type),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ── Timeline Entry ───────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  final LogEntry entry;
  final Color color;
  final IconData icon;
  final String typeLabel;

  const _TimelineEntry({
    required this.entry,
    required this.color,
    required this.icon,
    required this.typeLabel,
  });

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon on timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(entry.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────

class _EmptyLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            'Nincs találat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Próbálj más szűrési feltételt.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
