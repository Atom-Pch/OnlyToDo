import { expect, test } from '@playwright/test';

const USER_API = '**/api/who';
const TODO_API = '**/api/todos';

test.describe('Verify Todos page', () => {
	test('todo-list landing page', async ({ page }) => {
		await page.route(USER_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: { username: 'test' }
			});
		});

		await page.goto('/todos');
		await expect(page.locator('h1')).toHaveText('Your Tasks');
		await expect(page.getByTestId('todos-count')).toHaveText('0 Tasks');
		await expect(page.getByTestId('current-user')).toHaveText('(test)');
	});
});

test.describe('Todo page authentication & loading', () => {
	test('Unauthenticated user is redirected to login', async ({ page }) => {
		await page.route(TODO_API, async (route) => {
			await route.fulfill({
				status: 401,
				contentType: 'text/plain',
				body: 'No session found'
			});
		});
		await page.goto('/todos');
		await page.waitForURL('**/login');
	});

	test('Authenticated user sees their tasks after loading spinner', async ({ page }) => {
		await page.route(USER_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: { username: 'test' }
			});
		});
		await page.route(TODO_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: [
					{
						id: 1,
						title: 'title1',
						description: 'desc1',
						image_url: '',
						is_completed: false
					},
					{
						id: 2,
						title: 'title2',
						description: 'desc2',
						image_url: '',
						is_completed: true
					}
				]
			});
		});

		await page.goto('/todos');
		await expect(page.getByTestId('current-user')).toHaveText('(test)');
		await expect(page.getByTestId('todos-count')).toHaveText('2 Tasks');

		// Newer tasks appear first so the order is reversed
		await expect(page.locator('ul > li > button > h3')).toHaveText(['title2', 'title1']);
		await expect(page.locator('ul > li > button > p')).toHaveText(['desc2', 'desc1']);
		await expect(page.locator('ul > li')).toContainClass(['bg-emerald-700/30', 'bg-rose-700/30']);
	});

	test('Empty state shows when user has no tasks', async ({ page }) => {
		await page.route(USER_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: { username: 'test' }
			});
		});
		await page.route(TODO_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: null
			});
		});

		await page.goto('/todos');
		await expect(page.locator('h3')).toHaveText('No tasks yet');
		await expect(page.locator('p')).toHaveText('Get started by creating a new task above.');
	});
});

// test.describe('Todo creation', () => {
//     test('Create a todo with title only', async ({ page }) => {

//     });

//     test('Create a todo with title and description', async ({ page }) => {

//     });

//     test('Input fields clear after successful creation', async ({ page }) => {

//     });

//     test('New todo appears in the list immediately', async ({ page }) => {

//     });

//     test('Create a todo with an image attachment via S3 presign flow', async ({ page }) => {

//     });

//     test('Image preview renders after attaching an image', async ({ page }) => {

//     });

//     test('Error message displays when creation fails', async ({ page }) => {

//     });

//     test('Uploading state disables form during submission', async ({ page }) => {

//     });
// });

// test.describe('Todo completion toggle', () => {
//     test('Clicking a task toggles it to completed', async ({ page }) => {

//     });

//     test('Clicking a completed task toggles it back to incomplete', async ({ page }) => {

//     });

//     test('Completed task shows green styling, incomplete shows red', async ({ page }) => {

//     });

//     test('aria-pressed attribute updates on toggle', async ({ page }) => {

//     });
// });

// test.describe('Todo editing', () => {
//     test('Clicking edit reveals editable title and description fields', async ({ page }) => {

//     });

//     test('Save updates the todo title and description in the list', async ({ page }) => {

//     });

//     test('Cancel discards edits and exits edit mode', async ({ page }) => {

//     });

//     test('Saving with empty title shows validation error', async ({ page }) => {

//     });

//     test('Edit and delete buttons are hidden while in edit mode', async ({ page }) => {

//     });

//     test('Error message displays when save fails', async ({ page }) => {

//     });
// });

// test.describe('Todo deletion', () => {
//     test('Deleting a task removes it from the list', async ({ page }) => {

//     });

//     test('Task count badge decreases after deletion', async ({ page }) => {

//     });

//     test('Deleting the last task shows the empty state', async ({ page }) => {

//     });
// });

// test.describe('Todo page error handling', () => {
//     test('Fetch failure (network error) redirects to login', async ({ page }) => {

//     });

//     test('Non-401 fetch failure shows load error message', async ({ page }) => {

//     });
// });
