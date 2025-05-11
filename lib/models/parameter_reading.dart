import 'package:uuid/uuid.dart';
import 'water_parameter.dart';

class ParameterReading {
  final String id;
  final ParameterType type;
  final double value;
  final DateTime timestamp;
  final String locationId;
  final String notes;

  ParameterReading({
    String? id,
    required this.type,
    required this.value,
    required this.timestamp,
    required this.locationId,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  // Create a copy with updated values
  ParameterReading copyWith({
    String? id,
    ParameterType? type,
    double? value,
    DateTime? timestamp,
    String? locationId,
    String? notes,
  }) {
    return ParameterReading(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      locationId: locationId ?? this.locationId,
      notes: notes ?? this.notes,
    );
  }

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'locationId': locationId,
      'notes': notes,
    };
  }

  // Create from JSON
  factory ParameterReading.fromJson(Map<String, dynamic> json) {
    return ParameterReading(
      id: json['id'],
      type: ParameterType.values[json['type']],
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      locationId: json['locationId'],
      notes: json['notes'],
    );
  }

  // Determine alert status based on thresholds
  AlertStatus getAlertStatus() {
    final param = WaterParameter.parameters[type]!;

    if (value < param.range.criticalLowerThreshold ||
        value > param.range.criticalUpperThreshold) {
      return AlertStatus.critical;
    } else if (value < param.range.warningLowerThreshold ||
        value > param.range.warningUpperThreshold) {
      return AlertStatus.warning;
    } else {
      return AlertStatus.normal;
    }
  }
}

enum AlertStatus { normal, warning, critical }
