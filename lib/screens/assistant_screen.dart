import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/assistant_action.dart';
import '../providers/app_provider.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'Studied OSPF for 45 minutes',
    'Create a task to finish the project documentation tomorrow',
    'Show my overdue tasks',
    'Summarize my learning and project work this week',
    'Check in daily deep work habit',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitPrompt(String text) {
    if (text.trim().isEmpty) return;
    context.read<AppProvider>().submitAssistantPrompt(text.trim());
    _inputController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final history = provider.assistantHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
                Text(
                  'Schema Validated',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Assistant Chat Timeline
          Expanded(
            child: history.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, size: 48, color: Color(0xFF0D9488)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Typed Natural-Language Assistant',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plano translates your everyday messages into typed database mutations with schema validation. Destructive changes require explicit confirmation.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Text('Try one of these examples:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._suggestedPrompts.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () => _submitPrompt(p),
                              child: Text(p),
                            ),
                          )),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: history.length,
                    itemBuilder: (context, idx) {
                      final action = history[idx];
                      return _buildActionBubble(context, action);
                    },
                  ),
          ),

          if (provider.isLoading)
            const LinearProgressIndicator(minHeight: 2),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Studied OSPF for 45 mins...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _submitPrompt,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () => _submitPrompt(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBubble(BuildContext context, AssistantAction action) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User message bubble
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(left: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                action.userPrompt,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Assistant typed response card
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(right: 32),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: action.isDestructive
                        ? Colors.redAccent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intent badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'INTENT: ${action.intent.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(action.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Clarification Question or Summary
                      if (action.clarificationQuestion != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.help_outline, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                action.clarificationQuestion!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          action.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],

                      // Structured Parameters Preview
                      if (action.parameters.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: action.parameters.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1.0),
                                child: Text(
                                  '• ${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Confirmation / Execution Status
                      if (action.requiresConfirmation && !action.isConfirmed && action.executionStatus != 'cancelled') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: action.isDestructive ? Colors.redAccent : null,
                                foregroundColor: action.isDestructive ? Colors.white : null,
                              ),
                              onPressed: () => provider.executeAssistantAction(action),
                              child: Text(action.isDestructive ? 'Confirm Deletion' : 'Confirm & Apply'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => provider.cancelAssistantAction(action),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ] else if (action.executionStatus == 'executed') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Successfully applied and recorded.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
