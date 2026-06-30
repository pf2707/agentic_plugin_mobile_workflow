# Swift / SwiftUI test conventions

## Framework & placement
- Use **Swift Testing** (the `Testing` module, `@Test` / `#expect`), NOT XCTest.
- Mocking: hand-written stubs/spies conforming to the dependency's protocol — no
  mocking library. Inject dependencies through initializers.
- Tests live in /Tests/<Module>Tests, file name: <Source>Tests.swift

## Standard imports
import Testing
@testable import MyModule

## Naming
- Group with `struct` suites; name tests by behavior, not method:
  @Test("returns cached user when network is offline")
- Use `@Suite` to group related tests when helpful.

## Mocking idiom (protocol stub — Swift-specific, do not mix with XCTest/OCMock)
protocol UserApi { func fetchUser(_ id: String) async throws -> User }

final class StubUserApi: UserApi {
    var result: Result<User, Error> = .success(.test)
    private(set) var calls: [String] = []
    func fetchUser(_ id: String) async throws -> User {
        calls.append(id)
        return try result.get()
    }
}

## Assertions
- `#expect(value == expected)` for soft checks.
- `#require(optional)` to unwrap and stop the test if nil.
- Async throwing: `await #expect(throws: RepoError.self) { try await repo.getUser("1") }`

## Async rule
Every async path is tested twice: once for success, once for failure.

## Worked example
struct UserRepositoryTests {
    @Test("returns user on success")
    func returnsUser() async throws {
        let api = StubUserApi()
        api.result = .success(.test)
        let repo = UserRepository(api: api)

        let user = try await repo.getUser("1")

        #expect(user == .test)
        #expect(api.calls == ["1"])
    }

    @Test("throws RepoError when api fails")
    func throwsOnFailure() async {
        let api = StubUserApi()
        api.result = .failure(URLError(.notConnectedToInternet))
        let repo = UserRepository(api: api)

        await #expect(throws: RepoError.self) {
            try await repo.getUser("1")
        }
    }
}

## SwiftUI note
Test view *models* and observable state directly. Keep `View` bodies thin so logic
lives in testable types; do not attempt to snapshot-test views here.
