import { expect, test } from '@playwright/test';

const LOGIN_API = '**/api/login';

test.describe('Verify login page', () => {
    test('Clicking login button navigates to login page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Log In to Continue' }).click();
        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });

    test('Clicking navigation bar login button navigates to login page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Login' }).click();
        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });
});

test.describe('Successful login', () => {
    test('valid credentials redirect to /todos', async ({ page }) => {
        await page.route(LOGIN_API, async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'Logged in successfully' })
            });
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await page.waitForURL('**/todos');
    });

    test('successful login stores the session cookie returned by the server', async ({
        page,
        context
    }) => {
        await page.route(LOGIN_API, async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                headers: { 'set-cookie': 'session_token=mock-session-value; Path=/; HttpOnly; SameSite=Lax' },
                body: JSON.stringify({ message: 'Logged in successfully' })
            });
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await page.waitForURL('**/todos');
        const cookies = await context.cookies();
        expect(cookies.some((cookie) => cookie.name === 'session_token')).toBe(true);
    });
});

test.describe('Failed login', () => {
    test('invalid credentials show an error message and stay on /login', async ({ page }) => {
        await page.route(LOGIN_API, async (route) => {
            await route.fulfill({
                status: 401,
                contentType: 'application/json',
                body: JSON.stringify({ error: 'Invalid credentials' })
            });
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('wrong-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.getByText('Invalid username or password')).toBeVisible();
        await expect(page).toHaveURL(/\/login$/);
    });

    test('unreachable server shows a network error message', async ({ page }) => {
        await page.route(LOGIN_API, async (route) => {
            await route.abort('failed');
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.getByText("Network error. You're offline or server not running")).toBeVisible();
    });

    test('unexpected server error falls back to the generic invalid credentials message', async ({
        page
    }) => {
        await page.route(LOGIN_API, async (route) => {
            await route.fulfill({
                status: 500,
                contentType: 'application/json',
                body: JSON.stringify({ error: 'internal server error' })
            });
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.getByText('Invalid username or password')).toBeVisible();
        await expect(page).toHaveURL(/\/login$/);
    });
});

test.describe('Client-side validation and edge cases', () => {
    test('does not call the API when username and password are empty', async ({ page }) => {
        let apiWasCalled = false;
        await page.route(LOGIN_API, async (route) => {
            apiWasCalled = true;
            await route.continue();
        });

        await page.goto('/login');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.locator('#username')).toHaveJSProperty('validity.valid', false);
        expect(apiWasCalled).toBe(false);
        await expect(page).toHaveURL(/\/login$/);
    });

    test('does not call the API when password is missing', async ({ page }) => {
        let apiWasCalled = false;
        await page.route(LOGIN_API, async (route) => {
            apiWasCalled = true;
            await route.continue();
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.locator('#password')).toHaveJSProperty('validity.valid', false);
        expect(apiWasCalled).toBe(false);
    });

    test('clears the previous error message when resubmitting', async ({ page }) => {
        let callCount = 0;
        await page.route(LOGIN_API, async (route) => {
            callCount += 1;
            if (callCount === 1) {
                await route.fulfill({
                    status: 401,
                    contentType: 'application/json',
                    body: JSON.stringify({ error: 'Invalid credentials' })
                });
            } else {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({ message: 'Logged in successfully' })
                });
            }
        });

        await page.goto('/login');
        await page.locator('#username').fill('validuser');
        await page.locator('#password').fill('wrong-password');
        await page.getByRole('button', { name: 'Log in' }).click();
        await expect(page.getByText('Invalid username or password')).toBeVisible();

        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Log in' }).click();

        await expect(page.getByText('Invalid username or password')).toBeHidden();
        await page.waitForURL('**/todos');
    });

    test('sends whitespace and long input values exactly as typed', async ({ page }) => {
        const username = '  spaced-user  ';
        const password = 'p'.repeat(256);
        let receivedPayload: { username?: string; password?: string } | null = null;

        await page.route(LOGIN_API, async (route) => {
            receivedPayload = route.request().postDataJSON();
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'Logged in successfully' })
            });
        });

        await page.goto('/login');
        await page.locator('#username').fill(username);
        await page.locator('#password').fill(password);
        await page.getByRole('button', { name: 'Log in' }).click();

        await page.waitForURL('**/todos');
        expect(receivedPayload).toEqual({ username, password });
    });
});
