import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assistant_action.dart';
import 'supabase_service.dart';

class AssistantService {
  final _uuid = const Uuid();

  Future<AssistantAction> processPrompt({
    required String prompt,
    required String userTimezone,
    bool previewOnly = true,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'clarify_question',
        clarificationQuestion: 'Please enter a request or activity.',
        summary: 'Empty request provided.',
        timestamp: DateTime.now(),
      );
    }

    final supabase = SupabaseService();
    if (supabase.isConfigured) {
      if (supabase.currentUser == null) throw StateError('Sign in before using the assistant.');
      final idempotencyKey = _uuid.v4();
      final result = await Supabase.instance.client.functions.invoke(
        'assistant_action',
        body: {
          'prompt': cleanPrompt,
          'timezone': userTimezone,
          'idempotencyKey': idempotencyKey,
          'previewOnly': previewOnly,
        },
      );
      if (result.data is! Map) throw const FormatException('Assistant returned an invalid response.');
      return AssistantAction.fromJson(
        Map<String, dynamic>.from(result.data as Map)
          ..putIfAbsent('user_prompt', () => cleanPrompt),
      );
    }

    // Local parser is retained for unit tests and offline previews only.
    return _parsePromptLocally(cleanPrompt, userTimezone);
  }

  Future<void> confirmAction(AssistantAction action) async {
    final supabase = SupabaseService();
    if (!supabase.isConfigured || supabase.currentUser == null) {
      throw StateError('Sign in to Plano before confirming an assistant action.');
    }
    final result = await Supabase.instance.client.functions.invoke(
      'assistant_action',
      body: {
        'confirmedAction': {
          'id': action.id,
          'intent': action.intent,
          'parameters': action.parameters,
        },
      },
    );
    final data = result.data;
    if (data is! Map || data['status'] != 'success' || data['verified'] != true) {
      throw const FormatException('The assistant action was not verified as saved.');
    }
  }

  AssistantAction _parsePromptLocally(String prompt, String timezone) {
    final lower = prompt.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Task creation
    if (lower.startsWith('create a task') ||
        lower.startsWith('create task') ||
        lower.startsWith('add a task') ||
        lower.startsWith('add task') ||
        lower.startsWith('todo:') ||
        lower.contains('task to ')) {
      String title = prompt
          .replaceFirst(RegExp(r'^(create a task to|create a task|create task to|create task|add a task to|add a task|add task to|add task|todo:)', caseSensitive: false), '')
          .trim();

      DateTime? dueDate;
      if (lower.contains('tomorrow')) {
        dueDate = today.add(const Duration(days: 1));
        title = title.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim();
      } else if (lower.contains('today')) {
        dueDate = today;
        title = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim();
      } else if (lower.contains('next week')) {
        dueDate = today.add(const Duration(days: 7));
        title = title.replaceAll(RegExp(r'\bnext week\b', caseSensitive: false), '').trim();
      }

      String priority = 'medium';
      if (lower.contains('urgent') || lower.contains('high priority') || lower.contains('asap')) {
        priority = 'high';
        title = title.replaceAll(RegExp(r'\b(urgent|high priority|asap)\b', caseSensitive: false), '').trim();
      }

      if (title.isEmpty) {
        return AssistantAction(
          id: _uuid.v4(),
          userPrompt: prompt,
          intent: 'clarify_question',
          clarificationQuestion: 'What is the title or objective for this task?',
          summary: 'Missing task title.',
          timestamp: now,
        );
      }

      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'create_task',
        parameters: {
          'title': title,
          'priority': priority,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'category': 'work',
        },
        requiresConfirmation: true,
        summary: 'Create task "$title"${dueDate != null ? " due ${dueDate.toIso8601String().split('T').first}" : ""}',
        timestamp: now,
      );
    }

    // 2. Activity logging (e.g. "Studied OSPF for 45 minutes", "Ran for 30 mins")
    final durationMatch = RegExp(r'(\d+)\s*(minutes|minute|mins|min|hours|hour|hrs|hr)', caseSensitive: false).firstMatch(lower);

    if (durationMatch != null || lower.startsWith('studied') || lower.startsWith('worked on') || lower.startsWith('logged') || lower.startsWith('spent')) {
      int durationMinutes = 0;
      if (durationMatch != null) {
        final amount = int.tryParse(durationMatch.group(1) ?? '0') ?? 0;
        final unit = durationMatch.group(2)?.toLowerCase() ?? 'min';
        if (unit.startsWith('h')) {
          durationMinutes = amount * 60;
        } else {
          durationMinutes = amount;
        }
      } else {
        return AssistantAction(
          id: _uuid.v4(),
          userPrompt: prompt,
          intent: 'clarify_question',
          clarificationQuestion: 'How many minutes or hours did this activity take?',
          summary: 'Ambiguous duration in activity log.',
          timestamp: now,
        );
      }

      String category = 'work';
      if (lower.contains('stud') || lower.contains('learn') || lower.contains('read')) {
        category = 'learning';
      } else if (lower.contains('run') || lower.contains('workout') || lower.contains('gym') || lower.contains('walk')) {
        category = 'workout';
      } else if (lower.contains('habit')) {
        category = 'habit';
      } else if (lower.contains('errand') || lower.contains('admin')) {
        category = 'admin';
      }

      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'log_activity',
        parameters: {
          'title': prompt,
          'category': category,
          'duration_minutes': durationMinutes,
          'date': today.toIso8601String().split('T').first,
          'timezone': timezone,
        },
        requiresConfirmation: true,
        summary: 'Log $durationMinutes min $category activity: "$prompt"',
        timestamp: now,
      );
    }

    // 3. Queries and summaries
    if (lower.contains('show overdue') || lower.contains('overdue tasks')) {
      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'query_summary',
        parameters: {'filter': 'overdue_tasks'},
        summary: 'Filter and display all overdue tasks.',
        timestamp: now,
      );
    }

    if (lower.contains('summarize') || lower.contains('report') || lower.contains('compare')) {
      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'query_summary',
        parameters: {
          'scope': lower.contains('month') ? 'month' : 'week',
          'category': lower.contains('learning') ? 'learning' : 'all',
        },
        summary: 'Generate deterministic productivity and time summary.',
        timestamp: now,
      );
    }

    // 4. Habit check-in
    if (lower.contains('check in') || lower.contains('checked in') || lower.contains('habit')) {
      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'checkin_habit',
        parameters: {
          'target': prompt,
          'date': today.toIso8601String().split('T').first,
        },
        summary: 'Check in habit for today.',
        timestamp: now,
      );
    }

    // 5. Destructive preview check (e.g. delete, clear)
    if (lower.contains('delete') || lower.contains('remove') || lower.contains('clear all')) {
      return AssistantAction(
        id: _uuid.v4(),
        userPrompt: prompt,
        intent: 'delete_confirmation_required',
        isDestructive: true,
        requiresConfirmation: true,
        parameters: {'target': prompt},
        summary: 'Confirm deletion: this action is permanent and cannot be undone.',
        timestamp: now,
      );
    }

    // Default clarification
    return AssistantAction(
      id: _uuid.v4(),
      userPrompt: prompt,
      intent: 'clarify_question',
      clarificationQuestion: 'Would you like to log an activity, create a task, check in a habit, or view a summary report?',
      summary: 'Ambiguous request intent.',
      timestamp: now,
    );
  }
}
