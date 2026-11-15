import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/features/auth/data/auth_exception.dart';
import 'package:billbox/features/auth/data/auth_local_data_source.dart';
import 'package:billbox/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStore store;
  late AuthRepository repository;

  setUp(() {
    store = InMemoryStore();
    repository = AuthRepository(dataSource: AuthLocalDataSource(store));
  });

  test('sign up stores the account and opens a session', () async {
    final user = await repository.signUp(
      name: '  Naveen Kumar ',
      email: ' Naveen@Example.com ',
      password: 'billbox2026',
      phone: '98765 43210',
    );

    expect(user.name, 'Naveen Kumar');
    expect(user.email, 'naveen@example.com');
    expect(user.phone, '9876543210');
    expect(await repository.currentUser(), isNotNull);

    // The raw password must never reach storage.
    final stored = await store.read(AuthLocalDataSource.usersKey);
    expect(stored, isNotNull);
    expect(stored, isNot(contains('billbox2026')));
  });

  test('sign up rejects an email that already has an account', () async {
    await repository.signUp(
      name: 'Naveen',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );

    expect(
      () => repository.signUp(
        name: 'Someone Else',
        email: 'NAVEEN@example.com',
        password: 'another-one',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('log in succeeds with the right password, fails otherwise', () async {
    await repository.signUp(
      name: 'Naveen',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );
    await repository.logOut();

    final user = await repository.logIn(
      email: 'naveen@example.com',
      password: 'billbox2026',
    );
    expect(user.email, 'naveen@example.com');

    expect(
      () => repository.logIn(
        email: 'naveen@example.com',
        password: 'wrong-password',
      ),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => repository.logIn(
        email: 'nobody@example.com',
        password: 'billbox2026',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('log out clears the session but keeps the account', () async {
    await repository.signUp(
      name: 'Naveen',
      email: 'naveen@example.com',
      password: 'billbox2026',
    );

    await repository.logOut();
    expect(await repository.currentUser(), isNull);

    final user = await repository.logIn(
      email: 'naveen@example.com',
      password: 'billbox2026',
    );
    expect(user.name, 'Naveen');
  });

  test('corrupt storage is treated as no accounts', () async {
    await store.write(AuthLocalDataSource.usersKey, 'not json at all');

    expect(await repository.currentUser(), isNull);
    expect(
      () => repository.logIn(email: 'a@b.com', password: 'whatever'),
      throwsA(isA<AuthException>()),
    );
  });
}
