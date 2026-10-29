class AssistantAction {
  final String id;
  final String userPrompt;
  final String intent; // 'log_activity', 'create_task', 'checkin_habit', 'query_summary', 'clarify_question', 'unconfigured'
  final Map<String, dynamic> parameters;
  final bool isDestructive;
  final bool requiresConfirmation;
  final bool isConfirmed;
  final String executionStatus; // 'preview', 'confirmed', 'executed', 'cancelled', 'failed'
  final String? clarificationQuestion;
  final String summary;
  final DateTime timestamp;

  AssistantAction({
    required this.id,
    required this.userPrompt,
    required this.intent,
    this.parameters = const {},
    this.isDestructive = false,
    this.requiresConfirmation = false,
    this.isConfirmed = false,
    this.executionStatus = 'preview',
    this.clarificationQuestion,
    required this.summary,
    required this.timestamp,
  });

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    return AssistantAction(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userPrompt: json['user_prompt'] as String? ?? '',
      intent: json['intent'] as String? ?? 'unsupported',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
      isDestructive: json['is_destructive'] as bool? ?? false,
      requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      executionStatus: json['execution_status'] as String? ?? 'preview',
      clarificationQuestion: json['clarification_question'] as String?,
      summary: json['summary'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_prompt': userPrompt,
      'intent': intent,
      'parameters': parameters,
      'is_destructive': isDestructive,
      'requires_confirmation': requiresConfirmation,
      'is_confirmed': isConfirmed,
      'execution_status': executionStatus,
      'clarification_question': clarificationQuestion,
      'summary': summary,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AssistantAction copyWith({
    bool? isConfirmed,
    String? executionStatus,
  }) {
    return AssistantAction(
      id: id,
      userPrompt: userPrompt,
      intent: intent,
      parameters: parameters,
      isDestructive: isDestructive,
      requiresConfirmation: requiresConfirmation,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      executionStatus: executionStatus ?? this.executionStatus,
      clarificationQuestion: clarificationQuestion,
      summary: summary,
      timestamp: timestamp,
    );
  }
}
