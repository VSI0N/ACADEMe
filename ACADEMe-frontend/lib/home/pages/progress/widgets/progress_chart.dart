import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/services/study_time_tracker.dart';

class StudyTimeCard extends StatefulWidget {
  @override
  _StudyTimeCardState createState() => _StudyTimeCardState();
}

class _StudyTimeCardState extends State<StudyTimeCard> {
  final StudyTimeTracker _tracker = StudyTimeTracker();

  @override
  void initState() {
    super.initState();
    // Listen to tracker updates
    _tracker.addListener(_onTrackerUpdate);
  }

  @override
  void dispose() {
    _tracker.removeListener(_onTrackerUpdate);
    super.dispose();
  }

  void _onTrackerUpdate() {
    // Update UI when tracker data changes
    if (mounted) {
      setState(() {});
    }
  }

  String _formatTime(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else {
      final wholeHours = hours.floor();
      final minutes = ((hours - wholeHours) * 60).round();
      if (minutes == 0) {
        return '${wholeHours}h';
      } else {
        return '${wholeHours}h ${minutes}m';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Get data from global tracker
    final weeklyData = _tracker.getWeeklyData();
    final todayStudyTime = _tracker.getTodayStudyTime();
    final averageStudyTime = _tracker.getAverageStudyTime();
    final maxValue = weeklyData.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                L10n.getTranslatedText(context, 'Average Study Time'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'This Week'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Today: ${_formatTime(todayStudyTime)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: _buildBarChart(weeklyData, maxValue > 0 ? maxValue * 1.2 : 5),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<double> weeklyData, double maxY) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        backgroundColor: Colors.transparent,
        barGroups: [
          for (int i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: weeklyData[i],
                  color: weeklyData[i] > 0 ? Colors.yellow : Colors.yellow.withOpacity(0.3),
                  width: 22,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY > 10 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0', style: TextStyle(color: Colors.white, fontSize: 12));
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ["M", "T", "W", "T", "F", "S", "S"];
                return Text(
                  days[value.toInt()],
                  style: TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(20), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white, width: 1),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][group.x];
              return BarTooltipItem(
                '$day\n${_formatTime(rod.toY)}',
                TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}