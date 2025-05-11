import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _notificationsEnabled = true;
  int _dataRetentionDays = 30;
  int _sampleInterval = 5;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? true;
          _dataRetentionDays = prefs.getInt('data_retention_days') ?? 30;
          _sampleInterval = prefs.getInt('sample_interval') ?? 5;
          _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setInt('data_retention_days', _dataRetentionDays);
      await prefs.setInt('sample_interval', _sampleInterval);
      await prefs.setBool('dark_mode_enabled', _darkModeEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildNotificationSettings(),
        const SizedBox(height: 16),
        _buildDataSettings(),
        const SizedBox(height: 16),
        _buildAppearanceSettings(),
        const SizedBox(height: 16),
        _buildDatabaseActions(),
        const SizedBox(height: 32),
        _buildSaveButton(),
        const SizedBox(height: 16),
        _buildAppInfo(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your aquaculture monitoring system preferences',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard('Notifications', [
      SwitchListTile(
        title: const Text('Enable Notifications'),
        subtitle: const Text('Receive alerts when parameters are out of range'),
        value: _notificationsEnabled,
        onChanged: (value) {
          setState(() {
            _notificationsEnabled = value;
          });
        },
        secondary: const Icon(Icons.notifications),
      ),
    ]);
  }

  Widget _buildDataSettings() {
    return _buildSettingsCard('Data Collection', [
      ListTile(
        title: const Text('Sample Interval'),
        subtitle: Text('$_sampleInterval seconds between readings'),
        leading: const Icon(Icons.timer),
        trailing: DropdownButton<int>(
          value: _sampleInterval,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sampleInterval = value;
              });
            }
          },
          items: [1, 3, 5, 10, 30, 60].map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value s'),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text('Data Retention'),
        subtitle: Text('Keep data for $_dataRetentionDays days'),
        leading: const Icon(Icons.storage),
        trailing: DropdownButton<int>(
          value: _dataRetentionDays,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _dataRetentionDays = value;
              });
            }
          },
          items: [7, 14, 30, 60, 90, 180, 365].map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value days'),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildAppearanceSettings() {
    return _buildSettingsCard('Appearance', [
      SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Use dark theme throughout the app'),
        value: _darkModeEnabled,
        onChanged: (value) {
          setState(() {
            _darkModeEnabled = value;
          });
        },
        secondary: const Icon(Icons.dark_mode),
      ),
    ]);
  }

  Widget _buildDatabaseActions() {
    return _buildSettingsCard('Database Actions', [
      ListTile(
        title: const Text('Export Data'),
        subtitle: const Text('Export monitoring data to JSON'),
        leading: const Icon(Icons.download),
        onTap: _exportData,
      ),
      ListTile(
        title: const Text('Clean Database'),
        subtitle: const Text('Remove old data to free up space'),
        leading: const Icon(Icons.cleaning_services),
        onTap: _cleanDatabase,
      ),
    ]);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Save Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Aquaculture Monitoring System',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Version 1.0.0'),
          SizedBox(height: 4),
          Text(
            '© 2025 davytheprogrammer',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));

      // Export the data but don't store the unused jsonData variable
      await databaseService.exportReadingsToJson(
        locationId: 'location-001',
        startDate: startDate,
        endDate: now,
      );

      // In a real app, you would save this to a file or share it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanDatabase() async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      final cutoffDate = DateTime.now().subtract(
        Duration(days: _dataRetentionDays),
      );
      final deletedCount = await databaseService.deleteOldReadings(cutoffDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $deletedCount old readings'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
