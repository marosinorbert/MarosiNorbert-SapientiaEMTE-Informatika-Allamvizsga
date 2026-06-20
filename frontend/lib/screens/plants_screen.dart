import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class Plant {
  final int id;
  final String name;
  final String species;
  final DateTime plantedDate;
  final String emoji;
  final double idealTempMin;
  final double idealTempMax;
  final double idealHumidityMin;
  final double idealHumidityMax;
  final double idealSoilMin;
  final double idealLightMin;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.plantedDate,
    required this.emoji,
    required this.idealTempMin,
    required this.idealTempMax,
    required this.idealHumidityMin,
    required this.idealHumidityMax,
    required this.idealSoilMin,
    required this.idealLightMin,
  });
}

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  // Aktuális szenzor értékek (1 db szenzor)
  double _currentTemp = 0;
  double _currentHumidity = 0;
  double _currentSoil = 0;
  double _currentLight = 0;

  bool _isLoading = true;

  int _nextId = 4;

  final List<Plant> _plants = [
    Plant(
      id: 1,
      name: 'Paradicsom',
      species: 'Solanum lycopersicum',
      plantedDate: DateTime(2025, 3, 15),
      emoji: '🍅',
      idealTempMin: 20,
      idealTempMax: 27,
      idealHumidityMin: 60,
      idealHumidityMax: 80,
      idealSoilMin: 50,
      idealLightMin: 10000,
    ),
    Plant(
      id: 2,
      name: 'Uborka',
      species: 'Cucumis sativus',
      plantedDate: DateTime(2025, 4, 1),
      emoji: '🥒',
      idealTempMin: 22,
      idealTempMax: 28,
      idealHumidityMin: 70,
      idealHumidityMax: 90,
      idealSoilMin: 55,
      idealLightMin: 8000,
    ),
    Plant(
      id: 3,
      name: 'Saláta',
      species: 'Lactuca sativa',
      plantedDate: DateTime(2025, 5, 10),
      emoji: '🥬',
      idealTempMin: 15,
      idealTempMax: 22,
      idealHumidityMin: 50,
      idealHumidityMax: 70,
      idealSoilMin: 40,
      idealLightMin: 5000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSensorData();
  }

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _loadCurrentSensorData() async {
    try {
      final data = await ApiService.getLatestSensorData();

      if (!mounted) return;

      setState(() {
        _currentTemp = _toDouble(data['temperature'], 0);
        _currentHumidity = _toDouble(data['humidity'], 0);
        _currentSoil = _toDouble(data['soilMoisture'], 0);
        _currentLight = _toDouble(data['lightIntensity'], 0);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _daysSince(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    return '$diff nap';
  }

  bool _tempOk(Plant p) =>
      _currentTemp >= p.idealTempMin && _currentTemp <= p.idealTempMax;
  bool _humidityOk(Plant p) =>
      _currentHumidity >= p.idealHumidityMin &&
      _currentHumidity <= p.idealHumidityMax;
  bool _soilOk(Plant p) => _currentSoil >= p.idealSoilMin;
  bool _lightOk(Plant p) => _currentLight >= p.idealLightMin;

  int _healthScore(Plant p) {
    int score = 0;
    if (_tempOk(p)) score++;
    if (_humidityOk(p)) score++;
    if (_soilOk(p)) score++;
    if (_lightOk(p)) score++;
    return score;
  }

  Color _healthColor(int score) {
    if (score == 4) return AppTheme.primary;
    if (score >= 2) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _healthLabel(int score) {
    if (score == 4) return 'Kiváló';
    if (score >= 2) return 'Közepes';
    return 'Kritikus';
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final speciesCtrl = TextEditingController();
    String selectedEmoji = '🌱';
    final emojis = ['🌱', '🍅', '🥒', '🥬', '🌶️', '🍓', '🫑', '🧅', '🥕'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Új növény hozzáadása',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji picker
                const Text('Ikon',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: emojis
                      .map((e) => GestureDetector(
                            onTap: () => setDialog(() => selectedEmoji = e),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedEmoji == e
                                    ? AppTheme.primaryLight
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedEmoji == e
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child:
                                  Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Név',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _DialogField(controller: nameCtrl, hint: 'pl. Paradicsom'),
                const SizedBox(height: 12),
                const Text('Fajta / latin név',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _DialogField(
                    controller: speciesCtrl, hint: 'pl. Solanum lycopersicum'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _plants.add(Plant(
                      id: _nextId++,
                      name: nameCtrl.text,
                      species: speciesCtrl.text.isEmpty
                          ? 'Ismeretlen fajta'
                          : speciesCtrl.text,
                      plantedDate: DateTime.now(),
                      emoji: selectedEmoji,
                      idealTempMin: 18,
                      idealTempMax: 28,
                      idealHumidityMin: 50,
                      idealHumidityMax: 80,
                      idealSoilMin: 40,
                      idealLightMin: 5000,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Hozzáadás'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Plant plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Növény törlése',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Biztosan törlöd a "${plant.name}" növényt?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _plants.removeWhere((p) => p.id == plant.id));
              Navigator.pop(ctx);
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Növény ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'profilok',
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
                      'Növény állapotok az aktuális szenzor adatok alapján',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Új növény'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current sensor summary banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const Text(
                  'Aktuális értékek:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                _SensorBadge(
                  label: '${_currentTemp.toStringAsFixed(1)}°C',
                  icon: Icons.thermostat_rounded,
                ),
                _SensorBadge(
                  label: '${_currentHumidity.toStringAsFixed(1)}%',
                  icon: Icons.water_drop_rounded,
                ),
                _SensorBadge(
                  label: '${_currentSoil.toStringAsFixed(1)}%',
                  icon: Icons.eco_rounded,
                ),
                _SensorBadge(
                  label: '${_currentLight.toInt()} lux',
                  icon: Icons.wb_sunny_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Plant cards
          if (_plants.isEmpty)
            _EmptyPlants(onAdd: _showAddDialog)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: _plants
                      .map((p) => _PlantCard(
                            plant: p,
                            tempOk: _tempOk(p),
                            humidityOk: _humidityOk(p),
                            soilOk: _soilOk(p),
                            lightOk: _lightOk(p),
                            healthScore: _healthScore(p),
                            healthColor: _healthColor(_healthScore(p)),
                            healthLabel: _healthLabel(_healthScore(p)),
                            daysSince: _daysSince(p.plantedDate),
                            currentTemp: _currentTemp,
                            currentHumidity: _currentHumidity,
                            currentSoil: _currentSoil,
                            currentLight: _currentLight,
                            onDelete: () => _confirmDelete(p),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Plant Card ───────────────────────────────────────────

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final bool tempOk;
  final bool humidityOk;
  final bool soilOk;
  final bool lightOk;
  final int healthScore;
  final Color healthColor;
  final String healthLabel;
  final String daysSince;
  final double currentTemp;
  final double currentHumidity;
  final double currentSoil;
  final double currentLight;
  final VoidCallback onDelete;

  const _PlantCard({
    required this.plant,
    required this.tempOk,
    required this.humidityOk,
    required this.soilOk,
    required this.lightOk,
    required this.healthScore,
    required this.healthColor,
    required this.healthLabel,
    required this.daysSince,
    required this.currentTemp,
    required this.currentHumidity,
    required this.currentSoil,
    required this.currentLight,
    required this.onDelete,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: healthColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(plant.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        plant.species,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ültetve: $daysSince',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        healthLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: healthColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$healthScore/4',
                      style: TextStyle(
                        fontSize: 11,
                        color: healthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sensor comparison
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _CompareRow(
                    icon: Icons.thermostat_rounded,
                    label: 'Hőmérséklet',
                    current: '${currentTemp}°C',
                    ideal: '${plant.idealTempMin}–${plant.idealTempMax}°C',
                    isOk: tempOk,
                  ),
                  const SizedBox(height: 8),
                  _CompareRow(
                    icon: Icons.water_drop_rounded,
                    label: 'Páratartalom',
                    current: '${currentHumidity.toInt()}%',
                    ideal:
                        '${plant.idealHumidityMin.toInt()}–${plant.idealHumidityMax.toInt()}%',
                    isOk: humidityOk,
                  ),
                  const SizedBox(height: 8),
                  _CompareRow(
                    icon: Icons.eco_rounded,
                    label: 'Talajnedvesség',
                    current: '${currentSoil.toInt()}%',
                    ideal: 'min. ${plant.idealSoilMin.toInt()}%',
                    isOk: soilOk,
                  ),
                  const SizedBox(height: 8),
                  _CompareRow(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Fényerő',
                    current: '${currentLight.toInt()} lux',
                    ideal: 'min. ${plant.idealLightMin.toInt()} lux',
                    isOk: lightOk,
                  ),
                ],
              ),
            ),
          ),

          // Delete button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: Color(0xFFEF4444)),
              label: const Text('Törlés',
                  style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.06),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compare Row ──────────────────────────────────────────

class _CompareRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String current;
  final String ideal;
  final bool isOk;

  const _CompareRow({
    required this.icon,
    required this.label,
    required this.current,
    required this.ideal,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOk ? AppTheme.primary : const Color(0xFFEF4444);
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
        Text(
          current,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          ideal,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ── Sensor Badge ─────────────────────────────────────────

class _SensorBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SensorBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}

// ── Dialog Field ─────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _DialogField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────

class _EmptyPlants extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPlants({required this.onAdd});

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
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Még nincs növény hozzáadva',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adj hozzá növényeket a feltételek figyeléséhez.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Első növény hozzáadása'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
