import { expect, test } from '@playwright/test';

const REGISTER_API = '**/api/register';

test.describe('Verify Registration page', () => {
    test('Clicking register button navigates to register page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Create Account' }).click();
        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });

    test('Clicking navigation bar register button navigates to register page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Register' }).click();
        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });
});

test.describe('Register form - successful registration', () => {
    test('valid details redirect to /login', async ({ page }) => {
        await page.route(REGISTER_API, async (route) => {
            await route.fulfill({
                status: 201,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'User registered successfully' })
            });
        });

        await page.goto('/register');
        await page.locator('#email').fill('newuser@example.com');
        await page.locator('#username').fill('newuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();

        await page.waitForURL('**/login');
    });
});

test.describe('Register form - failed registration', () => {
    test('duplicate username/email shows "Failed to create user" error and stays on /register', async ({
        page
    }) => {
        await page.route(REGISTER_API, async (route) => {
            await route.fulfill({
                status: 500,
                contentType: 'text/plain',
                body: 'Failed to create user\n'
            });
        });

        await page.goto('/register');
        await page.locator('#email').fill('existing@example.com');
        await page.locator('#username').fill('existinguser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.getByText('Registration failed: Failed to create user')).toBeVisible();
        await expect(page).toHaveURL(/\/register$/);
    });

    test('hashing failure shows "Failed to hash password" error', async ({ page }) => {
        await page.route(REGISTER_API, async (route) => {
            await route.fulfill({
                status: 500,
                contentType: 'text/plain',
                body: 'Failed to hash password\n'
            });
        });

        await page.goto('/register');
        await page.locator('#email').fill('newuser@example.com');
        await page.locator('#username').fill('newuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.getByText('Registration failed: Failed to hash password')).toBeVisible();
    });

    test('unreachable server shows a network error message', async ({ page }) => {
        await page.route(REGISTER_API, async (route) => {
            await route.abort('failed');
        });

        await page.goto('/register');
        await page.locator('#email').fill('newuser@example.com');
        await page.locator('#username').fill('newuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.getByText("Network error. You're offline or server not running.")).toBeVisible();
    });
});

test.describe('Register form - client-side validation and edge cases', () => {
    test('does not call the API when all fields are empty', async ({ page }) => {
        let apiWasCalled = false;
        await page.route(REGISTER_API, async (route) => {
            apiWasCalled = true;
            await route.continue();
        });

        await page.goto('/register');
        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.locator('#email')).toHaveJSProperty('validity.valid', false);
        await expect(page.locator('#username')).toHaveJSProperty('validity.valid', false);
        await expect(page.locator('#password')).toHaveJSProperty('validity.valid', false);
        expect(apiWasCalled).toBe(false);
        await expect(page).toHaveURL(/\/register$/);
    });

    test('does not call the API when the email format is invalid', async ({ page }) => {
        let apiWasCalled = false;
        await page.route(REGISTER_API, async (route) => {
            apiWasCalled = true;
            await route.continue();
        });

        await page.goto('/register');
        await page.locator('#email').fill('not-an-email');
        await page.locator('#username').fill('newuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.locator('#email')).toHaveJSProperty('validity.valid', false);
        expect(apiWasCalled).toBe(false);
    });

    test('clears the previous error message when resubmitting', async ({ page }) => {
        let callCount = 0;
        await page.route(REGISTER_API, async (route) => {
            callCount += 1;
            if (callCount === 1) {
                await route.fulfill({
                    status: 500,
                    contentType: 'text/plain',
                    body: 'Failed to create user\n'
                });
            } else {
                await route.fulfill({
                    status: 201,
                    contentType: 'application/json',
                    body: JSON.stringify({ message: 'User registered successfully' })
                });
            }
        });

        await page.goto('/register');
        await page.locator('#email').fill('newuser@example.com');
        await page.locator('#username').fill('newuser');
        await page.locator('#password').fill('correct-password');
        await page.getByRole('button', { name: 'Register' }).click();
        await expect(page.getByText('Registration failed: Failed to create user')).toBeVisible();

        await page.getByRole('button', { name: 'Register' }).click();

        await expect(page.getByText('Registration failed: Failed to create user')).toBeHidden();
        await page.waitForURL('**/login');
    });

    test('sends whitespace and long input values exactly as typed', async ({ page }) => {
        const email = 'spaced.user@example.com';
        const username = '  spaced-user  ';
        const password = 'p'.repeat(256);
        let receivedPayload: { username?: string; email?: string; password?: string } | null = null;

        await page.route(REGISTER_API, async (route) => {
            receivedPayload = route.request().postDataJSON();
            await route.fulfill({
                status: 201,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'User registered successfully' })
            });
        });

        await page.goto('/register');
        await page.locator('#email').fill(email);
        await page.locator('#username').fill(username);
        await page.locator('#password').fill(password);
        await page.getByRole('button', { name: 'Register' }).click();

        await page.waitForURL('**/login');
        expect(receivedPayload).toEqual({ username, email, password });
    });
});
