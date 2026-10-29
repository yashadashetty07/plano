import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/learning_session.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';

class HabitsLearningScreen extends StatefulWidget {
  const HabitsLearningScreen({super.key});

  @override
  State<HabitsLearningScreen> createState() => _HabitsLearningScreenState();
}

class _HabitsLearningScreenState extends State<HabitsLearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddHabitDialog() {
    final provider = context.read<AppProvider>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String schedule = 'daily';
    int freqDays = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Habit'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name *', hintText: 'e.g. Daily Deep Work'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', hintText: '90 minutes before noon'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: schedule,
                  decoration: const InputDecoration(labelText: 'Target Schedule'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily (7 days/week)')),
                    DropdownMenuItem(value: 'weekdays', child: Text('Weekdays (Mon - Fri)')),
                    DropdownMenuItem(value: 'weekends', child: Text('Weekends (Sat - Sun)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        schedule = val;
                        freqDays = val == 'daily' ? 7 : (val == 'weekdays' ? 5 : 2);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final habit = Habit(
                  id: _uuid.v4(),
                  userId: provider.profile!.id,
                  name: name,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  frequencyTargetDaysPerWeek: freqDays,
                  targetSchedule: schedule,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await provider.addHabit(habit);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Habit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLearningDialog() {
    final provider = context.read<AppProvider>();
    final topicController = TextEditingController();
    final resourcesController = TextEditingController();
    final durController = TextEditingController(text: '45');
    final notesController = TextEditingController();
    final goalController = TextEditingController();
    String? selectedProjectId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Learning Session'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(labelText: 'Topic *', hintText: 'e.g. OSPF Routing Protocol'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Duration (mins) *'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedProjectId,
                        decoration: const InputDecoration(labelText: 'Project'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                        ],
                        onChanged: (val) => selectedProjectId = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: resourcesController,
                  decoration: const InputDecoration(labelText: 'Resources / References', hintText: 'RFC 2328, Cisco Press Chapter 4'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Session Notes', hintText: 'Key concepts mastered, configurations tested'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: 'Learning Goal', hintText: 'Pass certification lab'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final topic = topicController.text.trim();
              if (topic.isEmpty) return;
              final dur = int.tryParse(durController.text.trim()) ?? 30;

              final session = LearningSession(
                id: _uuid.v4(),
                userId: provider.profile!.id,
                projectId: selectedProjectId,
                topic: topic,
                resources: resourcesController.text.trim().isEmpty ? null : resourcesController.text.trim(),
                durationMinutes: dur,
                sessionDate: DateTime.now(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                goal: goalController.text.trim().isEmpty ? null : goalController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await provider.addLearningSession(session);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits & Learning', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Habits & Streaks'),
            Tab(text: 'Learning & Study'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddHabitDialog();
          } else {
            _showAddLearningDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'New Habit' : 'Log Study Session'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Habits
          provider.habits.isEmpty
              ? const EmptyState(
                  icon: Icons.repeat,
                  title: 'No habits defined',
                  message: 'Track daily routines and keep steady streaks with timezone-aware logs.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: provider.habits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final h = provider.habits[index];
                    final streak = provider.getHabitStreak(h.id);

                    // 7-day visual check-in row
                    final last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (h.description != null) ...[
                                        const SizedBox(height: 2),
                                        Text(h.description!, style: theme.textTheme.bodySmall),
                                      ],
                                    ],
                                  ),
                                ),
                                if (streak > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_fire_department, size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$streak days',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Weekly check-in bubbles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: last7Days.map((date) {
                                final isToday = date.isAtSameMomentAs(today);
                                final checked = provider.isHabitChecked(h.id, date);
                                return InkWell(
                                  onTap: isToday ? () => provider.toggleHabitCheckin(h.id, today) : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('E').format(date).substring(0, 1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                          color: isToday ? theme.colorScheme.primary : theme.colorScheme.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: checked
                                              ? theme.colorScheme.primary
                                              : (isToday ? theme.colorScheme.surfaceVariant : Colors.transparent),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: checked ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: checked
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : (isToday
                                                  ? Text('•', style: TextStyle(color: theme.colorScheme.primary))
                                                  : null),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // TAB 2: Learning Sessions
          provider.learningSessions.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No study sessions logged',
                  message: 'Track technical topics, read documentation, and master new skills.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: provider.learningSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final l = provider.learningSessions[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    l.topic,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${l.durationMinutes} mins',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(l.sessionDate),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                            if (l.resources != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.bookmark_border, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l.resources!,
                                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (l.notes != null) ...[
                              const SizedBox(height: 8),
                              Text(l.notes!, style: theme.textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
