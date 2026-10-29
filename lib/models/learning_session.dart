class LearningSession {
  final String id;
  final String userId;
  final String? projectId;
  final String topic;
  final String? resources;
  final int durationMinutes;
  final DateTime sessionDate;
  final String? notes;
  final String? goal;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningSession({
    required this.id,
    required this.userId,
    this.projectId,
    required this.topic,
    this.resources,
    required this.durationMinutes,
    required this.sessionDate,
    this.notes,
    this.goal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningSession.fromJson(Map<String, dynamic> json) {
    return LearningSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      topic: json['topic'] as String,
      resources: json['resources'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      sessionDate: DateTime.parse(json['session_date'] as String),
      notes: json['notes'] as String?,
      goal: json['goal'] as String?,
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
      'topic': topic,
      'resources': resources,
      'duration_minutes': durationMinutes,
      'session_date': sessionDate.toIso8601String().split('T').first,
      'notes': notes,
      'goal': goal,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  LearningSession copyWith({
    String? topic,
    String? resources,
    int? durationMinutes,
    DateTime? sessionDate,
    String? notes,
    String? goal,
    String? projectId,
  }) {
    return LearningSession(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      topic: topic ?? this.topic,
      resources: resources ?? this.resources,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionDate: sessionDate ?? this.sessionDate,
      notes: notes ?? this.notes,
      goal: goal ?? this.goal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
