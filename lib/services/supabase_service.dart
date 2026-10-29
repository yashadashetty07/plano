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

  // Empty local collections are retained for model/unit-test compatibility.
  final List<Project> _localProjects = [];
  final List<PlanoTask> _localTasks = [];
  final List<ActivityLog> _localActivityLogs = [];
  final List<Habit> _localHabits = [];
  final List<HabitCheckin> _localCheckins = [];
  final List<LearningSession> _localLearningSessions = [];
  final List<HealthSummary> _localHealthSummaries = [];
  IntegrationConnection? _localIntegration;
  Profile? _localProfile;

  Future<void> initialize({String? supabaseUrl, String? supabasePublishableKey}) async {
    if (supabaseUrl != null &&
        supabasePublishableKey != null &&
        supabaseUrl.isNotEmpty &&
        supabasePublishableKey.isNotEmpty &&
        !supabaseUrl.contains('your-project-ref') &&
        !supabasePublishableKey.contains('your-supabase-publishable-key')) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
      _isConfigured = true;
      return;
    }
    _isConfigured = false;
  }

  Stream<AuthState> get authStateChanges => _isConfigured
      ? Supabase.instance.client.auth.onAuthStateChange
      : const Stream<AuthState>.empty();

  // Auth
  String get currentUserId {
    final user = currentUser;
    if (user == null) throw StateError('A signed-in Supabase user is required.');
    return user.id;
  }

  User? get currentUser => _isConfigured ? Supabase.instance.client.auth.currentUser : null;

  User? get _configuredUser {
    _requireConfigured();
    final user = currentUser;
    if (user == null) throw StateError('Sign in to Plano before accessing data.');
    return user;
  }

  Future<void> signIn(String email, String password) async {
    _requireConfigured();
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    _requireConfigured();
    await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
  }

  Future<void> signOut() async {
    _requireConfigured();
    await Supabase.instance.client.auth.signOut();
  }

  void _requireConfigured() {
    if (!_isConfigured) throw StateError('Supabase is not configured.');
  }

  // Profile
  Future<Profile> getProfile() async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('profiles').upsert(profile.toJson());
    } else {
      _localProfile = profile;
    }
  }

  // Projects
  Future<List<Project>> getProjects() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) => Project.fromJson(e)).toList();
    }
    return List.unmodifiable(_localProjects);
  }

  Future<Project> createProject(Project project) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('projects').delete().eq('id', id);
    } else {
      _localProjects.removeWhere((p) => p.id == id);
      _localTasks.removeWhere((t) => t.projectId == id);
    }
  }

  // Tasks
  Future<List<PlanoTask>> getTasks() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) => PlanoTask.fromJson(e)).toList();
    }
    return List.unmodifiable(_localTasks);
  }

  Future<PlanoTask> createTask(PlanoTask task) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('tasks').update(task.toJson()).eq('id', task.id);
    } else {
      final idx = _localTasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) _localTasks[idx] = task;
    }
  }

  Future<void> deleteTask(String id) async {
    if (_configuredUser != null) {
      await Supabase.instance.client.from('tasks').delete().eq('id', id);
    } else {
      _localTasks.removeWhere((t) => t.id == id);
    }
  }

  // Activity Logs
  Future<List<ActivityLog>> getActivityLogs() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('activity_logs')
          .select()
          .order('date', ascending: false);
      return (res as List).map((e) => ActivityLog.fromJson(e)).toList();
    }
    return List.unmodifiable(_localActivityLogs);
  }

  Future<ActivityLog> createActivityLog(ActivityLog log) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('activity_logs').delete().eq('id', id);
    } else {
      _localActivityLogs.removeWhere((a) => a.id == id);
    }
  }

  // Habits & Checkins
  Future<List<Habit>> getHabits() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('habits')
          .select()
          .order('created_at', ascending: true);
      return (res as List).map((e) => Habit.fromJson(e)).toList();
    }
    return List.unmodifiable(_localHabits);
  }

  Future<Habit> createHabit(Habit habit) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('habits').update(habit.toJson()).eq('id', habit.id);
    } else {
      final idx = _localHabits.indexWhere((h) => h.id == habit.id);
      if (idx != -1) _localHabits[idx] = habit;
    }
  }

  Future<void> deleteHabit(String id) async {
    if (_configuredUser != null) {
      await Supabase.instance.client.from('habits').delete().eq('id', id);
    } else {
      _localHabits.removeWhere((h) => h.id == id);
      _localCheckins.removeWhere((c) => c.habitId == id);
    }
  }

  Future<List<HabitCheckin>> getCheckins() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client.from('habit_checkins').select();
      return (res as List).map((e) => HabitCheckin.fromJson(e)).toList();
    }
    return List.unmodifiable(_localCheckins);
  }

  Future<void> toggleHabitCheckin(String habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('learning_sessions')
          .select()
          .order('session_date', ascending: false);
      return (res as List).map((e) => LearningSession.fromJson(e)).toList();
    }
    return List.unmodifiable(_localLearningSessions);
  }

  Future<LearningSession> createLearningSession(LearningSession session) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client.from('learning_sessions').delete().eq('id', id);
    } else {
      _localLearningSessions.removeWhere((l) => l.id == id);
    }
  }

  // Health
  Future<List<HealthSummary>> getHealthSummaries() async {
    if (_configuredUser != null) {
      final res = await Supabase.instance.client
          .from('health_summaries')
          .select()
          .order('date', ascending: false);
      return (res as List).map((e) => HealthSummary.fromJson(e)).toList();
    }
    return List.unmodifiable(_localHealthSummaries);
  }

  Future<void> upsertHealthSummary(HealthSummary summary) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client
          .from('health_summaries')
          .delete()
          .eq('user_id', currentUser!.id);
    } else {
      _localHealthSummaries.clear();
    }
  }

  Future<IntegrationConnection?> getIntegrationConnection(String provider) async {
    if (_configuredUser != null) {
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
    if (_configuredUser != null) {
      await Supabase.instance.client
          .from('integration_connections')
          .upsert(conn.toJson());
    } else {
      _localIntegration = conn;
    }
  }
}
