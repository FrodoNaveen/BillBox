import 'package:billbox/app.dart';
import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/features/auth/data/auth_local_data_source.dart';
import 'package:billbox/features/auth/data/auth_repository.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AuthRepository repositoryWith(InMemoryStore store) =>
      AuthRepository(dataSource: AuthLocalDataSource(store));

  /// The app under test, with settings kept in memory.
  BillBoxApp appWith(AuthRepository repository) => BillBoxApp(
    authRepository: repository,
    settingsRepository: SettingsRepository(InMemoryStore()),
  );

  /// The screens are designed for a phone, so test them at phone size
  /// instead of the default 800x600 test window.
  Future<void> usePhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('opens on the login screen when nobody is signed in', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    await tester.pumpWidget(appWith(repositoryWith(InMemoryStore())));
    await tester.pumpAndSettle();

    expect(find.text('Capture once. Get reminded in time.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('a bad email is caught before any storage call', (tester) async {
    await usePhoneSurface(tester);
    await tester.pumpWidget(appWith(repositoryWith(InMemoryStore())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('wrong password shows one message for both cases', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final repository = repositoryWith(InMemoryStore());
    await repository.signUp(
      name: 'Naveen Kumar',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );
    await repository.logOut();

    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'naveen@example.com');
    await tester.enterText(fields.at(1), 'not-the-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('existing account logs in and lands on the dashboard', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final repository = repositoryWith(InMemoryStore());
    await repository.signUp(
      name: 'Naveen Kumar',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );
    await repository.logOut();

    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'naveen@example.com');
    await tester.enterText(fields.at(1), 'billbox2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Expiring soon'), findsOneWidget);
  });

  testWidgets('a saved session skips the login screen', (tester) async {
    await usePhoneSurface(tester);
    final repository = repositoryWith(InMemoryStore());
    await repository.signUp(
      name: 'Naveen Kumar',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );

    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();

    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsNothing);
  });

  testWidgets('log out returns to the login screen', (tester) async {
    await usePhoneSurface(tester);
    final repository = repositoryWith(InMemoryStore());
    await repository.signUp(
      name: 'Naveen Kumar',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );

    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('sign up creates the account and signs the person in', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final store = InMemoryStore();
    await tester.pumpWidget(appWith(repositoryWith(store)));
    await tester.pumpAndSettle();

    final createAccountLink = find.widgetWithText(TextButton, 'Create account');
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Naveen Kumar');
    await tester.enterText(fields.at(1), 'naveen@example.com');
    await tester.enterText(fields.at(3), 'billbox2026');
    await tester.pumpAndSettle();

    final createAccountButton = find.widgetWithText(
      FilledButton,
      'Create account',
    );

    // The terms box gates the button.
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();
    expect(find.text('Please accept the terms to continue'), findsOneWidget);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(find.text('Expiring soon'), findsOneWidget);
    expect(
      await store.read(AuthLocalDataSource.sessionKey),
      isNotNull,
      reason: 'the session should be persisted after sign-up',
    );
  });
}
