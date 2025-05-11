import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parameter_reading.dart' as param_reading;
import '../models/water_parameter.dart';
import '../theme/app_theme.dart';

class ParameterCard extends StatelessWidget {
  final param_reading.ParameterReading reading;
  final VoidCallback? onTap;

  const ParameterCard({Key? key, required this.reading, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final parameter = WaterParameter.parameters[reading.type]!;
    final alertStatus = reading.getAlertStatus();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(alertStatus),
          width: alertStatus != param_reading.AlertStatus.normal ? 2.0 : 0.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(parameter.icon, color: parameter.color, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        parameter.name,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: parameter.color,
                            ),
                      ),
                    ],
                  ),
                  _buildStatusIndicator(alertStatus),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reading.value.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    ' ${parameter.unit}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Range: ${parameter.range.warningLowerThreshold} - ${parameter.range.warningUpperThreshold} ${parameter.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('HH:mm:ss').format(reading.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(param_reading.AlertStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case param_reading.AlertStatus.critical:
        icon = Icons.error;
        color = AppTheme.criticalColor;
        break;
      case param_reading.AlertStatus.warning:
        icon = Icons.warning;
        color = AppTheme.warningColor;
        break;
      case param_reading.AlertStatus.normal:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  Color _getStatusColor(param_reading.AlertStatus status) {
    switch (status) {
      case param_reading.AlertStatus.critical:
        return AppTheme.criticalColor;
      case param_reading.AlertStatus.warning:
        return AppTheme.warningColor;
      case param_reading.AlertStatus.normal:
        return Colors.transparent;
    }
  }
}
