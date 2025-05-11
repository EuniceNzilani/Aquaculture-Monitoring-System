import 'dart:async';
import 'package:flutter/material.dart'; // Required for Color class
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import '../models/parameter_reading.dart' as param_reading;
import '../models/water_parameter.dart';

class AlertService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<List<Alert>> _alertsSubject =
      BehaviorSubject<List<Alert>>.seeded([]);

  Future<void> initialize() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _notifications.initialize(initSettings);
  }

  // Stream of alerts for UI to listen to
  Stream<List<Alert>> get alertsStream => _alertsSubject.stream;
  List<Alert> get currentAlerts => _alertsSubject.value;

  // Check if any reading generates an alert
  void checkReadingForAlert(param_reading.ParameterReading reading) {
    final status = reading.getAlertStatus();

    if (status != param_reading.AlertStatus.normal) {
      // Using parameter for the notification
      final alert = Alert(
        id: reading.id,
        parameterType: reading.type,
        value: reading.value,
        timestamp: reading.timestamp,
        locationId: reading.locationId,
        status: status,
      );

      final existingIndex = _alertsSubject.value.indexWhere(
        (a) =>
            a.parameterType == reading.type &&
            a.locationId == reading.locationId,
      );

      List<Alert> updatedAlerts = [..._alertsSubject.value];

      if (existingIndex >= 0) {
        // Update existing alert
        updatedAlerts[existingIndex] = alert;
      } else {
        // Add new alert
        updatedAlerts.add(alert);

        // Send notification for new alert
        _sendNotification(alert);
      }

      _alertsSubject.add(updatedAlerts);
    } else {
      // Remove alert if parameter is back to normal
      final existingIndex = _alertsSubject.value.indexWhere(
        (a) =>
            a.parameterType == reading.type &&
            a.locationId == reading.locationId,
      );

      if (existingIndex >= 0) {
        List<Alert> updatedAlerts = [..._alertsSubject.value];
        updatedAlerts.removeAt(existingIndex);
        _alertsSubject.add(updatedAlerts);
      }
    }
  }

  Future<void> _sendNotification(Alert alert) async {
    final parameter = WaterParameter.parameters[alert.parameterType]!;
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'aquaculture_monitoring_channel',
      'Aquaculture Monitoring Alerts',
      channelDescription: 'Notifications for water quality parameter alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: alert.status == param_reading.AlertStatus.critical
          ? const Color(0xFFFF0000)
          : const Color(0xFFFF9800),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = alert.status == param_reading.AlertStatus.critical
        ? 'CRITICAL ALERT: ${parameter.name}'
        : 'WARNING: ${parameter.name}';

    final String body =
        'Current value: ${alert.value.toStringAsFixed(2)} ${parameter.unit} '
        '(${alert.status == param_reading.AlertStatus.critical ? 'Critical' : 'Warning'} level reached)';

    await _notifications.show(alert.hashCode, title, body, notificationDetails);
  }

  void clearAlerts() {
    _alertsSubject.add([]);
  }

  void dispose() {
    _alertsSubject.close();
  }
}

class Alert {
  final String id;
  final ParameterType parameterType;
  final double value;
  final DateTime timestamp;
  final String locationId;
  final param_reading.AlertStatus status;

  Alert({
    required this.id,
    required this.parameterType,
    required this.value,
    required this.timestamp,
    required this.locationId,
    required this.status,
  });
}
