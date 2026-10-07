import 'package:flutter/material.dart';

import '../ui/screens/emergency_directory_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/map_screen.dart';
import '../ui/screens/my_reports_screen.dart';
import '../ui/screens/profile_settings_screen.dart';
import '../ui/screens/report_incident_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = HomeTab.home;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget get _selectedScreen {
    return switch (_selectedIndex) {
      HomeTab.map => const MapScreen(),
      HomeTab.report => ReportIncidentScreen(
          onViewMyReports: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MyReportsScreen(),
              ),
            );
          },
        ),
      HomeTab.directory => const EmergencyDirectoryScreen(),
      HomeTab.profile => const ProfileSettingsScreen(),
      // Home, and anything unexpected, lands on the dashboard.
      _ => HomeScreen(onNavigate: _selectTab),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.report_outlined), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Directory'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
