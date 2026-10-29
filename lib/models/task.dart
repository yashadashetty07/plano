class PlanoTask {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final String? description;
  final String status; // 'todo', 'in_progress', 'completed', 'cancelled'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime? dueDate;
  final DateTime? scheduledAt;
  final String? category;
  final List<String> tags;
  final int estimatedMinutes;
  final int actualMinutes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanoTask({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    this.scheduledAt,
    this.category,
    this.tags = const [],
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  factory PlanoTask.fromJson(Map<String, dynamic> json) {
    return PlanoTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      actualMinutes: json['actual_minutes'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  PlanoTask copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? scheduledAt,
    String? category,
    String? projectId,
    List<String>? tags,
    int? estimatedMinutes,
    int? actualMinutes,
    DateTime? completedAt,
  }) {
    return PlanoTask(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
