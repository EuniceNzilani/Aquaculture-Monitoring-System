import 'package:flutter/material.dart';

enum ParameterType {
  temperature,
  salinity,
  pH,
  conductivity,
  dissolvedOxygen,
  turbidity,
  orp, // Oxidation-Reduction Potential
  tds, // Total Dissolved Solids
  depth,
  chlorophyll,
}

enum AlertStatus {
  normal,
  warning,
  critical,
}

class ParameterRange {
  final double min;
  final double max;
  final double warningLowerThreshold;
  final double warningUpperThreshold;
  final double criticalLowerThreshold;
  final double criticalUpperThreshold;

  const ParameterRange({
    required this.min,
    required this.max,
    required this.warningLowerThreshold,
    required this.warningUpperThreshold,
    required this.criticalLowerThreshold,
    required this.criticalUpperThreshold,
  });
}

class WaterParameter {
  final ParameterType type;
  final String name;
  final String unit;
  final ParameterRange range;
  final IconData icon;
  final Color color;

  const WaterParameter({
    required this.type,
    required this.name,
    required this.unit,
    required this.range,
    required this.icon,
    required this.color,
  });

  static final Map<ParameterType, WaterParameter> parameters = {
    ParameterType.temperature: const WaterParameter(
      type: ParameterType.temperature,
      name: 'Temperature',
      unit: '°C',
      range: ParameterRange(
        min: -5.0,
        max: 50.0,
        warningLowerThreshold: 10.0,
        warningUpperThreshold: 30.0,
        criticalLowerThreshold: 5.0,
        criticalUpperThreshold: 35.0,
      ),
      icon: Icons.thermostat,
      color: Colors.orange,
    ),
    ParameterType.salinity: const WaterParameter(
      type: ParameterType.salinity,
      name: 'Salinity',
      unit: 'psu',
      range: ParameterRange(
        min: 0.0,
        max: 70.0,
        warningLowerThreshold: 28.0,
        warningUpperThreshold: 35.0,
        criticalLowerThreshold: 25.0,
        criticalUpperThreshold: 40.0,
      ),
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    ParameterType.pH: const WaterParameter(
      type: ParameterType.pH,
      name: 'pH',
      unit: '',
      range: ParameterRange(
        min: 0.0,
        max: 14.0,
        warningLowerThreshold: 6.8,
        warningUpperThreshold: 8.2,
        criticalLowerThreshold: 6.5,
        criticalUpperThreshold: 8.5,
      ),
      icon: Icons.science,
      color: Colors.green,
    ),
    ParameterType.conductivity: const WaterParameter(
      type: ParameterType.conductivity,
      name: 'Conductivity',
      unit: 'mS/cm',
      range: ParameterRange(
        min: 0.0,
        max: 200.0,
        warningLowerThreshold: 40.0,
        warningUpperThreshold: 60.0,
        criticalLowerThreshold: 35.0,
        criticalUpperThreshold: 65.0,
      ),
      icon: Icons.bolt,
      color: Colors.yellow,
    ),
    ParameterType.dissolvedOxygen: const WaterParameter(
      type: ParameterType.dissolvedOxygen,
      name: 'Dissolved Oxygen',
      unit: 'mg/L',
      range: ParameterRange(
        min: 0.0,
        max: 50.0,
        warningLowerThreshold: 5.0,
        warningUpperThreshold: 15.0,
        criticalLowerThreshold: 3.0,
        criticalUpperThreshold: 20.0,
      ),
      icon: Icons.air,
      color: Colors.lightBlue,
    ),
    ParameterType.turbidity: const WaterParameter(
      type: ParameterType.turbidity,
      name: 'Turbidity',
      unit: 'NTU',
      range: ParameterRange(
        min: 0.0,
        max: 4000.0,
        warningLowerThreshold: 0.0,
        warningUpperThreshold: 20.0,
        criticalLowerThreshold: 0.0,
        criticalUpperThreshold: 30.0,
      ),
      icon: Icons.opacity,
      color: Colors.brown,
    ),
    ParameterType.orp: const WaterParameter(
      type: ParameterType.orp,
      name: 'ORP',
      unit: 'mV',
      range: ParameterRange(
        min: -999.0,
        max: 999.0,
        warningLowerThreshold: 200.0,
        warningUpperThreshold: 400.0,
        criticalLowerThreshold: 150.0,
        criticalUpperThreshold: 450.0,
      ),
      icon: Icons.battery_charging_full,
      color: Colors.purple,
    ),
    ParameterType.tds: const WaterParameter(
      type: ParameterType.tds,
      name: 'Total Dissolved Solids',
      unit: 'g/L',
      range: ParameterRange(
        min: 0.0,
        max: 64.0,
        warningLowerThreshold: 15.0,
        warningUpperThreshold: 35.0,
        criticalLowerThreshold: 10.0,
        criticalUpperThreshold: 40.0,
      ),
      icon: Icons.grain,
      color: Colors.grey,
    ),
    ParameterType.depth: const WaterParameter(
      type: ParameterType.depth,
      name: 'Depth',
      unit: 'm',
      range: ParameterRange(
        min: 0.0,
        max: 250.0,
        warningLowerThreshold: 5.0,
        warningUpperThreshold: 100.0,
        criticalLowerThreshold: 2.0,
        criticalUpperThreshold: 150.0,
      ),
      icon: Icons.height,
      color: Colors.indigo,
    ),
    ParameterType.chlorophyll: const WaterParameter(
      type: ParameterType.chlorophyll,
      name: 'Chlorophyll',
      unit: 'μg/L',
      range: ParameterRange(
        min: 0.0,
        max: 400.0,
        warningLowerThreshold: 0.0,
        warningUpperThreshold: 200.0,
        criticalLowerThreshold: 0.0,
        criticalUpperThreshold: 300.0,
      ),
      icon: Icons.grass,
      color: Colors.lightGreen,
    ),
  };
}
