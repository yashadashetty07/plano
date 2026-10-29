class Project {
  final String id;
  final String userId;
  final String? workspaceId;
  final String name;
  final String? description;
  final String status; // 'active', 'completed', 'archived', 'on_hold'
  final DateTime? targetDate;
  final String? category;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.userId,
    this.workspaceId,
    required this.name,
    this.description,
    this.status = 'active',
    this.targetDate,
    this.category,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workspaceId: json['workspace_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'] as String)
          : null,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
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
      'workspace_id': workspaceId,
      'name': name,
      'description': description,
      'status': status,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'category': category,
      'icon': icon,
      'color': color,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Project copyWith({
    String? name,
    String? description,
    String? status,
    DateTime? targetDate,
    String? category,
    String? icon,
    String? color,
  }) {
    return Project(
      id: id,
      userId: userId,
      workspaceId: workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
