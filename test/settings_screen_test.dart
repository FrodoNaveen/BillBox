import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/features/account/presentation/screens/account_screen.dart';
import 'package:billbox/features/auth/data/auth_local_data_source.dart';
import 'package:billbox/features/auth/data/auth_repository.dart';
import 'package:billbox/features/auth/presentation/providers/auth_provider.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/settings/presentation/providers/settings_provider.dart';
import 'package:billbox/features/settings/presentation/screens/profile_details_screen.dart';
import 'package:billbox/features/settings/presentation/screens/reminder_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late InMemoryStore store;
  late AuthRepository auth;
  late SettingsRepository settings;

  setUp(() {
    store = InMemoryStore();
    auth = AuthRepository(dataSource: AuthLocalDataSource(store));
    settings = SettingsRepository(store);
  });

  /// The account tab with a signed-in person, as the shell shows it.
  Future<void> pumpAccountTab(WidgetTester tester, {String? phone}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await auth.signUp(
      name: 'Naveen Kumar',
      email: 'naveen@example.com',
      password: 'billbox2026',
      phone: phone,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repository: auth)..bootstrap(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(repository: settings)..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the tab shows who is signed in and the saved settings', (
    tester,
  ) async {
    await pumpAccountTab(tester);

    expect(find.text('Hi Naveen'), findsOneWidget);
    expect(find.text('naveen@example.com'), findsOneWidget);
    expect(find.textContaining('30, 7, 1 days before'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);
  });

  testWidgets('turning reminders off is saved and shown on the tab', (
    tester,
  ) async {
    await pumpAccountTab(tester);

    await tester.tap(find.text('Reminder settings'));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderSettingsScreen), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect((await settings.read()).remindersEnabled, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Off — nothing will be sent'), findsOneWidget);
  });

  testWidgets('a lead time can be dropped and is saved', (tester) async {
    await pumpAccountTab(tester);

    await tester.tap(find.text('Reminder settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 days before'));
    await tester.pumpAndSettle();

    expect((await settings.read()).leadDays.toList(), [30, 1]);
  });

  testWidgets('lead times cannot be changed while reminders are off', (
    tester,
  ) async {
    await settings.write(
      (await settings.read()).copyWith(remindersEnabled: false),
    );
    await pumpAccountTab(tester);

    await tester.tap(find.text('Reminder settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 days before'));
    await tester.pumpAndSettle();

    expect((await settings.read()).leadDays.contains(7), isTrue);
  });

  testWidgets('the time row opens the clock', (tester) async {
    await pumpAccountTab(tester);

    await tester.tap(find.text('Reminder settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send reminders at'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('editing the profile saves the name and phone', (tester) async {
    await pumpAccountTab(tester);

    await tester.tap(find.text('Profile details'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDetailsScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Naveen V');
    await tester.enterText(find.byType(TextFormField).at(1), '98765 43210');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    final saved = await auth.currentUser();
    expect(saved?.name, 'Naveen V');
    expect(saved?.phone, '9876543210');

    // Back on the tab, the row reflects the new details.
    expect(find.text('Naveen V · 9876543210'), findsOneWidget);
  });

  testWidgets('a bad number is caught before saving', (tester) async {
    await pumpAccountTab(tester);

    await tester.tap(find.text('Profile details'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a 10-digit number'), findsOneWidget);
    expect((await auth.currentUser())?.phone, isNull);
  });
}
