import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/activity_log.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/learning_session.dart';
import '../models/health_record.dart';

class CategorySummary {
  final String category;
  final int totalMinutes;
  final double percentage;

  CategorySummary({
    required this.category,
    required this.totalMinutes,
    required this.percentage,
  });
}

class PlanoReportData {
  final DateTime startDate;
  final DateTime endDate;
  final String timezone;
  final DateTime generatedAt;

  final int totalLoggedMinutes;
  final List<CategorySummary> categoryBreakdown;

  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final double taskCompletionRate;

  final int totalExpectedHabitDays;
  final int totalActualHabitCheckins;
  final double habitConsistencyRate;

  final int totalLearningMinutes;
  final List<String> learningTopics;

  final int totalSteps;
  final int totalHealthWorkoutMinutes;
  final bool hasHealthData;

  PlanoReportData({
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.generatedAt,
    required this.totalLoggedMinutes,
    required this.categoryBreakdown,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.taskCompletionRate,
    required this.totalExpectedHabitDays,
    required this.totalActualHabitCheckins,
    required this.habitConsistencyRate,
    required this.totalLearningMinutes,
    required this.learningTopics,
    required this.totalSteps,
    required this.totalHealthWorkoutMinutes,
    required this.hasHealthData,
  });
}

class ReportService {
  static PlanoReportData generateDeterministicReport({
    required DateTime startDate,
    required DateTime endDate,
    required String timezone,
    required List<ActivityLog> activities,
    required List<PlanoTask> tasks,
    required List<Habit> habits,
    required List<HabitCheckin> checkins,
    required List<LearningSession> learningSessions,
    required List<HealthSummary> healthSummaries,
    String? categoryFilter,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // 1. Filter activities in date range
    final inRangeActivities = activities.where((a) {
      final inDate = !a.date.isBefore(start) && !a.date.isAfter(end);
      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
        return inDate && a.category.toLowerCase() == categoryFilter.toLowerCase();
      }
      return inDate;
    }).toList();

    int totalMinutes = 0;
    final Map<String, int> catMinutes = {};

    for (final act in inRangeActivities) {
      totalMinutes += act.durationMinutes;
      catMinutes[act.category] = (catMinutes[act.category] ?? 0) + act.durationMinutes;
    }

    final List<CategorySummary> breakdown = [];
    catMinutes.forEach((cat, mins) {
      final pct = totalMinutes > 0 ? (mins / totalMinutes) * 100.0 : 0.0;
      breakdown.add(CategorySummary(category: cat, totalMinutes: mins, percentage: pct));
    });
    breakdown.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    // 2. Filter tasks
    final inRangeTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return !t.dueDate!.isBefore(start) && !t.dueDate!.isAfter(end);
    }).toList();

    final completedTasks = inRangeTasks.where((t) => t.isCompleted).length;
    final overdueTasks = inRangeTasks.where((t) => t.isOverdue).length;
    final taskRate = inRangeTasks.isNotEmpty ? (completedTasks / inRangeTasks.length) * 100.0 : 0.0;

    // 3. Habit consistency in range
    final rangeDays = end.difference(start).inDays + 1;
    int expectedHabits = 0;
    for (final h in habits.where((h) => !h.isArchived)) {
      final daysPerWeek = h.frequencyTargetDaysPerWeek;
      final expected = ((rangeDays / 7.0) * daysPerWeek).round();
      expectedHabits += expected > 0 ? expected : 1;
    }

    final inRangeCheckins = checkins.where((c) {
      return !c.checkinDate.isBefore(start) && !c.checkinDate.isAfter(end);
    }).length;

    final habitRate = expectedHabits > 0
        ? ((inRangeCheckins / expectedHabits) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // 4. Learning
    final inRangeLearning = learningSessions.where((l) {
      return !l.sessionDate.isBefore(start) && !l.sessionDate.isAfter(end);
    }).toList();

    int learningMins = 0;
    final Set<String> topics = {};
    for (final l in inRangeLearning) {
      learningMins += l.durationMinutes;
      topics.add(l.topic);
    }

    // 5. Health
    final inRangeHealth = healthSummaries.where((h) {
      return !h.date.isBefore(start) && !h.date.isAfter(end);
    }).toList();

    int steps = 0;
    int workoutMins = 0;
    for (final h in inRangeHealth) {
      steps += h.stepCount;
      workoutMins += h.workoutDurationMinutes;
    }

    return PlanoReportData(
      startDate: start,
      endDate: end,
      timezone: timezone,
      generatedAt: DateTime.now(),
      totalLoggedMinutes: totalMinutes,
      categoryBreakdown: breakdown,
      totalTasks: inRangeTasks.length,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
      taskCompletionRate: taskRate,
      totalExpectedHabitDays: expectedHabits,
      totalActualHabitCheckins: inRangeCheckins,
      habitConsistencyRate: habitRate,
      totalLearningMinutes: learningMins,
      learningTopics: topics.toList(),
      totalSteps: steps,
      totalHealthWorkoutMinutes: workoutMins,
      hasHealthData: inRangeHealth.isNotEmpty,
    );
  }

  static String exportActivitiesToCsv(List<ActivityLog> activities) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final rows = <List<dynamic>>[];

    // CSV Headers
    rows.add([
      'ID',
      'Date',
      'Title',
      'Category',
      'Duration (Minutes)',
      'Duration (Hours)',
      'Timezone',
      'Source',
      'Tags',
      'Notes',
    ]);

    for (final a in activities) {
      rows.add([
        a.id,
        dateFormat.format(a.date),
        a.title,
        a.category,
        a.durationMinutes,
        (a.durationMinutes / 60.0).toStringAsFixed(2),
        a.timezone,
        a.source,
        a.tags.join(';'),
        a.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String exportReportSummaryToCsv(PlanoReportData report) {
    final df = DateFormat('yyyy-MM-dd');
    final rows = <List<dynamic>>[];

    rows.add(['PLANO DETERMINISTIC ANALYTICS REPORT']);
    rows.add(['Generated At', report.generatedAt.toIso8601String()]);
    rows.add(['Timezone', report.timezone]);
    rows.add(['Date Range', '${df.format(report.startDate)} to ${df.format(report.endDate)}']);
    rows.add([]);

    rows.add(['METRIC', 'VALUE']);
    rows.add(['Total Time Logged (Minutes)', report.totalLoggedMinutes]);
    rows.add(['Total Time Logged (Hours)', (report.totalLoggedMinutes / 60.0).toStringAsFixed(1)]);
    rows.add(['Total Tasks Scheduled', report.totalTasks]);
    rows.add(['Completed Tasks', report.completedTasks]);
    rows.add(['Overdue Tasks', report.overdueTasks]);
    rows.add(['Task Completion Rate (%)', report.taskCompletionRate.toStringAsFixed(1)]);
    rows.add(['Expected Habit Days', report.totalExpectedHabitDays]);
    rows.add(['Actual Habit Check-ins', report.totalActualHabitCheckins]);
    rows.add(['Habit Consistency Rate (%)', report.habitConsistencyRate.toStringAsFixed(1)]);
    rows.add(['Learning Time (Minutes)', report.totalLearningMinutes]);
    rows.add(['Learning Topics Count', report.learningTopics.length]);
    rows.add(['Health Steps Total', report.hasHealthData ? report.totalSteps : 'Unavailable']);
    rows.add(['Health Workout Minutes', report.hasHealthData ? report.totalHealthWorkoutMinutes : 'Unavailable']);
    rows.add([]);

    rows.add(['CATEGORY BREAKDOWN']);
    rows.add(['Category', 'Minutes', 'Hours', 'Percentage (%)']);
    for (final c in report.categoryBreakdown) {
      rows.add([
        c.category,
        c.totalMinutes,
        (c.totalMinutes / 60.0).toStringAsFixed(1),
        c.percentage.toStringAsFixed(1),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
