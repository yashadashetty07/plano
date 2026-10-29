import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/activity_log.dart';
import '../models/habit.dart';
import '../models/learning_session.dart';
import '../models/health_record.dart';
import '../models/assistant_action.dart';
import '../services/supabase_service.dart';
import '../services/health_connect_service.dart';
import '../services/assistant_service.dart';
import '../services/report_service.dart';

class AppProvider with ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final HealthConnectService _healthService = HealthConnectService();
  final AssistantService _assistantService = AssistantService();
  final _uuid = const Uuid();

  int _selectedNavigationIndex = 0;
  int get selectedNavigationIndex => _selectedNavigationIndex;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasLoadedUserData = false;
  bool get hasLoadedUserData => _hasLoadedUserData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Profile? _profile;
  Profile? get profile => _profile;

  List<Project> _projects = [];
  List<Project> get projects => _projects;

  List<PlanoTask> _tasks = [];
  List<PlanoTask> get tasks => _tasks;

  List<ActivityLog> _activities = [];
  List<ActivityLog> get activities => _activities;

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  List<HabitCheckin> _checkins = [];
  List<HabitCheckin> get checkins => _checkins;

  List<LearningSession> _learningSessions = [];
  List<LearningSession> get learningSessions => _learningSessions;

  List<HealthSummary> _healthSummaries = [];
  List<HealthSummary> get healthSummaries => _healthSummaries;

  IntegrationConnection? _healthIntegration;
  IntegrationConnection? get healthIntegration => _healthIntegration;

  HealthSdkStatus _healthSdkStatus = HealthSdkStatus.notSupported;
  HealthSdkStatus get healthSdkStatus => _healthSdkStatus;

  final List<AssistantAction> _assistantHistory = [];
  List<AssistantAction> get assistantHistory => List.unmodifiable(_assistantHistory);

  // Filters
  String _activityCategoryFilter = 'all';
  String get activityCategoryFilter => _activityCategoryFilter;

  String _taskStatusFilter = 'all';
  String get taskStatusFilter => _taskStatusFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  DateTimeRange _reportDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  DateTimeRange get reportDateRange => _reportDateRange;

  void setNavigationIndex(int index) {
    _selectedNavigationIndex = index;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setActivityCategoryFilter(String category) {
    _activityCategoryFilter = category;
    notifyListeners();
  }

  void setTaskStatusFilter(String status) {
    _taskStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setReportDateRange(DateTimeRange range) {
    _reportDateRange = range;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _db.getProfile();
      _projects = await _db.getProjects();
      _tasks = await _db.getTasks();
      _activities = await _db.getActivityLogs();
      _habits = await _db.getHabits();
      _checkins = await _db.getCheckins();
      _learningSessions = await _db.getLearningSessions();
      _healthSummaries = await _db.getHealthSummaries();
      _healthIntegration = await _db.getIntegrationConnection('health_connect');

      // Check Health SDK
      _healthSdkStatus = await _healthService.checkAvailability();
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
    } finally {
      _isLoading = false;
      _hasLoadedUserData = true;
      notifyListeners();
    }
  }

  // Task Operations
  Future<void> addTask(PlanoTask task) async {
    await _db.createTask(task);
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<void> toggleTaskStatus(PlanoTask task) async {
    final nextStatus = task.isCompleted ? 'todo' : 'completed';
    final completedAt = nextStatus == 'completed' ? DateTime.now() : null;
    final updated = task.copyWith(status: nextStatus, completedAt: completedAt);
    await _db.updateTask(updated);
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  // Project Operations
  Future<void> addProject(Project project) async {
    await _db.createProject(project);
    _projects = await _db.getProjects();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
    _projects = await _db.getProjects();
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  // Activity Operations
  Future<void> addActivity(ActivityLog activity) async {
    await _db.createActivityLog(activity);
    _activities = await _db.getActivityLogs();
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    await _db.deleteActivityLog(id);
    _activities = await _db.getActivityLogs();
    notifyListeners();
  }

  // Habit Operations
  Future<void> addHabit(Habit habit) async {
    await _db.createHabit(habit);
    _habits = await _db.getHabits();
    notifyListeners();
  }

  Future<void> toggleHabitCheckin(String habitId, DateTime date) async {
    await _db.toggleHabitCheckin(habitId, date);
    _checkins = await _db.getCheckins();
    notifyListeners();
  }

  bool isHabitChecked(String habitId, DateTime date) {
    final dateStr = date.toIso8601String().split('T').first;
    return _checkins.any((c) =>
        c.habitId == habitId &&
        c.checkinDate.toIso8601String().split('T').first == dateStr);
  }

  int getHabitStreak(String habitId) {
    int streak = 0;
    var checkDate = DateTime.now();
    final today = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // If checked today, start counting from today; otherwise if not checked today, check yesterday
    if (isHabitChecked(habitId, today)) {
      streak++;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      checkDate = today.subtract(const Duration(days: 1));
      if (!isHabitChecked(habitId, checkDate)) {
        return 0;
      }
    }

    while (isHabitChecked(habitId, checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // Learning Operations
  Future<void> addLearningSession(LearningSession session) async {
    await _db.createLearningSession(session);
    _learningSessions = await _db.getLearningSessions();
    notifyListeners();
  }

  Future<void> deleteLearningSession(String id) async {
    await _db.deleteLearningSession(id);
    _learningSessions = await _db.getLearningSessions();
    notifyListeners();
  }

  // Health Sync
  Future<void> syncHealthData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final raw = await _healthService.getDailySummaries(start: start, end: now);

      final steps = (raw['steps'] as num?)?.toInt() ?? 0;
      final workoutMinutes = (raw['workoutMinutes'] as num?)?.toInt() ?? 0;
      final source = raw['source'] as String? ?? 'Health Connect';

      final summary = HealthSummary(
        id: _uuid.v4(),
        userId: _db.currentUserId,
        date: start,
        stepCount: steps,
        workoutCount: workoutMinutes > 0 ? 1 : 0,
        workoutDurationMinutes: workoutMinutes,
        source: source,
        lastSyncedAt: now,
      );

      await _db.upsertHealthSummary(summary);
      _healthSummaries = await _db.getHealthSummaries();

      final conn = IntegrationConnection(
        id: _healthIntegration?.id ?? _uuid.v4(),
        userId: _db.currentUserId,
        provider: 'health_connect',
        isConnected: true,
        permissionsGranted: ['READ_STEPS', 'READ_EXERCISE'],
        lastSyncAt: now,
        updatedAt: now,
      );
      await _db.updateIntegrationConnection(conn);
      _healthIntegration = conn;
    } catch (e) {
      _errorMessage = 'Health sync error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHealthData() async {
    await _db.deleteHealthData();
    _healthSummaries = await _db.getHealthSummaries();
    notifyListeners();
  }

  void clearUserData() {
    _profile = null;
    _projects = [];
    _tasks = [];
    _activities = [];
    _habits = [];
    _checkins = [];
    _learningSessions = [];
    _healthSummaries = [];
    _healthIntegration = null;
    _assistantHistory.clear();
    _hasLoadedUserData = false;
    notifyListeners();
  }

  // Natural Language Assistant Flow
  Future<void> submitAssistantPrompt(String prompt) async {
    _isLoading = true;
    notifyListeners();

    try {
      final action = await _assistantService.processPrompt(
        prompt: prompt,
        userTimezone: _profile?.timezone ?? 'UTC',
        previewOnly: true,
      );

      _assistantHistory.add(action);

      if (action.intent == 'query_summary') _selectedNavigationIndex = 4;
    } catch (e) {
      _errorMessage = 'Assistant error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> executeAssistantAction(AssistantAction action) async {
    final idx = _assistantHistory.indexWhere((a) => a.id == action.id);
    try {
      await _assistantService.confirmAction(action);
      await loadAllData();
      if (idx != -1) {
        _assistantHistory[idx] = action.copyWith(
          isConfirmed: true,
          executionStatus: 'executed',
        );
      }
    } catch (e) {
      _errorMessage = 'Assistant action was not verified as saved: $e';
      if (idx != -1) {
        _assistantHistory[idx] = action.copyWith(executionStatus: 'failed');
      }
    }
    notifyListeners();
  }

  void cancelAssistantAction(AssistantAction action) {
    final idx = _assistantHistory.indexWhere((a) => a.id == action.id);
    if (idx == -1) return;
    _assistantHistory[idx] = action.copyWith(executionStatus: 'cancelled');
    notifyListeners();
  }

  // Reports
  PlanoReportData get currentReport {
    return ReportService.generateDeterministicReport(
      startDate: _reportDateRange.start,
      endDate: _reportDateRange.end,
      timezone: _profile?.timezone ?? 'UTC',
      activities: _activities,
      tasks: _tasks,
      habits: _habits,
      checkins: _checkins,
      learningSessions: _learningSessions,
      healthSummaries: _healthSummaries,
    );
  }
}
