import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class StudyTimeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(16),
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
          SizedBox(height: 8),
          Text(
            "2h 45m",
            style: TextStyle(
              color: const Color.fromARGB(193, 255, 255, 255),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(height: 170, width: double.infinity, child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        backgroundColor: Colors.transparent,
        barGroups: [
          for (int i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: (2 + i).toDouble(),
                  color: Colors.yellow,
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
              getTitlesWidget: (value, meta) {
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
                return Text(
                  ["M", "T", "W", "T", "F", "S", "S"][value.toInt()],
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
      ),
    );
  }
}