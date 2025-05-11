import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/simulation_service.dart';
import 'services/database_service.dart';
import 'services/alert_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final databaseService = DatabaseService();
  final alertService = AlertService();
  await alertService.initialize();

  // Default location ID - in a real app, this would be configurable
  const defaultLocationId = 'location-001';
  final simulationService = SimulationService(locationId: defaultLocationId);

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AlertService>.value(value: alertService),
        Provider<SimulationService>.value(value: simulationService),
      ],
      child: const AquacultureMonitoringApp(),
    ),
  );
}

class AquacultureMonitoringApp extends StatelessWidget {
  const AquacultureMonitoringApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquaculture Monitoring',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
