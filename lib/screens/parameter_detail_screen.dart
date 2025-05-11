import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/parameter_reading.dart' as param_reading;
import '../models/water_parameter.dart';
import '../services/simulation_service.dart';
import '../widgets/parameter_chart.dart';

class ParameterDetailScreen extends StatefulWidget {
  final ParameterType parameterType;
  final String locationId;

  const ParameterDetailScreen({
    Key? key,
    required this.parameterType,
    required this.locationId,
  }) : super(key: key);

  @override
  State<ParameterDetailScreen> createState() => _ParameterDetailScreenState();
}

class _ParameterDetailScreenState extends State<ParameterDetailScreen> {
  List<param_reading.ParameterReading> _readings = [];
  StreamSubscription? _readingsSubscription;
  Duration _selectedTimeWindow = const Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _subscribeToReadings();
  }

  void _subscribeToReadings() {
    final simulationService = Provider.of<SimulationService>(
      context,
      listen: false,
    );

    _readingsSubscription = simulationService.readingsStream.listen((readings) {
      final filteredReadings = readings
          .where(
            (reading) =>
                reading.type == widget.parameterType &&
                reading.locationId == widget.locationId,
          )
          .toList();

      setState(() {
        _readings = filteredReadings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final parameter = WaterParameter.parameters[widget.parameterType]!;

    return Scaffold(
      appBar: AppBar(title: Text(parameter.name), elevation: 0),
      body: Column(
        children: [
          _buildCurrentValueCard(context),
          _buildTimeWindowSelector(),
          Expanded(
            child: ParameterChart(
              parameterType: widget.parameterType,
              readings: _readings,
              timeWindow: _selectedTimeWindow,
            ),
          ),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentValueCard(BuildContext context) {
    final parameter = WaterParameter.parameters[widget.parameterType]!;
    final latestReading = _readings.isNotEmpty
        ? _readings.reduce(
            (curr, next) =>
                curr.timestamp.isAfter(next.timestamp) ? curr : next,
          )
        : null;

    if (latestReading == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final alertStatus = latestReading.getAlertStatus();
    Color statusColor;
    String statusText;

    switch (alertStatus) {
      case param_reading.AlertStatus.normal:
        statusColor = const Color(0xFF388E3C);
        statusText = 'Normal';
        break;
      case param_reading.AlertStatus.warning:
        statusColor = const Color(0xFFFFA000);
        statusText = 'Warning';
        break;
      case param_reading.AlertStatus.critical:
        statusColor = const Color(0xFFD32F2F);
        statusText = 'Critical';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Value',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(parameter.icon, size: 36, color: parameter.color),
                const SizedBox(width: 12),
                Text(
                  latestReading.value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: parameter.color,
                      ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    parameter.unit,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(latestReading.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildThresholdInfo(context, parameter),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdInfo(BuildContext context, WaterParameter parameter) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildThresholdItem(
              context,
              'Warning Range',
              '${parameter.range.warningLowerThreshold} - ${parameter.range.warningUpperThreshold} ${parameter.unit}',
              const Color(0xFFFFA000),
            ),
            _buildThresholdItem(
              context,
              'Critical Range',
              '${parameter.range.criticalLowerThreshold} - ${parameter.range.criticalUpperThreshold} ${parameter.unit}',
              const Color(0xFFD32F2F),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThresholdItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTimeWindowSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              const Text('Time Window:'),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _timeWindowButton('1h', const Duration(hours: 1)),
                      _timeWindowButton('6h', const Duration(hours: 6)),
                      _timeWindowButton('12h', const Duration(hours: 12)),
                      _timeWindowButton('24h', const Duration(hours: 24)),
                      _timeWindowButton('3d', const Duration(days: 3)),
                      _timeWindowButton('7d', const Duration(days: 7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeWindowButton(String label, Duration duration) {
    final isSelected = _selectedTimeWindow == duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTimeWindow = duration;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? null : Colors.grey.shade200,
          foregroundColor: isSelected ? null : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(40, 30),
          elevation: isSelected ? 2 : 0,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_readings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate statistics
    final sortedReadings = List<param_reading.ParameterReading>.from(_readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final filteredReadings = sortedReadings.where((reading) {
      final cutoffTime = DateTime.now().subtract(_selectedTimeWindow);
      return reading.timestamp.isAfter(cutoffTime);
    }).toList();

    if (filteredReadings.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = filteredReadings.map((r) => r.value).toList();
    final min = values.reduce((curr, next) => curr < next ? curr : next);
    final max = values.reduce((curr, next) => curr > next ? curr : next);
    final avg = values.reduce((a, b) => a + b) / values.length;

    final parameter = WaterParameter.parameters[widget.parameterType]!;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Min',
                  '${min.toStringAsFixed(2)} ${parameter.unit}',
                  Icons.arrow_downward,
                ),
                _buildStatItem(
                  context,
                  'Average',
                  '${avg.toStringAsFixed(2)} ${parameter.unit}',
                  Icons.equalizer,
                ),
                _buildStatItem(
                  context,
                  'Max',
                  '${max.toStringAsFixed(2)} ${parameter.unit}',
                  Icons.arrow_upward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    super.dispose();
  }
}
