class Profile {
  final String id;
  final String fullName;
  final String timezone;
  final String themeMode; // 'system', 'light', 'dark'
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.timezone,
    this.themeMode = 'system',
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Plano User',
      timezone: json['timezone'] as String? ?? 'UTC',
      themeMode: json['theme_mode'] as String? ?? 'system',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'timezone': timezone,
      'theme_mode': themeMode,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? timezone,
    String? themeMode,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      timezone: timezone ?? this.timezone,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt,
    );
  }
}
