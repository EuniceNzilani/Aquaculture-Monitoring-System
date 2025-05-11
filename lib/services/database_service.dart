import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/parameter_reading.dart';
import '../models/water_parameter.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'parameter_readings';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = path.join(
      documentsDirectory.path,
      'aquaculture_monitoring.db',
    );

    return await openDatabase(dbPath, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        value REAL NOT NULL,
        timestamp TEXT NOT NULL,
        locationId TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT,
        timestamp TEXT NOT NULL,
        locationId TEXT NOT NULL,
        userId TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Create indices for faster queries
    await db.execute(
      'CREATE INDEX idx_readings_timestamp ON $tableName (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_locationId ON $tableName (locationId)',
    );
    await db.execute('CREATE INDEX idx_readings_type ON $tableName (type)');
  }

  // Save a list of readings to the database
  Future<void> saveReadings(List<ParameterReading> readings) async {
    final db = await database;
    final batch = db.batch();

    for (final reading in readings) {
      batch.insert(
        tableName,
        reading.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Get readings for a specific parameter and location within a time range
  Future<List<ParameterReading>> getReadings({
    required ParameterType type,
    required String locationId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'type = ? AND locationId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        type.index,
        locationId,
        startTime.toIso8601String(),
        endTime.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ParameterReading.fromJson(maps[i]);
    });
  }

  // Get latest readings for all parameters at a location
  Future<List<ParameterReading>> getLatestReadings(String locationId) async {
    final db = await database;
    final List<ParameterReading> result = [];

    for (final type in ParameterType.values) {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'type = ? AND locationId = ?',
        whereArgs: [type.index, locationId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        result.add(ParameterReading.fromJson(maps.first));
      }
    }

    return result;
  }

  // Get readings for daily averages
  Future<List<Map<String, dynamic>>> getDailyAverages({
    required ParameterType type,
    required String locationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    // SQLite date functions to group by day
    const query = '''
      SELECT 
        strftime('%Y-%m-%d', timestamp) as day, 
        AVG(value) as average
      FROM $tableName
      WHERE type = ? AND locationId = ? AND timestamp BETWEEN ? AND ?
      GROUP BY day
      ORDER BY day
    ''';

    final List<Map<String, dynamic>> results = await db.rawQuery(query, [
      type.index,
      locationId,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return results;
  }

  // Delete old readings to manage database size
  Future<int> deleteOldReadings(DateTime cutoffDate) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Export readings to JSON
  Future<String> exportReadingsToJson({
    required String locationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'locationId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        locationId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return jsonEncode(maps);
  }

  // Save a pollution report
  Future<void> saveReport({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    required DateTime timestamp,
    required String locationId,
    required String userId,
    required String status,
  }) async {
    final db = await database;

    await db.insert(
        'reports',
        {
          'id': id,
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'timestamp': timestamp.toIso8601String(),
          'locationId': locationId,
          'userId': userId,
          'status': status,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all reports
  Future<List<Map<String, dynamic>>> getReports() async {
    final db = await database;
    return await db.query('reports', orderBy: 'timestamp DESC');
  }
}
