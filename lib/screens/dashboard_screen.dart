import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parameter_reading.dart' as param_reading;
import '../models/water_parameter.dart';
import '../services/simulation_service.dart';
import '../services/database_service.dart';
import '../services/alert_service.dart';
import '../widgets/parameter_card.dart';
import 'parameter_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _locationId = 'location-001';
  List<param_reading.ParameterReading> _latestReadings = [];
  List<Alert> _currentAlerts = [];
  StreamSubscription? _readingsSubscription;
  StreamSubscription? _alertsSubscription;
  bool _isLoading = true;
  Timer? _databaseSaveTimer;

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    _startSimulation();
  }

  void _initSubscriptions() {
    final simulationService =
        Provider.of<SimulationService>(context, listen: false);
    final alertService = Provider.of<AlertService>(context, listen: false);

    // Subscribe to readings
    _readingsSubscription = simulationService.readingsStream.listen((readings) {
      setState(() {
        _latestReadings = _getLatestReadings(readings);
        _isLoading = false;
      });

      // Check for alerts
      for (final reading in _latestReadings) {
        alertService.checkReadingForAlert(reading);
      }
    });

    // Subscribe to alerts
    _alertsSubscription = alertService.alertsStream.listen((alerts) {
      setState(() {
        _currentAlerts = alerts;
      });
    });
  }

  void _startSimulation() {
    final simulationService =
        Provider.of<SimulationService>(context, listen: false);
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    // Start the simulation
    simulationService.startSimulation(intervalSeconds: 3);

    // Save readings to database every 30 seconds
    _databaseSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final readings = simulationService.currentReadings;
      if (readings.isNotEmpty) {
        await databaseService.saveReadings(readings);
      }
    });
  }

  List<param_reading.ParameterReading> _getLatestReadings(
      List<param_reading.ParameterReading> allReadings) {
    final Map<ParameterType, param_reading.ParameterReading> latestReadings =
        {};

    for (final reading in allReadings) {
      if (reading.locationId == _locationId) {
        final existingReading = latestReadings[reading.type];
        if (existingReading == null ||
            reading.timestamp.isAfter(existingReading.timestamp)) {
          latestReadings[reading.type] = reading;
        }
      }
    }

    return latestReadings.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final simulationService =
            Provider.of<SimulationService>(context, listen: false);
        simulationService.startSimulation(intervalSeconds: 3);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Column(
        children: [
          _buildAlertBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                _buildStatusSummary(),
                const SizedBox(height: 16),
                _buildParameterGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    if (_currentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final criticalCount = _currentAlerts
        .where((a) => a.status == param_reading.AlertStatus.critical)
        .length;
    final warningCount = _currentAlerts
        .where((a) => a.status == param_reading.AlertStatus.warning)
        .length;

    String message;
    Color color;
    IconData icon;

    if (criticalCount > 0) {
      message =
          'Critical Alerts: $criticalCount | Warning Alerts: $warningCount';
      color = const Color(0xFFD32F2F);
      icon = Icons.error_outline;
    } else {
      message = 'Warning Alerts: $warningCount';
      color = const Color(0xFFFFA000);
      icon = Icons.warning_amber_outlined;
    }

    return Material(
      color: color,
      child: InkWell(
        onTap: () {
          // Navigate to alerts tab
          final homeScreen =
              context.findAncestorWidgetOfExactType<HomeScreen>();
          if (homeScreen != null) {
            // Implementation to navigate to alerts tab
            // This will be implemented later
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    // Count parameters by status
    int normalCount = 0;
    int warningCount = 0;
    int criticalCount = 0;

    for (final reading in _latestReadings) {
      switch (reading.getAlertStatus()) {
        case param_reading.AlertStatus.normal:
          normalCount++;
          break;
        case param_reading.AlertStatus.warning:
          warningCount++;
          break;
        case param_reading.AlertStatus.critical:
          criticalCount++;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Water Quality Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusIndicator(
                    context,
                    Icons.check_circle_outline,
                    normalCount.toString(),
                    'Normal',
                    const Color(0xFF388E3C),
                  ),
                  _buildStatusIndicator(
                    context,
                    Icons.warning_amber_outlined,
                    warningCount.toString(),
                    'Warning',
                    const Color(0xFFFFA000),
                  ),
                  _buildStatusIndicator(
                    context,
                    Icons.error_outline,
                    criticalCount.toString(),
                    'Critical',
                    const Color(0xFFD32F2F),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildParameterGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      childAspectRatio: 0.9,
      children: _latestReadings.map((reading) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ParameterCard(
            reading: reading,
            onTap: () => _navigateToParameterDetail(reading),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToParameterDetail(param_reading.ParameterReading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParameterDetailScreen(
          parameterType: reading.type,
          locationId: _locationId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    _alertsSubscription?.cancel();
    _databaseSaveTimer?.cancel();
    super.dispose();
  }
}

// Placeholder class for HomeScreen if it hasn't been created yet
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aquaculture Monitoring'),
      ),
      body: const Center(
        child: Text('HomeScreen implementation pending'),
      ),
    );
  }
}
