# Flutter test conventions

## Framework & placement
- Use `flutter_test`. Mocking: `mocktail` (no codegen).
- Tests live in /test, mirroring /lib. File name: <source>_test.dart

## Standard imports
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

## Naming
- group() per class/feature; test() describes behavior, not method:
  'returns cached user when network is offline' — not 'test getUser'

## Mocking idiom (mocktail — THIS is Flutter-specific, do not mix frameworks)
class MockUserApi extends Mock implements UserApi {}

final api = MockUserApi();
when(() => api.fetchUser(any())).thenAnswer((_) async => testUser); // success
when(() => api.fetchUser(any())).thenThrow(SocketException('offline')); // failure
verify(() => api.fetchUser('123')).called(1);
// For custom argument types, registerFallbackValue(FakeFoo()) in setUpAll.

## Async rule
Every async path is tested twice: once for success, once for failure.

## Worked example
group('UserRepository', () {
  late MockUserApi api;
  late UserRepository repo;
  setUp(() { api = MockUserApi(); repo = UserRepository(api); });

  test('returns user on success', () async {
    when(() => api.fetchUser('1')).thenAnswer((_) async => testUser);
    final result = await repo.getUser('1');
    expect(result, testUser);
  });

  test('throws RepoException when api fails', () async {
    when(() => api.fetchUser('1')).thenThrow(SocketException('x'));
    expect(() => repo.getUser('1'), throwsA(isA<RepoException>()));
  });
});