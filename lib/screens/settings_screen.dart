import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/health_connect_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final profile = provider.profile;
    final healthConn = provider.healthIntegration;
    final healthSdk = provider.healthSdkStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Profile & Timezone
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile & Workspace', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName[0] : 'U',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(profile?.fullName ?? 'Plano User', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Private Personal Workspace (Default Owner)'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Configured Timezone'),
                    subtitle: Text(profile?.timezone ?? 'UTC'),
                    trailing: const Icon(Icons.lock_outline, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Appearance & Theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance & Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default (Follows OS / Material You)'),
                    value: ThemeMode.system,
                    groupValue: provider.themeMode,
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Canvas'),
                    value: ThemeMode.light,
                    groupValue: provider.themeMode,
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Night Slate (Dark Theme)'),
                    value: ThemeMode.dark,
                    groupValue: provider.themeMode,
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Android Health Connect & Samsung Health Integration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Health Connect (Android)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: healthSdk == HealthSdkStatus.available
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          healthSdk == HealthSdkStatus.available ? 'AVAILABLE' : 'WEB / STANDBY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: healthSdk == HealthSdkStatus.available ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plano integrates with official Android Health Connect for opt-in, read-only aggregation of daily steps and exercise sessions. Samsung Health synchronizes supported records into Health Connect when configured.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sync_outlined),
                    title: const Text('Last Synchronization'),
                    subtitle: Text(
                      healthConn?.lastSyncAt != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(healthConn!.lastSyncAt!)
                          : 'Never synchronized',
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => provider.syncHealthData(),
                      child: const Text('Sync Now'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    title: const Text('Delete Imported Health Records'),
                    subtitle: const Text('Permanently wipes all imported steps and workout summaries from Plano database.'),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Health Data?'),
                          content: const Text('This will delete all imported health records stored in Plano. Your original data in Health Connect / Samsung Health remains unaffected.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.clearHealthData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Imported health records deleted.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. AI & Groq Privacy Disclosures
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('AI Privacy & Data Minimization', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Privacy First: Raw health records and biometric data are NEVER sent to the AI model by default.\n• Strict Isolation: AI requests are routed through verified Supabase JWT claims and protected n8n webhooks.\n• Schema Enforcement: Output from the model is strictly validated against schemas before any action occurs.\n• Non-authoritative: AI never calculates authoritative statistics or totals; all numbers are calculated by deterministic code.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
