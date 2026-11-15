import 'package:flutter/material.dart';

import '../../../account/presentation/screens/account_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../items/presentation/screens/capture_bill_screen.dart';
import '../../../reminders/presentation/screens/reminders_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../widgets/billbox_nav_bar.dart';

/// Holds the four tabs and the bottom bar. Each tab keeps its own state, so
/// switching back and forth does not rebuild the dashboard from scratch.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellTab _current = ShellTab.home;

  void _select(ShellTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
  }

  void _openCapture() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CaptureBillScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: ShellTab.values.indexOf(_current),
        children: [
          HomeScreen(
            onOpenSearch: () => _select(ShellTab.search),
            onOpenReminders: () => _select(ShellTab.reminders),
          ),
          const RemindersScreen(),
          const SearchScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: BillBoxNavBar(
        current: _current,
        onSelect: _select,
        onAdd: _openCapture,
      ),
    );
  }
}
