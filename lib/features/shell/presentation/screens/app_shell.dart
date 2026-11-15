import 'package:flutter/material.dart';

import '../../../account/presentation/screens/account_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../expenses/presentation/widgets/expense_sheet.dart';
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

  /// The add button covers both halves of the app, so it asks which.
  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Scan a bill'),
              subtitle: const Text('Keep a warranty or document with its date'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openCapture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee_rounded),
              title: const Text('Log an expense'),
              subtitle: const Text('Add what you spent today'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showExpenseSheet(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openCapture() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CaptureBillScreen()));
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
        onAdd: _openAddSheet,
      ),
    );
  }
}
