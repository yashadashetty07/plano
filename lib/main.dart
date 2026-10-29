import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'services/supabase_service.dart';
import 'widgets/responsive_scaffold.dart';
import 'screens/auth_screen.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService().initialize(
    supabaseUrl: _supabaseUrl,
    supabasePublishableKey: _supabasePublishableKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const PlanoApp(),
    ),
  );
}

class PlanoApp extends StatelessWidget {
  const PlanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Plano — Productivity & Activity Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: provider.themeMode,
      home: SupabaseService().isConfigured
          ? const AuthGate()
          : const _ConfigurationRequired(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    return StreamBuilder<bool>(
      stream: service.authStateChanges.map((state) => state.session?.user != null),
      initialData: service.currentUser != null,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const AuthScreen();
        final provider = context.read<AppProvider>();
        if (!provider.hasLoadedUserData && !provider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) => provider.loadAllData());
        }
        if (!provider.hasLoadedUserData || provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (provider.profile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your Plano profile.'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: provider.loadAllData, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        return const ResponsiveScaffold();
      },
    );
  }
}

class _ConfigurationRequired extends StatelessWidget {
  const _ConfigurationRequired();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Plano is not configured. Build with SUPABASE_URL and '
              'SUPABASE_PUBLISHABLE_KEY using --dart-define-from-file '
              'config/supabase.dev.json.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
