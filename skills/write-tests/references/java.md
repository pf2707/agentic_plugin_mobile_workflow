# Java (Android) test conventions

## Framework & placement
- Use **JUnit5** (Jupiter). Mocking: **Mockito** (`mockito-junit-jupiter`).
- Unit tests live in /app/src/test/java/...   (file: <Class>Test.java)
- Instrumented/Espresso tests live in /app/src/androidTest/java/...

## Standard imports
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

## Naming
- Method names describe behavior: `returnsUserWhenApiSucceeds()`
- Annotate the class with `@ExtendWith(MockitoExtension.class)`.

## Mocking idiom (Mockito — Java-specific, do not mix with MockK)
@Mock UserApi api;
when(api.fetchUser("1")).thenReturn(testUser);                 // success
when(api.fetchUser("1")).thenThrow(new IOException("offline")); // failure
verify(api, times(1)).fetchUser("1");

## Async rule
For callback/future APIs, assert both the success and failure outcomes (use
`ArgumentCaptor` to capture callbacks, or block on the future with a timeout).

## Worked example
@ExtendWith(MockitoExtension.class)
class UserRepositoryTest {

    @Mock UserApi api;
    UserRepository repo;

    @BeforeEach
    void setUp() {
        repo = new UserRepository(api);
    }

    @Test
    void returnsUserOnSuccess() throws Exception {
        when(api.fetchUser("1")).thenReturn(testUser);

        User result = repo.getUser("1");

        assertEquals(testUser, result);
        verify(api, times(1)).fetchUser("1");
    }

    @Test
    void throwsRepoExceptionWhenApiFails() throws Exception {
        when(api.fetchUser("1")).thenThrow(new IOException("offline"));

        assertThrows(RepoException.class, () -> repo.getUser("1"));
    }
}
