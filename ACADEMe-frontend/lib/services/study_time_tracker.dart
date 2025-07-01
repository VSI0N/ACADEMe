import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudyTimeTracker with WidgetsBindingObserver {
  static final StudyTimeTracker _instance = StudyTimeTracker._internal();
  factory StudyTimeTracker() => _instance;
  StudyTimeTracker._internal();

  DateTime? _sessionStartTime;
  Map<String, double> _weeklyStudyTime = {};
  bool _isInitialized = false;
  List<VoidCallback> _listeners = [];

  // Initialize the tracker
  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    await _loadStudyTimeData();
    _startSession();
    _isInitialized = true;
  }

  // Dispose the tracker
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endSession();
    _isInitialized = false;
  }

  // Add listener for UI updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startSession();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _endSession();
        break;
    }
  }

  void _startSession() {
    _sessionStartTime = DateTime.now();
  }

  void _endSession() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final hours = sessionDuration.inMinutes / 60.0;

      if (hours > 0) {
        _addStudyTime(hours);
      }
      _sessionStartTime = null;
    }
  }

  void _addStudyTime(double hours) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    _weeklyStudyTime[dateKey] = (_weeklyStudyTime[dateKey] ?? 0.0) + hours;
    _saveStudyTimeData();
    _notifyListeners(); // Notify UI to update
  }

  Future<void> _loadStudyTimeData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('study_time_data');

    if (jsonString != null) {
      final Map<String, dynamic> data = json.decode(jsonString);
      _weeklyStudyTime = Map<String, double>.from(
          data.map((key, value) => MapEntry(key, value.toDouble()))
      );
    }
  }

  Future<void> _saveStudyTimeData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_weeklyStudyTime);
    await prefs.setString('study_time_data', jsonString);
  }

  // Public getters for UI
  List<double> getWeeklyData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    List<double> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      weekData.add(_weeklyStudyTime[dateKey] ?? 0.0);
    }

    return weekData;
  }

  double getTodayStudyTime() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _weeklyStudyTime[todayKey] ?? 0.0;
  }

  double getAverageStudyTime() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    double totalTime = 0.0;
    int daysWithData = 0;

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayTime = _weeklyStudyTime[dateKey] ?? 0.0;

      if (dayTime > 0) {
        totalTime += dayTime;
        daysWithData++;
      }
    }

    return daysWithData > 0 ? totalTime / daysWithData : 0.0;
  }

  // Clear all data (for testing or reset)
  Future<void> clearData() async {
    _weeklyStudyTime.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('study_time_data');
    _notifyListeners();
  }
}