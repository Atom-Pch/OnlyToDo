import { expect, test } from '@playwright/test';

test.describe('Verify landing page', () => {
	test('Homepage heading', async ({ page }) => {
		await page.goto('/');

		await expect(page.locator('h1')).toContainText('Welcome to my To-Do App!');
	});

	test('Login buttons', async ({ page }) => {
		await page.goto('/');

		await expect(page.getByRole('link', { name: 'Log In to Continue' })).toBeVisible();
		await expect(page.getByRole('link', { name: 'Login' })).toBeVisible();
	});

	test('Register buttons', async ({ page }) => {
		await page.goto('/');

		await expect(page.getByRole('link', { name: 'Create Account' })).toBeVisible();
		await expect(page.getByRole('link', { name: 'Register' })).toBeVisible();
	});
});
