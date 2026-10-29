import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';

class TasksProjectsScreen extends StatefulWidget {
  const TasksProjectsScreen({super.key});

  @override
  State<TasksProjectsScreen> createState() => _TasksProjectsScreenState();
}

class _TasksProjectsScreenState extends State<TasksProjectsScreen> with SingleTickerProviderStateMixin {
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

  void _showAddEditTaskDialog({PlanoTask? existing}) {
    final provider = context.read<AppProvider>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final estController = TextEditingController(
      text: existing != null ? existing.estimatedMinutes.toString() : '30',
    );
    String selectedPriority = existing?.priority ?? 'medium';
    String? selectedProjectId = existing?.projectId;
    DateTime? selectedDueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Create Task' : 'Edit Task'),
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
                      labelText: 'Task Title *',
                      hintText: 'e.g. Finish project documentation',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: const InputDecoration(labelText: 'Priority *'),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'high', child: Text('High')),
                            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPriority = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: estController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Estimate (mins)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Project selector
                  if (provider.projects.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      value: selectedProjectId,
                      decoration: const InputDecoration(labelText: 'Associated Project'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None (General)')),
                        ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProjectId = val),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Due date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDueDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedDueDate != null
                              ? DateFormat('yyyy-MM-dd').format(selectedDueDate!)
                              : 'No Due Date'),
                          const Icon(Icons.event, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Context',
                      hintText: 'Acceptance criteria or details...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final est = int.tryParse(estController.text.trim()) ?? 0;

                final task = PlanoTask(
                  id: existing?.id ?? _uuid.v4(),
                  userId: provider.profile?.id ?? 'local-user-001',
                  projectId: selectedProjectId,
                  title: title,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  status: existing?.status ?? 'todo',
                  priority: selectedPriority,
                  dueDate: selectedDueDate,
                  estimatedMinutes: est,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await provider.addTask(task);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Create Task' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    final provider = context.read<AppProvider>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final catController = TextEditingController(text: 'work');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Project'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Project Name *', hintText: 'e.g. Plano App Core'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Strategic goals and milestone targets'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catController,
                decoration: const InputDecoration(labelText: 'Category', hintText: 'work, learning, personal'),
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

              final project = Project(
                id: _uuid.v4(),
                userId: provider.profile?.id ?? 'local-user-001',
                name: name,
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                category: catController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await provider.addProject(project);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');

    // Filter tasks
    final tasksList = provider.tasks.where((t) {
      if (provider.taskStatusFilter == 'todo') return !t.isCompleted;
      if (provider.taskStatusFilter == 'completed') return t.isCompleted;
      if (provider.taskStatusFilter == 'overdue') return t.isOverdue;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Projects', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tasks (${provider.tasks.length})'),
            Tab(text: 'Projects (${provider.projects.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditTaskDialog();
          } else {
            _showAddProjectDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'New Task' : 'New Project'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Tasks
          Column(
            children: [
              // Filter chips for tasks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('ALL'),
                      selected: provider.taskStatusFilter == 'all',
                      onSelected: (_) => provider.setTaskStatusFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('TODO'),
                      selected: provider.taskStatusFilter == 'todo',
                      onSelected: (_) => provider.setTaskStatusFilter('todo'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('COMPLETED'),
                      selected: provider.taskStatusFilter == 'completed',
                      onSelected: (_) => provider.setTaskStatusFilter('completed'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('OVERDUE'),
                      selected: provider.taskStatusFilter == 'overdue',
                      onSelected: (_) => provider.setTaskStatusFilter('overdue'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasksList.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No tasks found',
                        message: 'Add tasks with priorities and deadlines to keep work organized.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: tasksList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = tasksList[index];
                          final project = provider.projects.where((p) => p.id == task.projectId).firstOrNull;
                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => provider.toggleTaskStatus(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null) ...[
                                    const SizedBox(height: 2),
                                    Text(task.description!, style: theme.textTheme.bodySmall),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (project != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            project.name,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      if (task.dueDate != null) ...[
                                        Icon(
                                          Icons.event,
                                          size: 12,
                                          color: task.isOverdue ? Colors.red : theme.colorScheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateFormat.format(task.dueDate!),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: task.isOverdue ? Colors.red : theme.colorScheme.outline,
                                            fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        'Est: ${task.estimatedMinutes}m',
                                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showAddEditTaskDialog(existing: task);
                                  } else if (action == 'delete') {
                                    provider.deleteTask(task.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // TAB 2: Projects
          provider.projects.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open,
                  title: 'No projects yet',
                  message: 'Group tasks and activities by core initiative.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: provider.projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = provider.projects[index];
                    final projTasks = provider.tasks.where((t) => t.projectId == p.id).toList();
                    final completed = projTasks.where((t) => t.isCompleted).length;
                    final progress = projTasks.isNotEmpty ? (completed / projTasks.length) : 0.0;

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
                                    p.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => provider.deleteProject(p.id),
                                ),
                              ],
                            ),
                            if (p.description != null) ...[
                              const SizedBox(height: 4),
                              Text(p.description!, style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${projTasks.length} tasks ($completed done)', style: theme.textTheme.bodySmall),
                                Text('${(progress * 100).toInt()}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
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
