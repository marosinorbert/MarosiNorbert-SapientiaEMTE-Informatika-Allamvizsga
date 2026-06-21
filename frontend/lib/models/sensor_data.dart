class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightIntensity;
  final String lastUpdated;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightIntensity,
    required this.lastUpdated,
  });

  static SensorData get dummy => const SensorData(
        temperature: 24.5,
        humidity: 62,
        soilMoisture: 45,
        lightIntensity: 0,
        lastUpdated: 'Last seen over 1 year ago',
      );
}

class DeviceState {
  final String name;
  final String description;
  final String icon;
  bool isOn;
  bool isAuto;

  DeviceState({
    required this.name,
    required this.description,
    required this.icon,
    required this.isOn,
    required this.isAuto,
  });

  static List<DeviceState> get dummyDevices => [
        DeviceState(
          name: 'Szellőzés',
          description: 'Levegő keringtetés és klíma szabályozás',
          icon: 'ventilation',
          isOn: true,
          isAuto: true,
        ),
        DeviceState(
          name: 'Öntözőrendszer',
          description: 'Automatikus öntözés',
          icon: 'irrigation',
          isOn: true,
          isAuto: true,
        ),
        DeviceState(
          name: 'Növénylámpa',
          description: 'Kiegészítő világítás',
          icon: 'lamp',
          isOn: true,
          isAuto: true,
        ),
        DeviceState(
          name: 'Fűtés',
          description: 'Hőmérséklet szabályozás',
          icon: 'heating',
          isOn: false,
          isAuto: true,
        ),
      ];
}