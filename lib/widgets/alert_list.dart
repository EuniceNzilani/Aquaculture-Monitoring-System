import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/water_parameter.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';
import '../models/parameter_reading.dart' as param_reading;

class AlertList extends StatelessWidget {
  final List<Alert> alerts;
  final Function(Alert) onTap;

  const AlertList({Key? key, required this.alerts, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No active alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'All parameters are within normal ranges',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final criticalAlerts = alerts
        .where((a) => a.status == param_reading.AlertStatus.critical)
        .toList();
    final warningAlerts = alerts
        .where((a) => a.status == param_reading.AlertStatus.warning)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (criticalAlerts.isNotEmpty) ...[
          const _AlertSectionHeader(
            title: 'Critical Alerts',
            color: AppTheme.criticalColor,
            icon: Icons.error_outline,
          ),
          const SizedBox(height: 8),
          ...criticalAlerts.map(
            (alert) => _AlertItem(alert: alert, onTap: () => onTap(alert)),
          ),
          const SizedBox(height: 16),
        ],
        if (warningAlerts.isNotEmpty) ...[
          const _AlertSectionHeader(
            title: 'Warning Alerts',
            color: AppTheme.warningColor,
            icon: Icons.warning_amber_outlined,
          ),
          const SizedBox(height: 8),
          ...warningAlerts.map(
            (alert) => _AlertItem(alert: alert, onTap: () => onTap(alert)),
          ),
        ],
      ],
    );
  }
}

class _AlertSectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _AlertSectionHeader({
    Key? key,
    required this.title,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _AlertItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertItem({Key? key, required this.alert, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final parameter = WaterParameter.parameters[alert.parameterType]!;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.status == param_reading.AlertStatus.critical
              ? AppTheme.criticalColor
              : AppTheme.warningColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(parameter.icon, color: parameter.color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parameter.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: ${alert.value.toStringAsFixed(2)} ${parameter.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    if (alert.status == param_reading.AlertStatus.critical)
                      Text(
                        'Outside critical range: ${parameter.range.criticalLowerThreshold} - ${parameter.range.criticalUpperThreshold} ${parameter.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.criticalColor,
                            ),
                      )
                    else
                      Text(
                        'Outside warning range: ${parameter.range.warningLowerThreshold} - ${parameter.range.warningUpperThreshold} ${parameter.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                            ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    alert.status == param_reading.AlertStatus.critical
                        ? Icons.error
                        : Icons.warning,
                    color: alert.status == param_reading.AlertStatus.critical
                        ? AppTheme.criticalColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm').format(alert.timestamp),
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
}
