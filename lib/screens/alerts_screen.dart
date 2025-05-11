import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parameter_reading.dart' as param_reading;
import '../services/alert_service.dart';
import '../widgets/alert_list.dart';
import 'parameter_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  StreamSubscription? _alertsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToAlerts();
  }

  void _subscribeToAlerts() {
    final alertService = Provider.of<AlertService>(context, listen: false);

    _alertsSubscription = alertService.alertsStream.listen((alerts) {
      setState(() {
        _alerts = alerts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: AlertList(alerts: _alerts, onTap: _navigateToParameterDetail),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor water quality parameter alerts in real-time',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildAlertSummary(),
        ],
      ),
    );
  }

  Widget _buildAlertSummary() {
    final criticalCount = _alerts
        .where((a) => a.status == param_reading.AlertStatus.critical)
        .length;
    final warningCount = _alerts
        .where((a) => a.status == param_reading.AlertStatus.warning)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Critical',
            criticalCount.toString(),
            Icons.error_outline,
            const Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Warning',
            warningCount.toString(),
            Icons.warning_amber_outlined,
            const Color(0xFFFFA000),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToParameterDetail(Alert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParameterDetailScreen(
          parameterType: alert.parameterType,
          locationId: alert.locationId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
