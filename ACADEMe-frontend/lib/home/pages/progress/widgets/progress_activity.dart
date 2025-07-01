import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class ActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrap entire content
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyStreak(context),
            const SizedBox(height: 35),
            _buildHistorySection(context),
          ],
        ),
      ),
    );
  }

  // All other methods remain unchanged...
  Widget _buildWeeklyStreak(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.getTranslatedText(context, 'Weekly Streak'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["M", "T", "W", "T", "F", "S", "S"]
                .map((day) => _buildStreakDay(day, day == "M" || day == "T"))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDay(String day, bool isActive) {
    return Column(
      children: [
        Text(day,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 6),
        CircleAvatar(
          backgroundColor:
          isActive ? Colors.black : const Color.fromARGB(136, 0, 0, 0),
          child: isActive
              ? const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 30,
          )
              : null,
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.getTranslatedText(context, 'History'),
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 2", 3),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Quiz')} - 2", 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 1", 3),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Daily Streak'),
            L10n.getTranslatedText(context, 'Attendance'),
            L10n.getTranslatedText(context, 'Profile'), 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Quiz')} - 2", 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 1", 3),
      ],
    );
  }

  Widget _buildHistoryItem(
      String title, String subtitle, String detail, int points) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              Text(
                detail,
                style: TextStyle(color: AcademeTheme.appColor, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              Text("+$points",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 30),
            ],
          ),
        ],
      ),
    );
  }
}