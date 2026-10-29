class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final int frequencyTargetDaysPerWeek;
  final String targetSchedule; // 'daily', 'weekdays', 'weekends'
  final String category;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequencyTargetDaysPerWeek = 7,
    this.targetSchedule = 'daily',
    this.category = 'routine',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequencyTargetDaysPerWeek: json['frequency_target_days_per_week'] as int? ?? 7,
      targetSchedule: json['target_schedule'] as String? ?? 'daily',
      category: json['category'] as String? ?? 'routine',
      isArchived: json['is_archived'] as bool? ?? false,
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
      'name': name,
      'description': description,
      'frequency_target_days_per_week': frequencyTargetDaysPerWeek,
      'target_schedule': targetSchedule,
      'category': category,
      'is_archived': isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Habit copyWith({
    String? name,
    String? description,
    int? frequencyTargetDaysPerWeek,
    String? targetSchedule,
    String? category,
    bool? isArchived,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequencyTargetDaysPerWeek: frequencyTargetDaysPerWeek ?? this.frequencyTargetDaysPerWeek,
      targetSchedule: targetSchedule ?? this.targetSchedule,
      category: category ?? this.category,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class HabitCheckin {
  final String id;
  final String habitId;
  final String userId;
  final DateTime checkinDate;
  final String? notes;
  final DateTime createdAt;

  HabitCheckin({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.checkinDate,
    this.notes,
    required this.createdAt,
  });

  factory HabitCheckin.fromJson(Map<String, dynamic> json) {
    return HabitCheckin(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      checkinDate: DateTime.parse(json['checkin_date'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'checkin_date': checkinDate.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}
