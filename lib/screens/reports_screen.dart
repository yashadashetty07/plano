import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/report_service.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPreset = '7days';

  void _applyPreset(String preset) {
    setState(() => _selectedPreset = preset);
    final provider = context.read<AppProvider>();
    final now = DateTime.now();
    DateTime start;
    if (preset == '7days') {
      start = now.subtract(const Duration(days: 6));
    } else if (preset == '30days') {
      start = now.subtract(const Duration(days: 29));
    } else {
      // Month to date
      start = DateTime(now.year, now.month, 1);
    }
    provider.setReportDateRange(DateTimeRange(start: start, end: now));
  }

  void _showCsvExportModal(BuildContext context, PlanoReportData report) {
    final activitiesCsv = ReportService.exportActivitiesToCsv(
      context.read<AppProvider>().activities,
    );
    final reportSummaryCsv = ReportService.exportReportSummaryToCsv(report);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deterministic CSV Export',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Copy or save raw deterministic CSV records. Calculations adhere to stored timestamps and timezone specifications.',
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export Activity Logs CSV'),
              subtitle: const Text('All individual logged activity records with duration and tags'),
              trailing: const Icon(Icons.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: activitiesCsv));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activities CSV copied to clipboard!')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Export Summary Analytics CSV'),
              subtitle: const Text('Category breakdown, task rates, habit consistency, and health stats'),
              trailing: const Icon(Icons.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: reportSummaryCsv));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics Summary CSV copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final report = provider.currentReport;
    final df = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () => _showCsvExportModal(context, report),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Range selection and provenance bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Date Window', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(height: 2),
                          Text(
                            '${df.format(report.startDate)} — ${df.format(report.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, size: 16),
                        label: const Text('Change'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                            initialDateRange: provider.reportDateRange,
                          );
                          if (picked != null) {
                            setState(() => _selectedPreset = 'custom');
                            provider.setReportDateRange(picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Preset Chips
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Last 7 Days'),
                        selected: _selectedPreset == '7days',
                        onSelected: (_) => _applyPreset('7days'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Last 30 Days'),
                        selected: _selectedPreset == '30days',
                        onSelected: (_) => _applyPreset('30days'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('This Month'),
                        selected: _selectedPreset == 'month',
                        onSelected: (_) => _applyPreset('month'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Timezone: ${report.timezone} • Generated: ${DateFormat('HH:mm:ss').format(report.generatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.8 : 1.5,
                children: [
                  StatCard(
                    label: 'Total Time',
                    value: '${(report.totalLoggedMinutes / 60.0).toStringAsFixed(1)}h',
                    subtitle: '${report.totalLoggedMinutes} minutes',
                    icon: Icons.timelapse,
                    iconColor: const Color(0xFF0D9488),
                  ),
                  StatCard(
                    label: 'Task Completion',
                    value: '${report.taskCompletionRate.toInt()}%',
                    subtitle: '${report.completedTasks} / ${report.totalTasks} tasks',
                    icon: Icons.task_alt,
                    iconColor: const Color(0xFF6366F1),
                  ),
                  StatCard(
                    label: 'Habit Consistency',
                    value: '${report.habitConsistencyRate.toInt()}%',
                    subtitle: '${report.totalActualHabitCheckins} check-ins',
                    icon: Icons.repeat_on,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  StatCard(
                    label: 'Health Steps',
                    value: report.hasHealthData ? '${report.totalSteps}' : 'Unavailable',
                    subtitle: report.hasHealthData ? '${report.totalHealthWorkoutMinutes}m workout' : 'No sync in range',
                    icon: Icons.directions_walk,
                    iconColor: const Color(0xFF10B981),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Category Time Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time by Category',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Deterministic calculation',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (report.categoryBreakdown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text('No logged activities in this period.')),
                    )
                  else
                    Column(
                      children: report.categoryBreakdown.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat.category.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    '${(cat.totalMinutes / 60.0).toStringAsFixed(1)}h (${cat.percentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: cat.percentage / 100.0,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Learning & Studies Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning & Skill Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Total Study Time: ${(report.totalLearningMinutes / 60.0).toStringAsFixed(1)} hours'),
                  const SizedBox(height: 8),
                  if (report.learningTopics.isNotEmpty) ...[
                    const Text('Topics Covered:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: report.learningTopics
                          .map((t) => Chip(
                                avatar: const Icon(Icons.school, size: 14),
                                label: Text(t),
                              ))
                          .toList(),
                    ),
                  ] else ...[
                    Text('No learning sessions recorded in this date range.', style: TextStyle(color: theme.colorScheme.outline)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
