import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:plano/main.dart';
import 'package:plano/models/activity_log.dart';
import 'package:plano/providers/app_provider.dart';
import 'package:plano/services/report_service.dart';
import 'package:plano/services/assistant_service.dart';

void main() {
  group('Plano App Smoke Tests', () {
    testWidgets('App launches and renders Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()..loadAllData()),
          ],
          child: const PlanoApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text("Today's Tasks"), findsOneWidget);
      expect(find.text('Time Logged'), findsOneWidget);
    });
  });

  group('Deterministic Analytics & Report Calculations', () {
    test('Calculates exact minute totals and category percentages', () {
      final now = DateTime(2026, 10, 30);
      final activities = [
        ActivityLog(
          id: '1',
          userId: 'u1',
          title: 'Deep Work Session',
          category: 'work',
          date: now,
          durationMinutes: 90,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        ),
        ActivityLog(
          id: '2',
          userId: 'u1',
          title: 'Networking Lab',
          category: 'learning',
          date: now,
          durationMinutes: 45,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        ),
        ActivityLog(
          id: '3',
          userId: 'u1',
          title: 'Cardio run',
          category: 'workout',
          date: now,
          durationMinutes: 45,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final report = ReportService.generateDeterministicReport(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        timezone: 'UTC',
        activities: activities,
        tasks: [],
        habits: [],
        checkins: [],
        learningSessions: [],
        healthSummaries: [],
      );

      // Total = 90 + 45 + 45 = 180 mins
      expect(report.totalLoggedMinutes, 180);

      // Work = 90 / 180 = 50.0%
      final workCat = report.categoryBreakdown.firstWhere((c) => c.category == 'work');
      expect(workCat.totalMinutes, 90);
      expect(workCat.percentage, 50.0);

      // Learning = 45 / 180 = 25.0%
      final learnCat = report.categoryBreakdown.firstWhere((c) => c.category == 'learning');
      expect(learnCat.totalMinutes, 45);
      expect(learnCat.percentage, 25.0);
    });

    test('CSV export generates valid formatted CSV with headers', () {
      final now = DateTime(2026, 10, 30);
      final activities = [
        ActivityLog(
          id: 'act-test-1',
          userId: 'u1',
          title: 'Test Task',
          category: 'work',
          date: now,
          durationMinutes: 60,
          timezone: 'UTC',
          tags: ['test', 'plano'],
          notes: 'Test note',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final csv = ReportService.exportActivitiesToCsv(activities);
      expect(csv.contains('Date,Title,Category,Duration (Minutes)'), isTrue);
      expect(csv.contains('act-test-1'), isTrue);
      expect(csv.contains('Test Task'), isTrue);
      expect(csv.contains('60'), isTrue);
      expect(csv.contains('test;plano'), isTrue);
    });
  });

  group('Natural-Language Assistant Intent Parser Tests', () {
    final assistant = AssistantService();

    test('Parses study session into typed activity log intent', () async {
      final action = await assistant.processPrompt(
        prompt: 'Studied OSPF for 45 minutes',
        userTimezone: 'UTC',
      );

      expect(action.intent, 'log_activity');
      expect(action.parameters['duration_minutes'], 45);
      expect(action.parameters['category'], 'learning');
      expect(action.requiresConfirmation, isFalse);
    });

    test('Parses task creation into typed task intent', () async {
      final action = await assistant.processPrompt(
        prompt: 'Create a task to finish the project documentation tomorrow',
        userTimezone: 'UTC',
      );

      expect(action.intent, 'create_task');
      expect(action.parameters['title'], contains('finish the project documentation'));
      expect(action.parameters['due_date'], isNotNull);
    });

    test('Ambiguous activity duration prompts for concise clarification', () async {
      final action = await assistant.processPrompt(
        prompt: 'Worked on coding',
        userTimezone: 'UTC',
      );

      expect(action.intent, 'clarify_question');
      expect(action.clarificationQuestion, contains('minutes or hours'));
    });
  });
}
