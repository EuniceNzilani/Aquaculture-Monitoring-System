import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import '../models/water_parameter.dart';
import '../models/parameter_reading.dart';

class SimulationService {
  final String locationId;
  final Random _random = Random();
  final BehaviorSubject<List<ParameterReading>> _readingsSubject =
      BehaviorSubject<List<ParameterReading>>.seeded([]);
  Timer? _timer;

  // Initial baseline values for each parameter
  final Map<ParameterType, double> _baselineValues = {
    ParameterType.temperature: 25.0,
    ParameterType.salinity: 32.0,
    ParameterType.pH: 7.8,
    ParameterType.conductivity: 50.0,
    ParameterType.dissolvedOxygen: 8.0,
    ParameterType.turbidity: 5.0,
    ParameterType.orp: 300.0,
    ParameterType.tds: 25.0,
    ParameterType.depth: 15.0,
    ParameterType.chlorophyll: 50.0,
  };

  // Environmental factors that affect multiple parameters together
  double _stormFactor = 0.0;
  double _algalBloomFactor = 0.0;
  double _temperatureAnomaly = 0.0;

  // Noise and fluctuation settings for simulation
  final Map<ParameterType, double> _noiseFactors = {
    ParameterType.temperature: 0.5,
    ParameterType.salinity: 0.3,
    ParameterType.pH: 0.1,
    ParameterType.conductivity: 2.0,
    ParameterType.dissolvedOxygen: 0.4,
    ParameterType.turbidity: 1.0,
    ParameterType.orp: 10.0,
    ParameterType.tds: 1.0,
    ParameterType.depth: 0.2,
    ParameterType.chlorophyll: 5.0,
  };

  SimulationService({required this.locationId});

  Stream<List<ParameterReading>> get readingsStream => _readingsSubject.stream;
  List<ParameterReading> get currentReadings => _readingsSubject.value;

  void startSimulation({int intervalSeconds = 5}) {
    if (_timer != null) {
      stopSimulation();
    }

    // Initial generation of readings
    _updateEnvironmentalFactors();
    _generateReadings();

    // Set up timer for continuous updates
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _updateEnvironmentalFactors();
      _generateReadings();
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateEnvironmentalFactors() {
    // Randomly evolve environmental factors
    _stormFactor = _updateFactor(_stormFactor, 0.05, 0.0, 1.0);
    _algalBloomFactor = _updateFactor(_algalBloomFactor, 0.03, 0.0, 1.0);
    _temperatureAnomaly = _updateFactor(_temperatureAnomaly, 0.1, -3.0, 3.0);

    // Apply seasonal influences (simplified)
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seasonalFactor =
        sin(2 * pi * dayOfYear / 365) * 5; // +/-5 degree seasonal variation

    // Update baseline temperature based on season
    _baselineValues[ParameterType.temperature] = 25.0 + seasonalFactor;
  }

  double _updateFactor(
    double currentValue,
    double changeMax,
    double min,
    double max,
  ) {
    double change = (_random.nextDouble() * 2 - 1) * changeMax;
    double newValue = currentValue + change;

    // 10% chance of factor going to 0 (environmental event ending)
    if (_random.nextDouble() < 0.1 && currentValue > 0.3) {
      newValue = currentValue * 0.5;
    }

    // 2% chance of sudden significant event
    if (_random.nextDouble() < 0.02 && currentValue < 0.3) {
      newValue = min + _random.nextDouble() * (max - min) * 0.7;
    }

    return newValue.clamp(min, max);
  }

  void _generateReadings() {
    final now = DateTime.now();
    final readings = <ParameterReading>[];

    // Generate readings for each parameter type
    for (final type in ParameterType.values) {
      final param = WaterParameter.parameters[type]!;
      double value = _generateParameterValue(type);

      // Ensure the value is within the defined range
      value = value.clamp(param.range.min, param.range.max);

      readings.add(
        ParameterReading(
          type: type,
          value: value,
          timestamp: now,
          locationId: locationId,
        ),
      );
    }

    // Add new readings to the stream
    final List<ParameterReading> allReadings = [
      ...readings,
      ..._readingsSubject.value,
    ];

    // Limit history to last 1000 readings
    final limitedReadings =
        allReadings.length > 1000 ? allReadings.sublist(0, 1000) : allReadings;

    _readingsSubject.add(limitedReadings);
  }

  double _generateParameterValue(ParameterType type) {
    double baseValue = _baselineValues[type]!;
    double noiseFactor = _noiseFactors[type]!;

    // Basic random noise
    double noise = (_random.nextDouble() * 2 - 1) * noiseFactor;
    double value = baseValue + noise;

    // Apply environmental factors
    switch (type) {
      case ParameterType.temperature:
        value += _temperatureAnomaly;
        break;
      case ParameterType.turbidity:
        value += _stormFactor * 50; // Storms increase turbidity
        break;
      case ParameterType.dissolvedOxygen:
        value -= _algalBloomFactor * 3; // Algal blooms decrease oxygen
        value -= _temperatureAnomaly * 0.2; // Higher temps = lower oxygen
        break;
      case ParameterType.chlorophyll:
        value += _algalBloomFactor * 100; // Algal blooms increase chlorophyll
        break;
      case ParameterType.pH:
        // Higher CO2 from algal blooms at night can lower pH
        value -= _algalBloomFactor * 0.4;
        break;
      case ParameterType.conductivity:
        // Storms can affect conductivity
        value += _stormFactor * 5;
        break;
      case ParameterType.salinity:
        // Storms with rain can reduce salinity
        value -= _stormFactor * 2;
        break;
      case ParameterType.orp:
        // Algal blooms can reduce ORP
        value -= _algalBloomFactor * 100;
        break;
      case ParameterType.tds:
        // Storms can increase TDS
        value += _stormFactor * 10;
        break;
      case ParameterType.depth:
        // Very minor fluctuations in depth (tides, etc.)
        value +=
            sin(DateTime.now().millisecondsSinceEpoch / 3600000 * pi) * 1.5;
        break;
    }

    return value;
  }

  // Method to trigger a simulated event
  void simulateEvent(String eventType, {double intensity = 0.8}) {
    switch (eventType) {
      case 'storm':
        _stormFactor = intensity;
        break;
      case 'algalBloom':
        _algalBloomFactor = intensity;
        break;
      case 'heatwave':
        _temperatureAnomaly = 3.0 * intensity;
        break;
      case 'coldSpell':
        _temperatureAnomaly = -3.0 * intensity;
        break;
      case 'oxygenDepletion':
        _baselineValues[ParameterType.dissolvedOxygen] =
            _baselineValues[ParameterType.dissolvedOxygen]! *
            (1 - intensity * 0.5);
        break;
    }
    _generateReadings();
  }

  // Reset to normal conditions
  void resetToNormal() {
    _stormFactor = 0.0;
    _algalBloomFactor = 0.0;
    _temperatureAnomaly = 0.0;

    // Reset baseline values
    _baselineValues[ParameterType.temperature] = 25.0;
    _baselineValues[ParameterType.salinity] = 32.0;
    _baselineValues[ParameterType.pH] = 7.8;
    _baselineValues[ParameterType.conductivity] = 50.0;
    _baselineValues[ParameterType.dissolvedOxygen] = 8.0;
    _baselineValues[ParameterType.turbidity] = 5.0;
    _baselineValues[ParameterType.orp] = 300.0;
    _baselineValues[ParameterType.tds] = 25.0;
    _baselineValues[ParameterType.depth] = 15.0;
    _baselineValues[ParameterType.chlorophyll] = 50.0;

    _generateReadings();
  }

  void dispose() {
    stopSimulation();
    _readingsSubject.close();
  }
}
