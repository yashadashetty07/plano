import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateFormat = DateFormat('EEEE, MMM d');

    // Filter today's tasks
    final todaysTasks = provider.tasks.where((t) {
      if (t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isAtSameMomentAs(today);
    }).toList();

    // Filter today's activity logs
    final todaysActivities = provider.activities.where((a) {
      final actDate = DateTime(a.date.year, a.date.month, a.date.day);
      return actDate.isAtSameMomentAs(today);
    }).toList();

    int totalMinutesToday = 0;
    for (final a in todaysActivities) {
      totalMinutesToday += a.durationMinutes;
    }

    final completedTasksToday = todaysTasks.where((t) => t.isCompleted).length;

    // Health summary for today
    final healthToday = provider.healthSummaries.where((h) {
      final hDate = DateTime(h.date.year, h.date.month, h.date.day);
      return hDate.isAtSameMomentAs(today);
    }).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              dateFormat.format(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Health Connect',
            onPressed: () => provider.syncHealthData(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => provider.setNavigationIndex(6),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Quick action banner
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ask Plano: "Studied OSPF for 45 mins" or "Add a task to..."',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.setNavigationIndex(5),
                      child: const Text('Open AI'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Stat Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final crossAxisCount = isWide ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.8 : 1.5,
                  children: [
                    StatCard(
                      label: "Today's Tasks",
                      value: '${todaysTasks.length}',
                      subtitle: '$completedTasksToday completed',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF0D9488),
                      onTap: () => provider.setNavigationIndex(2),
                    ),
                    StatCard(
                      label: "Time Logged",
                      value: totalMinutesToday >= 60
                          ? '${(totalMinutesToday / 60).toStringAsFixed(1)}h'
                          : '${totalMinutesToday}m',
                      subtitle: '${todaysActivities.length} logs today',
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF6366F1),
                      onTap: () => provider.setNavigationIndex(1),
                    ),
                    StatCard(
                      label: "Habits Done",
                      value: '${provider.habits.where((h) => provider.isHabitChecked(h.id, today)).length} / ${provider.habits.length}',
                      subtitle: 'Daily consistency',
                      icon: Icons.repeat,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () => provider.setNavigationIndex(3),
                    ),
                    StatCard(
                      label: "Health Steps",
                      value: healthToday != null ? '${healthToday.stepCount}' : 'Unavailable',
                      subtitle: healthToday != null
                          ? '${healthToday.source} synced'
                          : 'Not synced today',
                      icon: Icons.directions_walk,
                      iconColor: const Color(0xFF10B981),
                      onTap: () => provider.setNavigationIndex(6),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 1: Habits Quick Check-in
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Habits",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => provider.setNavigationIndex(3),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.habits.isEmpty)
              const EmptyState(
                icon: Icons.repeat,
                title: 'No habits created yet',
                message: 'Track recurring routines and see your streaks grow.',
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: provider.habits.map((h) {
                      final isChecked = provider.isHabitChecked(h.id, today);
                      final streak = provider.getHabitStreak(h.id);
                      return ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outline,
                          ),
                          onPressed: () => provider.toggleHabitCheckin(h.id, today),
                        ),
                        title: Text(
                          h.name,
                          style: TextStyle(
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text('${h.targetSchedule} • ${h.category}'),
                        trailing: streak > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('$streak day streak', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Section 2: Tasks Due Today
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tasks Due Today",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => provider.setNavigationIndex(2),
                  child: const Text('All Tasks'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todaysTasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No tasks scheduled for today. Great job or plan your day!',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: todaysTasks.map((t) {
                    return CheckboxListTile(
                      value: t.isCompleted,
                      onChanged: (_) => provider.toggleTaskStatus(t),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        'Priority: ${t.priority.toUpperCase()} • ${t.category ?? "general"}',
                      ),
                      secondary: Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.priority == 'high'
                              ? Colors.redAccent
                              : (t.priority == 'urgent' ? Colors.deepOrange : Colors.teal),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),

            // Section 3: Recent Activity Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Activities Today",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => provider.setNavigationIndex(1),
                  child: const Text('Log Activity'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todaysActivities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No activities logged today yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaysActivities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final a = todaysActivities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          '${a.durationMinutes}m',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${a.category} • ${a.source}'),
                      trailing: a.notes != null && a.notes!.isNotEmpty
                          ? Tooltip(message: a.notes!, child: const Icon(Icons.notes, size: 16))
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
