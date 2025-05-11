import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/parameter_reading.dart';
import '../models/water_parameter.dart';
import '../theme/app_theme.dart';

class ParameterChart extends StatelessWidget {
  final ParameterType parameterType;
  final List<ParameterReading> readings;
  final Duration timeWindow;

  const ParameterChart({
    Key? key,
    required this.parameterType,
    required this.readings,
    this.timeWindow = const Duration(hours: 1),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final parameter = WaterParameter.parameters[parameterType]!;
    final sortedReadings = _getSortedFilteredReadings();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent ${parameter.name} Readings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Last ${_formatTimeWindow(timeWindow)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              _createLineChartData(sortedReadings, parameter, context),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(parameter),
        ],
      ),
    );
  }

  List<ParameterReading> _getSortedFilteredReadings() {
    final now = DateTime.now();
    final cutoffTime = now.subtract(timeWindow);

    return readings
        .where(
          (reading) =>
              reading.type == parameterType &&
              reading.timestamp.isAfter(cutoffTime),
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  LineChartData _createLineChartData(
    List<ParameterReading> sortedReadings,
    WaterParameter parameter,
    BuildContext context,
  ) {
    final spots = sortedReadings.map((reading) {
      return FlSpot(
        reading.timestamp.millisecondsSinceEpoch.toDouble(),
        reading.value,
      );
    }).toList();

    // If we have fewer than 2 points, add a dummy point to avoid rendering issues
    if (spots.length < 2) {
      final dummyTime = sortedReadings.first.timestamp.add(
        const Duration(minutes: 10),
      );
      spots.add(
        FlSpot(
          dummyTime.millisecondsSinceEpoch.toDouble(),
          sortedReadings.first.value,
        ),
      );
    }

    // Calculate min/max for better visualization
    double minY = parameter.range.min;
    double maxY = parameter.range.max;

    // Ensure critical thresholds are visible
    minY = minY.clamp(
      parameter.range.criticalLowerThreshold -
          (parameter.range.max - parameter.range.min) * 0.1,
      parameter.range.criticalLowerThreshold,
    );

    maxY = maxY.clamp(
      parameter.range.criticalUpperThreshold,
      parameter.range.criticalUpperThreshold +
          (parameter.range.max - parameter.range.min) * 0.1,
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: _calculateInterval(minY, maxY),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                value.toInt(),
              );
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('HH:mm').format(date),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            },
            interval: _calculateTimeInterval(),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: AppTheme.textSecondaryColor, width: 1),
          left: BorderSide(color: AppTheme.textSecondaryColor, width: 1),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      ),
      minX: sortedReadings.first.timestamp.millisecondsSinceEpoch.toDouble(),
      maxX: sortedReadings.last.timestamp.millisecondsSinceEpoch.toDouble(),
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor:
              Colors.black.withAlpha(204), // 0.8 opacity = 204 alpha
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                touchedSpot.x.toInt(),
              );
              return LineTooltipItem(
                '${DateFormat('HH:mm:ss').format(date)}\n${touchedSpot.y.toStringAsFixed(2)} ${parameter.unit}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // Warning lower threshold
          HorizontalLine(
            y: parameter.range.warningLowerThreshold,
            color:
                AppTheme.warningColor.withAlpha(179), // 0.7 opacity = 179 alpha
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          // Warning upper threshold
          HorizontalLine(
            y: parameter.range.warningUpperThreshold,
            color:
                AppTheme.warningColor.withAlpha(179), // 0.7 opacity = 179 alpha
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          // Critical lower threshold
          HorizontalLine(
            y: parameter.range.criticalLowerThreshold,
            color: AppTheme.criticalColor
                .withAlpha(179), // 0.7 opacity = 179 alpha
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          // Critical upper threshold
          HorizontalLine(
            y: parameter.range.criticalUpperThreshold,
            color: AppTheme.criticalColor
                .withAlpha(179), // 0.7 opacity = 179 alpha
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: parameter.color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length < 30, // Only show dots if we have few readings
          ),
          belowBarData: BarAreaData(
            show: true,
            color: parameter.color.withAlpha(51), // 0.2 opacity = 51 alpha
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(WaterParameter parameter) {
    return Wrap(
      spacing: 16,
      children: [
        _legendItem(parameter.color, 'Readings'),
        _legendItem(AppTheme.warningColor, 'Warning Thresholds'),
        _legendItem(AppTheme.criticalColor, 'Critical Thresholds'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 4, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;

    if (range <= 1) return 0.1;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    if (range <= 500) return 50;

    return 100;
  }

  double _calculateTimeInterval() {
    if (timeWindow.inHours <= 1) {
      // For 1 hour, show 10-minute intervals
      return 10 * 60 * 1000;
    } else if (timeWindow.inHours <= 6) {
      // For up to 6 hours, show 30-minute intervals
      return 30 * 60 * 1000;
    } else if (timeWindow.inHours <= 24) {
      // For up to 24 hours, show 1-hour intervals
      return 60 * 60 * 1000;
    } else {
      // For more than 24 hours, show 6-hour intervals
      return 6 * 60 * 60 * 1000;
    }
  }

  String _formatTimeWindow(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inDays} days';
    }
  }
}
