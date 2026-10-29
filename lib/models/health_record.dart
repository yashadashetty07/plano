class HealthSummary {
  final String id;
  final String userId;
  final DateTime date;
  final int stepCount;
  final int workoutCount;
  final int workoutDurationMinutes;
  final String source;
  final List<String> sourceRecordIds;
  final DateTime lastSyncedAt;

  HealthSummary({
    required this.id,
    required this.userId,
    required this.date,
    this.stepCount = 0,
    this.workoutCount = 0,
    this.workoutDurationMinutes = 0,
    this.source = 'Health Connect',
    this.sourceRecordIds = const [],
    required this.lastSyncedAt,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      stepCount: json['step_count'] as int? ?? 0,
      workoutCount: json['workout_count'] as int? ?? 0,
      workoutDurationMinutes: json['workout_duration_minutes'] as int? ?? 0,
      source: json['source'] as String? ?? 'Health Connect',
      sourceRecordIds: (json['source_record_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'step_count': stepCount,
      'workout_count': workoutCount,
      'workout_duration_minutes': workoutDurationMinutes,
      'source': source,
      'source_record_ids': sourceRecordIds,
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }
}

class IntegrationConnection {
  final String id;
  final String userId;
  final String provider; // 'health_connect', 'samsung_health'
  final bool isConnected;
  final List<String> permissionsGranted;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final DateTime updatedAt;

  IntegrationConnection({
    required this.id,
    required this.userId,
    required this.provider,
    this.isConnected = false,
    this.permissionsGranted = const [],
    this.lastSyncAt,
    this.errorMessage,
    required this.updatedAt,
  });

  factory IntegrationConnection.fromJson(Map<String, dynamic> json) {
    return IntegrationConnection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: json['provider'] as String,
      isConnected: json['is_connected'] as bool? ?? false,
      permissionsGranted: (json['permissions_granted'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.tryParse(json['last_sync_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider,
      'is_connected': isConnected,
      'permissions_granted': permissionsGranted,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'error_message': errorMessage,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
