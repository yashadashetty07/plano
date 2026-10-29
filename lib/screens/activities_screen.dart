import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_log.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _searchController = TextEditingController();
  final _uuid = const Uuid();

  static const List<String> categories = [
    'all',
    'work',
    'personal_project',
    'learning',
    'workout',
    'habit',
    'admin',
    'creative',
    'rest',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditActivityDialog({ActivityLog? existing}) {
    final provider = context.read<AppProvider>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final durationController = TextEditingController(
      text: existing != null ? existing.durationMinutes.toString() : '45',
    );
    final tagsController = TextEditingController(
      text: existing != null ? existing.tags.join(', ') : '',
    );
    String selectedCategory = existing?.category ?? 'work';
    DateTime selectedDate = existing?.date ?? DateTime.now();
    String? selectedProjectId = existing?.projectId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Log Activity' : 'Edit Activity'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Title *',
                      hintText: 'e.g. Studied OSPF for 45 minutes',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: categories.contains(selectedCategory) && selectedCategory != 'all'
                              ? selectedCategory
                              : 'work',
                          decoration: const InputDecoration(labelText: 'Category *'),
                          items: categories
                              .where((c) => c != 'all')
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.replaceAll('_', ' ').toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (mins) *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Project association
                  if (provider.projects.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      value: selectedProjectId,
                      decoration: const InputDecoration(labelText: 'Associated Project (Optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None (Independent)')),
                        ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProjectId = val),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g. networking, cert, deep-work',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Summary',
                      hintText: 'Key learnings, outcomes or next steps...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final dur = int.tryParse(durationController.text.trim()) ?? 0;
                if (title.isEmpty) return;

                final tags = tagsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final log = ActivityLog(
                  id: existing?.id ?? _uuid.v4(),
                  userId: provider.profile?.id ?? 'local-user-001',
                  projectId: selectedProjectId,
                  title: title,
                  category: selectedCategory,
                  durationMinutes: dur,
                  date: selectedDate,
                  timezone: provider.profile?.timezone ?? 'UTC',
                  tags: tags,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  source: existing?.source ?? 'manual',
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (existing == null) {
                  await provider.addActivity(log);
                } else {
                  await provider.addActivity(log);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Save Log' : 'Update Log'),
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
    final dateFormat = DateFormat('MMM d, yyyy');

    // Filter activities
    final filtered = provider.activities.where((a) {
      final matchesCat = provider.activityCategoryFilter == 'all' ||
          a.category.toLowerCase() == provider.activityCategoryFilter.toLowerCase();
      final query = provider.searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          a.title.toLowerCase().contains(query) ||
          (a.notes?.toLowerCase().contains(query) ?? false) ||
          a.tags.any((t) => t.toLowerCase().contains(query));
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => provider.setNavigationIndex(4), // Go to Reports
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditActivityDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search activities, notes, or tags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => provider.setSearchQuery(val),
            ),
          ),

          // Category Chips Row
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = provider.activityCategoryFilter == cat;
                return FilterChip(
                  label: Text(cat.replaceAll('_', ' ').toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => provider.setActivityCategoryFilter(cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Activity Logs List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'No activities found',
                    message: 'Log your work, workouts, study sessions, or creative tasks.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final act = filtered[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${act.durationMinutes}m',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          dateFormat.format(act.date),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            act.category.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'via ${act.source}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (act.notes != null && act.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        act.notes!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                    if (act.tags.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: act.tags
                                            .map((t) => Chip(
                                                  label: Text('#$t', style: const TextStyle(fontSize: 10)),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showAddEditActivityDialog(existing: act);
                                  } else if (action == 'delete') {
                                    provider.deleteActivity(act.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
