class ActivityLog {
  final String id;
  final String userId;
  final String? projectId;
  final String? taskId;
  final String title;
  final String? description;
  final String category; // 'work', 'personal_project', 'learning', 'workout', 'habit', 'admin', 'creative', 'rest', 'custom'
  final List<String> tags;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String timezone;
  final String? notes;
  final String source; // 'manual', 'assistant', 'health_connect', 'timer'
  final String? idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityLog({
    required this.id,
    required this.userId,
    this.projectId,
    this.taskId,
    required this.title,
    this.description,
    required this.category,
    this.tags = const [],
    required this.date,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.timezone,
    this.notes,
    this.source = 'manual',
    this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      taskId: json['task_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      timezone: json['timezone'] as String? ?? 'UTC',
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'manual',
      idempotencyKey: json['idempotency_key'] as String?,
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
      'task_id': taskId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'timezone': timezone,
      'notes': notes,
      'source': source,
      'idempotency_key': idempotencyKey,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ActivityLog copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? notes,
    String? projectId,
    String? taskId,
  }) {
    return ActivityLog(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timezone: timezone,
      notes: notes ?? this.notes,
      source: source,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
