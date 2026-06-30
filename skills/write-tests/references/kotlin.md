# Kotlin (Android) test conventions

## Framework & placement
- Unit tests: **JUnit5** (Jupiter). UI/instrumented tests: **Espresso**.
- Mocking: **MockK** (`io.mockk`), the Kotlin-idiomatic mocker — coroutines aware.
- Unit tests live in /app/src/test/java/...      (file: <Class>Test.kt)
- Espresso tests live in /app/src/androidTest/java/... (file: <Screen>Test.kt)

## Standard imports (unit)
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import io.mockk.*
import kotlinx.coroutines.test.runTest

## Naming
- Backtick behavior names:
  `@Test fun \`returns cached user when network is offline\`() { ... }`

## Mocking idiom (MockK — Kotlin-specific, do not mix with Mockito)
val api = mockk<UserApi>()
coEvery { api.fetchUser("1") } returns testUser          // suspend success
coEvery { api.fetchUser("1") } throws IOException()       // suspend failure
coVerify(exactly = 1) { api.fetchUser("1") }
// Non-suspend: every { ... } returns ... / verify { ... }

## Async rule
Use `runTest { }` for coroutines; test each suspend path for success AND failure.

## Worked example (unit / JUnit5 + MockK)
class UserRepositoryTest {
    private val api = mockk<UserApi>()
    private val repo = UserRepository(api)

    @Test
    fun `returns user on success`() = runTest {
        coEvery { api.fetchUser("1") } returns testUser

        val result = repo.getUser("1")

        assertEquals(testUser, result)
        coVerify(exactly = 1) { api.fetchUser("1") }
    }

    @Test
    fun `throws RepoException when api fails`() = runTest {
        coEvery { api.fetchUser("1") } throws IOException("offline")

        assertThrows(RepoException::class.java) {
            runBlocking { repo.getUser("1") }
        }
    }
}

## Espresso idiom (instrumented UI — androidTest)
@RunWith(AndroidJUnit4::class)
class LoginScreenTest {
    @get:Rule val rule = ActivityScenarioRule(LoginActivity::class.java)

    @Test fun showsErrorOnEmptySubmit() {
        onView(withId(R.id.submit)).perform(click())
        onView(withId(R.id.error)).check(matches(isDisplayed()))
    }
}
