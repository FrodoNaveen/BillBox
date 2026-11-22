import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../account/presentation/screens/account_screen.dart';
import '../../../expenses/presentation/providers/hands_free_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../expenses/presentation/widgets/expense_sheet.dart';
import '../../../expenses/presentation/widgets/voice_expense_sheet.dart';
import '../../../items/presentation/screens/capture_bill_screen.dart';
import '../../../reminders/presentation/screens/reminders_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/billbox_nav_bar.dart';

/// Holds the four tabs and the bottom bar. Each tab keeps its own state, so
/// switching back and forth does not rebuild the dashboard from scratch.
///
/// It also owns hands-free listening, because that has to work from any tab:
/// it follows the saved setting, drops the microphone whenever the app leaves
/// the foreground, and opens the read-back sheet when a command is heard.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  ShellTab _current = ShellTab.home;

  /// True while the read-back sheet is already up, so a second command
  /// cannot stack another sheet on top of it.
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Settings are read after the first frame, so the toggle is applied once
    // the saved value is actually known.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHandsFree());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Neither platform lets a backgrounded app keep the microphone, so the
  /// loop is stopped on the way out and picked up again on the way back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final handsFree = context.read<HandsFreeProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        handsFree.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        handsFree.pause();
    }
  }

  /// Keeps the listener in step with the saved setting.
  Future<void> _syncHandsFree() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final handsFree = context.read<HandsFreeProvider>();
    await handsFree.setEnabled(settings.settings.handsFreeEnabled);
  }

  /// Opens the read-back sheet on a command heard hands-free.
  Future<void> _askAboutCaught() async {
    if (_isAsking) return;
    final handsFree = context.read<HandsFreeProvider>();
    final draft = handsFree.takeCaught();
    if (draft == null) return;

    setState(() => _isAsking = true);
    // Listening stops while the sheet is up, so the sheet's own microphone
    // is not fighting the loop for the device.
    await handsFree.pause();
    if (mounted) await showVoiceExpenseSheet(context, caught: draft);
    if (!mounted) return;

    setState(() => _isAsking = false);
    await handsFree.resume();
  }

  void _select(ShellTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
  }

  /// The add button covers both halves of the app, so it asks which.
  ///
  /// Voice sits at the top because it is the one people reach for daily: two
  /// taps from any tab to "add 50 rupees for medicines".
  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text('Say what you spent'),
              subtitle: const Text('"Add 50 rupees for medicines"'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showVoiceExpenseSheet(context);
              },
            ),
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
              title: const Text('Type an expense'),
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
    // A command caught while any tab was open: ask about it once this frame
    // is done, since a sheet cannot be opened from inside build.
    final settings = context.watch<SettingsProvider>().settings;
    final handsFree = context.watch<HandsFreeProvider>();
    if (handsFree.caught != null && !_isAsking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askAboutCaught());
    }
    if (settings.handsFreeEnabled != handsFree.isEnabled &&
        handsFree.problem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncHandsFree());
    }

    return Scaffold(
      body: IndexedStack(
        index: ShellTab.values.indexOf(_current),
        children: [
          HomeScreen(
            onOpenSearch: () => _select(ShellTab.search),
            onOpenReminders: () => _select(ShellTab.reminders),
          ),
          RemindersScreen(onAddItem: _openCapture),
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
