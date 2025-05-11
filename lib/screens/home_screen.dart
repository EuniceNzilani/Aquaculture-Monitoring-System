import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AlertsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = ['Dashboard', 'Alerts', 'History', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.science),
              onPressed: _showSimulationEventDialog,
              tooltip: 'Simulate Event',
            ),
          if (_currentIndex != 3) // Don't show on settings screen
            IconButton(
              icon: const Icon(Icons.report_problem),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
              tooltip: 'Report Incident',
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showSimulationEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Environmental Event'),
        content: const Text(
          'This will simulate an environmental event for testing the monitoring system. '
          'Choose an event type:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateEvent('storm');
            },
            child: const Text('Storm'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateEvent('algalBloom');
            },
            child: const Text('Algal Bloom'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateEvent('heatwave');
            },
            child: const Text('Heatwave'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateEvent('oxygenDepletion');
            },
            child: const Text('Oxygen Depletion'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToNormal();
            },
            child: const Text('Reset to Normal'),
          ),
        ],
      ),
    );
  }

  void _simulateEvent(String eventType) {
    // This would be implemented to call the simulation service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulating $eventType event'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _resetToNormal() {
    // This would be implemented to call the simulation service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to normal conditions'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
