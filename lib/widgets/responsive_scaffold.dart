import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/activities_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/habits_learning_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/settings_screen.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    ActivitiesScreen(),
    TasksProjectsScreen(),
    HabitsLearningScreen(),
    ReportsScreen(),
    AssistantScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final selectedIdx = provider.selectedNavigationIndex;

    if (isDesktop) {
      // Desktop / Responsive Web Layout with NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIdx,
              onDestinationSelected: (idx) => provider.setNavigationIndex(idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Tooltip(
                  message: 'Plano Productivity Hub',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: Text('Activities'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.task_alt_outlined),
                  selectedIcon: Icon(Icons.task_alt),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.repeat_outlined),
                  selectedIcon: Icon(Icons.repeat),
                  label: Text('Habits'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: Text('Assistant'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: selectedIdx,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Layout with NavigationBar
    // For mobile NavigationBar, show top 5 items, and remaining in overflow / appbar
    final mobileIdx = selectedIdx > 4 ? 0 : selectedIdx;

    return Scaffold(
      body: IndexedStack(
        index: selectedIdx,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIdx,
        onDestinationSelected: (idx) {
          if (idx == 4) {
            // More menu for reports & settings
            _showMobileMoreMenu(context);
          } else {
            provider.setNavigationIndex(idx);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _showMobileMoreMenu(BuildContext context) {
    final provider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Habits & Learning'),
              subtitle: const Text('Daily routines, study sessions, and streaks'),
              onTap: () {
                Navigator.pop(ctx);
                provider.setNavigationIndex(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Reports & Analytics'),
              subtitle: const Text('Deterministic summaries and CSV exports'),
              onTap: () {
                Navigator.pop(ctx);
                provider.setNavigationIndex(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings & Privacy'),
              subtitle: const Text('Theme, Health Connect, profile, and AI controls'),
              onTap: () {
                Navigator.pop(ctx);
                provider.setNavigationIndex(6);
              },
            ),
          ],
        ),
      ),
    );
  }
}
