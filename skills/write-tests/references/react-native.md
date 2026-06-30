# React Native test conventions

## Framework & placement
- Use **Jest** + **React Testing Library** (`@testing-library/react-native`).
- Mocking: `jest.mock` / `jest.fn`. Use `@testing-library/jest-native` matchers.
- Tests live in __tests__/ next to source, or <Source>.test.tsx alongside the file.

## Standard imports
import { render, screen, fireEvent, waitFor } from '@testing-library/react-native';
import { UserRepository } from '../UserRepository';

## Naming
- `describe()` per unit; `it()` describes behavior:
  it('returns cached user when network is offline', ...) — not 'test getUser'

## Mocking idiom (jest — RN-specific, do not mix with other frameworks)
const fetchUser = jest.fn();
jest.mock('../api', () => ({ fetchUser: (...a) => fetchUser(...a) }));

fetchUser.mockResolvedValue(testUser);                 // async success
fetchUser.mockRejectedValue(new Error('offline'));     // async failure
expect(fetchUser).toHaveBeenCalledWith('1');

## Async rule
Use `async/await` with `waitFor`; test every async path for success AND failure.

## Worked example — logic (UserRepository)
describe('UserRepository', () => {
  const api = { fetchUser: jest.fn() };
  const repo = new UserRepository(api);

  afterEach(() => jest.clearAllMocks());

  it('returns user on success', async () => {
    api.fetchUser.mockResolvedValue(testUser);

    const result = await repo.getUser('1');

    expect(result).toEqual(testUser);
    expect(api.fetchUser).toHaveBeenCalledWith('1');
  });

  it('throws RepoError when api fails', async () => {
    api.fetchUser.mockRejectedValue(new Error('offline'));

    await expect(repo.getUser('1')).rejects.toThrow(RepoError);
  });
});

## Worked example — component (RTL)
describe('<LoginScreen />', () => {
  it('shows an error when submitting empty form', () => {
    render(<LoginScreen />);

    fireEvent.press(screen.getByText('Submit'));

    expect(screen.getByText('Email is required')).toBeOnTheScreen();
  });
});
