import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/activity_log.dart';
import '../models/habit.dart';
import '../models/learning_session.dart';
import '../models/health_record.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _uuid = const Uuid();
  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  // Local fallback state for development/testing without real Supabase backend
  final List<Project> _localProjects = [];
  final List<PlanoTask> _localTasks = [];
  final List<ActivityLog> _localActivityLogs = [];
  final List<Habit> _localHabits = [];
  final List<HabitCheckin> _localCheckins = [];
  final List<LearningSession> _localLearningSessions = [];
  final List<HealthSummary> _localHealthSummaries = [];
  IntegrationConnection? _localIntegration;
  Profile? _localProfile;

  Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    if (supabaseUrl != null &&
        supabaseAnonKey != null &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('your-project-ref')) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        _isConfigured = true;
        debugPrint('Supabase initialized successfully');
      } catch (e) {
        debugPrint('Supabase initialization error: $e');
        _isConfigured = false;
        _seedLocalData();
      }
    } else {
      _isConfigured = false;
      _seedLocalData();
    }
  }

  void _seedLocalData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const userId = 'local-user-001';

    _localProfile = Profile(
      id: userId,
      fullName: 'Yashasvi (Plano Lead)',
      timezone: 'Asia/Kolkata',
      themeMode: 'system',
      createdAt: now.subtract(const Duration(days: 30)),
    );

    // Seed Projects
    final p1 = Project(
      id: 'proj-1',
      userId: userId,
      name: 'Plano Core App',
      description: 'End-to-end productivity & activity hub build',
      status: 'active',
      category: 'work',
      targetDate: today.add(const Duration(days: 14)),
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
    );
    final p2 = Project(
      id: 'proj-2',
      userId: userId,
      name: 'Networking Mastery',
      description: 'CCNA & BGP/OSPF Routing Architecture',
      status: 'active',
      category: 'learning',
      targetDate: today.add(const Duration(days: 45)),
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now,
    );
    _localProjects.addAll([p1, p2]);

    // Seed Tasks
    _localTasks.addAll([
      PlanoTask(
        id: 'task-1',
        userId: userId,
        projectId: p1.id,
        title: 'Complete Health Connect Method Channel',
        description: 'Verify steps and exercise session aggregation contracts',
        status: 'completed',
        priority: 'high',
        dueDate: today,
        category: 'work',
        estimatedMinutes: 60,
        actualMinutes: 45,
        completedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      PlanoTask(
        id: 'task-2',
        userId: userId,
        projectId: p1.id,
        title: 'Finish project documentation and schema tests',
        description: 'Ensure deterministic queries and RLS isolation tests pass',
        status: 'todo',
        priority: 'high',
        dueDate: today.add(const Duration(days: 1)),
        category: 'work',
        estimatedMinutes: 90,
        createdAt: now,
        updatedAt: now,
      ),
      PlanoTask(
        id: 'task-3',
        userId: userId,
        projectId: p2.id,
        title: 'Review OSPF Areas and LSA Types',
        description: 'Read RFC 2328 sections 3 and 4',
        status: 'todo',
        priority: 'medium',
        dueDate: today,
        category: 'learning',
        estimatedMinutes: 45,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    // Seed Activity Logs
    _localActivityLogs.addAll([
      ActivityLog(
        id: 'act-1',
        userId: userId,
        projectId: p2.id,
        title: 'Studied OSPF for 45 minutes',
        category: 'learning',
        tags: ['networking', 'ospf', 'ccna'],
        date: today,
        durationMinutes: 45,
        timezone: 'Asia/Kolkata',
        notes: 'Covered DR/BDR election and LSA type 1-5 transitions',
        source: 'manual',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now,
      ),
      ActivityLog(
        id: 'act-2',
        userId: userId,
        projectId: p1.id,
        title: 'Plano architecture & RLS security design',
        category: 'work',
        tags: ['supabase', 'rls', 'flutter'],
        date: today,
        durationMinutes: 90,
        timezone: 'Asia/Kolkata',
        notes: 'Drafted strict tenant isolation policies and Edge Function boundary',
        source: 'manual',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now,
      ),
      ActivityLog(
        id: 'act-3',
        userId: userId,
        title: 'Evening brisk walk & workout',
        category: 'workout',
        tags: ['health', 'cardio'],
        date: today.subtract(const Duration(days: 1)),
        durationMinutes: 35,
        timezone: 'Asia/Kolkata',
        notes: 'Imported sync check',
        source: 'health_connect',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
    ]);

    // Seed Habits & Checkins
    final h1 = Habit(
      id: 'habit-1',
      userId: userId,
      name: 'Daily Deep Work Session (90 min)',
      description: 'Uninterrupted technical focus before noon',
      frequencyTargetDaysPerWeek: 6,
      targetSchedule: 'weekdays',
      category: 'routine',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
    );
    final h2 = Habit(
      id: 'habit-2',
      userId: userId,
      name: 'Physical Activity / 8k Steps',
      description: 'Daily cardio and step consistency',
      frequencyTargetDaysPerWeek: 7,
      targetSchedule: 'daily',
      category: 'health',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
    );
    _localHabits.addAll([h1, h2]);

    _localCheckins.addAll([
      HabitCheckin(
        id: 'chk-1',
        habitId: h1.id,
        userId: userId,
        checkinDate: today,
        createdAt: now,
      ),
      HabitCheckin(
        id: 'chk-2',
        habitId: h1.id,
        userId: userId,
        checkinDate: today.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      HabitCheckin(
        id: 'chk-3',
        habitId: h2.id,
        userId: userId,
        checkinDate: today.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Seed Learning
    _localLearningSessions.add(
      LearningSession(
        id: 'learn-1',
        userId: userId,
        projectId: p2.id,
        topic: 'OSPF Link-State Advertisements',
        resources: 'Routing TCP/IP Volume 1, Chapter 8',
        durationMinutes: 45,
        sessionDate: today,
        notes: 'Configured point-to-point and broadcast network types',
        goal: 'Pass certification routing lab',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Seed Health Summary
    _localHealthSummaries.addAll([
      HealthSummary(
        id: 'hlth-1',
        userId: userId,
        date: today.subtract(const Duration(days: 1)),
        stepCount: 8420,
        workoutCount: 1,
        workoutDurationMinutes: 35,
        source: 'Health Connect',
        lastSyncedAt: now.subtract(const Duration(hours: 12)),
      ),
      HealthSummary(
        id: 'hlth-2',
        userId: userId,
        date: today,
        stepCount: 4210,
        workoutCount: 0,
        workoutDurationMinutes: 0,
        source: 'Health Connect',
        lastSyncedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ]);

    _localIntegration = IntegrationConnection(
      id: 'int-1',
      userId: userId,
      provider: 'health_connect',
      isConnected: true,
      permissionsGranted: ['READ_STEPS', 'READ_EXERCISE'],
      lastSyncAt: now.subtract(const Duration(minutes: 30)),
      updatedAt: now,
    );
  }

  // Auth
  String get currentUserId => _isConfigured && Supabase.instance.client.auth.currentUser != null
      ? Supabase.instance.client.auth.currentUser!.id
      : 'local-user-001';

  User? get currentUser => _isConfigured ? Supabase.instance.client.auth.currentUser : null;

  Future<void> signIn(String email, String password) async {
    if (_isConfigured) {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    if (_isConfigured) {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    }
  }

  Future<void> signOut() async {
    if (_isConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  // Profile
  Future<Profile> getProfile() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      return Profile.fromJson(res);
    }
    return _localProfile!;
  }

  Future<void> updateProfile(Profile profile) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('profiles').upsert(profile.toJson());
    } else {
      _localProfile = profile;
    }
  }

  // Projects
  Future<List<Project>> getProjects() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) => Project.fromJson(e)).toList();
    }
    return List.unmodifiable(_localProjects);
  }

  Future<Project> createProject(Project project) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('projects')
          .insert(project.toJson())
          .select()
          .single();
      return Project.fromJson(res);
    }
    _localProjects.insert(0, project);
    return project;
  }

  Future<void> updateProject(Project project) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id);
    } else {
      final idx = _localProjects.indexWhere((p) => p.id == project.id);
      if (idx != -1) _localProjects[idx] = project;
    }
  }

  Future<void> deleteProject(String id) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('projects').delete().eq('id', id);
    } else {
      _localProjects.removeWhere((p) => p.id == id);
      _localTasks.removeWhere((t) => t.projectId == id);
    }
  }

  // Tasks
  Future<List<PlanoTask>> getTasks() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) => PlanoTask.fromJson(e)).toList();
    }
    return List.unmodifiable(_localTasks);
  }

  Future<PlanoTask> createTask(PlanoTask task) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('tasks')
          .insert(task.toJson())
          .select()
          .single();
      return PlanoTask.fromJson(res);
    }
    _localTasks.insert(0, task);
    return task;
  }

  Future<void> updateTask(PlanoTask task) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('tasks').update(task.toJson()).eq('id', task.id);
    } else {
      final idx = _localTasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) _localTasks[idx] = task;
    }
  }

  Future<void> deleteTask(String id) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('tasks').delete().eq('id', id);
    } else {
      _localTasks.removeWhere((t) => t.id == id);
    }
  }

  // Activity Logs
  Future<List<ActivityLog>> getActivityLogs() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('activity_logs')
          .select()
          .order('date', ascending: false);
      return (res as List).map((e) => ActivityLog.fromJson(e)).toList();
    }
    return List.unmodifiable(_localActivityLogs);
  }

  Future<ActivityLog> createActivityLog(ActivityLog log) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('activity_logs')
          .insert(log.toJson())
          .select()
          .single();
      return ActivityLog.fromJson(res);
    }
    _localActivityLogs.insert(0, log);
    return log;
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client
          .from('activity_logs')
          .update(log.toJson())
          .eq('id', log.id);
    } else {
      final idx = _localActivityLogs.indexWhere((a) => a.id == log.id);
      if (idx != -1) _localActivityLogs[idx] = log;
    }
  }

  Future<void> deleteActivityLog(String id) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('activity_logs').delete().eq('id', id);
    } else {
      _localActivityLogs.removeWhere((a) => a.id == id);
    }
  }

  // Habits & Checkins
  Future<List<Habit>> getHabits() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('habits')
          .select()
          .order('created_at', ascending: true);
      return (res as List).map((e) => Habit.fromJson(e)).toList();
    }
    return List.unmodifiable(_localHabits);
  }

  Future<Habit> createHabit(Habit habit) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('habits')
          .insert(habit.toJson())
          .select()
          .single();
      return Habit.fromJson(res);
    }
    _localHabits.add(habit);
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('habits').update(habit.toJson()).eq('id', habit.id);
    } else {
      final idx = _localHabits.indexWhere((h) => h.id == habit.id);
      if (idx != -1) _localHabits[idx] = habit;
    }
  }

  Future<void> deleteHabit(String id) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('habits').delete().eq('id', id);
    } else {
      _localHabits.removeWhere((h) => h.id == id);
      _localCheckins.removeWhere((c) => c.habitId == id);
    }
  }

  Future<List<HabitCheckin>> getCheckins() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client.from('habit_checkins').select();
      return (res as List).map((e) => HabitCheckin.fromJson(e)).toList();
    }
    return List.unmodifiable(_localCheckins);
  }

  Future<void> toggleHabitCheckin(String habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    if (_isConfigured && currentUser != null) {
      final existing = await Supabase.instance.client
          .from('habit_checkins')
          .select()
          .eq('habit_id', habitId)
          .eq('checkin_date', dateStr);
      if ((existing as List).isNotEmpty) {
        await Supabase.instance.client
            .from('habit_checkins')
            .delete()
            .eq('habit_id', habitId)
            .eq('checkin_date', dateStr);
      } else {
        await Supabase.instance.client.from('habit_checkins').insert({
          'id': _uuid.v4(),
          'habit_id': habitId,
          'user_id': currentUser!.id,
          'checkin_date': dateStr,
        });
      }
    } else {
      final idx = _localCheckins.indexWhere((c) =>
          c.habitId == habitId &&
          c.checkinDate.toIso8601String().split('T').first == dateStr);
      if (idx != -1) {
        _localCheckins.removeAt(idx);
      } else {
        _localCheckins.add(HabitCheckin(
          id: _uuid.v4(),
          habitId: habitId,
          userId: currentUserId,
          checkinDate: date,
          createdAt: DateTime.now(),
        ));
      }
    }
  }

  // Learning
  Future<List<LearningSession>> getLearningSessions() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('learning_sessions')
          .select()
          .order('session_date', ascending: false);
      return (res as List).map((e) => LearningSession.fromJson(e)).toList();
    }
    return List.unmodifiable(_localLearningSessions);
  }

  Future<LearningSession> createLearningSession(LearningSession session) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('learning_sessions')
          .insert(session.toJson())
          .select()
          .single();
      return LearningSession.fromJson(res);
    }
    _localLearningSessions.insert(0, session);
    return session;
  }

  Future<void> updateLearningSession(LearningSession session) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client
          .from('learning_sessions')
          .update(session.toJson())
          .eq('id', session.id);
    } else {
      final idx = _localLearningSessions.indexWhere((l) => l.id == session.id);
      if (idx != -1) _localLearningSessions[idx] = session;
    }
  }

  Future<void> deleteLearningSession(String id) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('learning_sessions').delete().eq('id', id);
    } else {
      _localLearningSessions.removeWhere((l) => l.id == id);
    }
  }

  // Health
  Future<List<HealthSummary>> getHealthSummaries() async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('health_summaries')
          .select()
          .order('date', ascending: false);
      return (res as List).map((e) => HealthSummary.fromJson(e)).toList();
    }
    return List.unmodifiable(_localHealthSummaries);
  }

  Future<void> upsertHealthSummary(HealthSummary summary) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client.from('health_summaries').upsert(summary.toJson());
    } else {
      final dateStr = summary.date.toIso8601String().split('T').first;
      final idx = _localHealthSummaries.indexWhere(
          (h) => h.date.toIso8601String().split('T').first == dateStr);
      if (idx != -1) {
        _localHealthSummaries[idx] = summary;
      } else {
        _localHealthSummaries.insert(0, summary);
      }
    }
  }

  Future<void> deleteHealthData() async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client
          .from('health_summaries')
          .delete()
          .eq('user_id', currentUser!.id);
    } else {
      _localHealthSummaries.clear();
    }
  }

  Future<IntegrationConnection?> getIntegrationConnection(String provider) async {
    if (_isConfigured && currentUser != null) {
      final res = await Supabase.instance.client
          .from('integration_connections')
          .select()
          .eq('provider', provider)
          .maybeSingle();
      if (res != null) return IntegrationConnection.fromJson(res);
      return null;
    }
    return _localIntegration;
  }

  Future<void> updateIntegrationConnection(IntegrationConnection conn) async {
    if (_isConfigured && currentUser != null) {
      await Supabase.instance.client
          .from('integration_connections')
          .upsert(conn.toJson());
    } else {
      _localIntegration = conn;
    }
  }
}
