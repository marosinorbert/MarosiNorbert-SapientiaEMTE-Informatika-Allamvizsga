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
  final double idealSoilMax;
  final double idealLightMin;
  final double idealLightMax;

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
    required this.idealSoilMax,
    required this.idealLightMin,
    required this.idealLightMax,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return Plant(
      id: json['id'],
      name: json['name'] ?? 'Ismeretlen növény',
      species: json['species'] ?? 'Ismeretlen fajta',
      plantedDate: DateTime.tryParse(json['planted_date']?.toString() ?? '') ??
          DateTime.now(),
      emoji: json['emoji'] ?? '🌱',
      idealTempMin: toDouble(json['temp_min'], 18),
      idealTempMax: toDouble(json['temp_max'], 28),
      idealHumidityMin: toDouble(json['humidity_min'], 50),
      idealHumidityMax: toDouble(json['humidity_max'], 75),
      idealSoilMin: toDouble(json['soil_min'], 35),
      idealSoilMax: toDouble(json['soil_max'], 80),
      idealLightMin: toDouble(json['light_min'], 800),
      idealLightMax: toDouble(json['light_max'], 3000),
    );
  }
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

  List<Plant> _plants = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadCurrentSensorData(),
      _loadPlants(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deletePlant(Plant plant) async {
    try {
      await ApiService.deletePlant(plant.id);
      await _loadPlants();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} törölve lett'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nem sikerült törölni a növényt'),
        ),
      );
    }
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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {});
    }
  }

  Future<void> _loadPlants() async {
    try {
      final data = await ApiService.getPlants();

      if (!mounted) return;

      setState(() {
        _plants = data
            .map((item) => Plant.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nem sikerült betölteni a növényeket'),
        ),
      );
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
  bool _soilOk(Plant p) =>
      _currentSoil >= p.idealSoilMin && _currentSoil <= p.idealSoilMax;
  bool _lightOk(Plant p) =>
      _currentLight >= p.idealLightMin && _currentLight <= p.idealLightMax;

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

  void _showPlantDialog({Plant? plant}) {
    final isEdit = plant != null;

    final nameCtrl = TextEditingController(text: plant?.name ?? '');
    final speciesCtrl = TextEditingController(text: plant?.species ?? '');

    final tempMinCtrl = TextEditingController(
      text: (plant?.idealTempMin ?? 18).toStringAsFixed(0),
    );
    final tempMaxCtrl = TextEditingController(
      text: (plant?.idealTempMax ?? 28).toStringAsFixed(0),
    );

    final humidityMinCtrl = TextEditingController(
      text: (plant?.idealHumidityMin ?? 50).toStringAsFixed(0),
    );
    final humidityMaxCtrl = TextEditingController(
      text: (plant?.idealHumidityMax ?? 80).toStringAsFixed(0),
    );

    final soilMinCtrl = TextEditingController(
      text: (plant?.idealSoilMin ?? 40).toStringAsFixed(0),
    );
    final soilMaxCtrl = TextEditingController(
      text: (plant?.idealSoilMax ?? 80).toStringAsFixed(0),
    );

    final lightMinCtrl = TextEditingController(
      text: (plant?.idealLightMin ?? 5000).toStringAsFixed(0),
    );
    final lightMaxCtrl = TextEditingController(
      text: (plant?.idealLightMax ?? 30000).toStringAsFixed(0),
    );

    String selectedEmoji = plant?.emoji ?? '🌱';

    final emojis = ['🌱', '🍅', '🥒', '🥬', '🌶️', '🍓', '🫑', '🧅', '🥕'];

    double parseValue(TextEditingController controller, double fallback) {
      return double.tryParse(controller.text.trim().replaceAll(',', '.')) ??
          fallback;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Növény szerkesztése' : 'Új növény hozzáadása',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: emojis
                      .map(
                        (e) => GestureDetector(
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
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Név',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _DialogField(
                  controller: nameCtrl,
                  hint: 'pl. Paradicsom',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fajta / latin név',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _DialogField(
                  controller: speciesCtrl,
                  hint: 'pl. Solanum lycopersicum',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ideális értékek',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DialogField(
                        controller: tempMinCtrl,
                        hint: 'Hőm. min °C',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogField(
                        controller: tempMaxCtrl,
                        hint: 'Hőm. max °C',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DialogField(
                        controller: humidityMinCtrl,
                        hint: 'Pára min %',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogField(
                        controller: humidityMaxCtrl,
                        hint: 'Pára max %',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DialogField(
                        controller: soilMinCtrl,
                        hint: 'Talaj min %',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogField(
                        controller: soilMaxCtrl,
                        hint: 'Talaj max %',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DialogField(
                        controller: lightMinCtrl,
                        hint: 'Fény min lux',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogField(
                        controller: lightMaxCtrl,
                        hint: 'Fény max lux',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Mégse',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                if (isEdit) {
                  await ApiService.updatePlant(
                    id: plant.id,
                    name: nameCtrl.text.trim(),
                    species: speciesCtrl.text.trim().isEmpty
                        ? 'Ismeretlen fajta'
                        : speciesCtrl.text.trim(),
                    emoji: selectedEmoji,
                    tempMin: parseValue(tempMinCtrl, 18),
                    tempMax: parseValue(tempMaxCtrl, 28),
                    humidityMin: parseValue(humidityMinCtrl, 50),
                    humidityMax: parseValue(humidityMaxCtrl, 80),
                    soilMin: parseValue(soilMinCtrl, 40),
                    soilMax: parseValue(soilMaxCtrl, 80),
                    lightMin: parseValue(lightMinCtrl, 5000),
                    lightMax: parseValue(lightMaxCtrl, 30000),
                  );
                } else {
                  await ApiService.addPlant(
                    name: nameCtrl.text.trim(),
                    species: speciesCtrl.text.trim().isEmpty
                        ? 'Ismeretlen fajta'
                        : speciesCtrl.text.trim(),
                    emoji: selectedEmoji,
                    tempMin: parseValue(tempMinCtrl, 18),
                    tempMax: parseValue(tempMaxCtrl, 28),
                    humidityMin: parseValue(humidityMinCtrl, 50),
                    humidityMax: parseValue(humidityMaxCtrl, 80),
                    soilMin: parseValue(soilMinCtrl, 40),
                    soilMax: parseValue(soilMaxCtrl, 80),
                    lightMin: parseValue(lightMinCtrl, 5000),
                    lightMax: parseValue(lightMaxCtrl, 30000),
                  );
                }

                await _loadPlants();

                if (!mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Mentés' : 'Hozzáadás'),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePlant(plant);
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
                onPressed: () => _showPlantDialog(),
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
            _EmptyPlants(onAdd: () => _showPlantDialog())
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
                            onEdit: () => _showPlantDialog(plant: p),
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
  final VoidCallback onEdit;

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
    required this.onEdit,
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
                    ideal:
                        '${plant.idealSoilMin.toInt()}–${plant.idealSoilMax.toInt()}%',
                    isOk: soilOk,
                  ),
                  const SizedBox(height: 8),
                  _CompareRow(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Fényerő',
                    current: '${currentLight.toInt()} lux',
                    ideal:
                        '${plant.idealLightMin.toInt()}–${plant.idealLightMax.toInt()} lux',
                    isOk: lightOk,
                  ),
                ],
              ),
            ),
          ),

          // Delete button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    label: const Text(
                      'Szerkesztés',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      backgroundColor: AppTheme.primary.withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Törlés',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      backgroundColor:
                          const Color(0xFFEF4444).withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
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
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
