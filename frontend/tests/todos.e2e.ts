import { expect, test, type Page } from '@playwright/test';

const USER_API = '**/api/who';
const TODO_API = '**/api/todos';
const USERNAME = 'testUser'

async function mockUserLogin(page: Page) {
	await page.route(USER_API, async (route) => {
		await route.fulfill({
			status: 200,
			contentType: 'application/json',
			json: { username: `${USERNAME}` }
		});
	});
}

test.describe('Verify Todos page', () => {
	test('todo-list landing page', async ({ page }) => {
		await mockUserLogin(page);

		await page.goto('/todos');

		await expect(page.locator('h1')).toHaveText('Your Tasks');
		await expect(page.getByTestId('todos-count')).toHaveText('0 Tasks');
		await expect(page.getByTestId('current-user')).toHaveText(`(${USERNAME})`);
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
		await mockUserLogin(page);
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

		await expect(page.getByTestId('current-user')).toHaveText(`(${USERNAME})`);
		await expect(page.getByTestId('todos-count')).toHaveText('2 Tasks');

		// Newer tasks appear first so the order is reversed
		await expect(page.getByRole('heading', { level: 3 })).toHaveText(['title2', 'title1']);
		await expect(page.locator('p')).toHaveText(['desc2', 'desc1']);
		await expect(page.getByRole('listitem')).toContainClass(['bg-emerald-700/30', 'bg-rose-700/30']);
	});

	test('Empty state shows when user has no tasks', async ({ page }) => {
		await mockUserLogin(page);
		await page.route(TODO_API, async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: null
			});
		});

		await page.goto('/todos');

		await expect(page.getByTestId('current-user')).toHaveText(`(${USERNAME})`);
		await expect(page.locator('h3')).toHaveText('No tasks yet');
		await expect(page.locator('p')).toHaveText('Get started by creating a new task above.');
	});
});

test.describe('Todo creation', { tag: '@now' }, () => {
	test('Create a todo with title only', async ({ page }) => {
		await mockUserLogin(page);
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				await route.fulfill({
					status: 201,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'todoTitle',
						description: '',
						image_url: ''
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('todoTitle');
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.getByTestId('current-user')).toHaveText('(${USERNAME})');
		await expect(page.getByTestId('todos-count')).toHaveText('1 Task');
		await expect(page.getByRole('heading', { level: 3 })).toHaveText('todoTitle');
		await expect(page.getByRole('listitem')).toContainClass('bg-rose-700/30');
	});

	test('Create a todo with title and description', async ({ page }) => {
		await mockUserLogin(page);
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				await route.fulfill({
					status: 201,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'todoTitle',
						description: 'todoDesc',
						image_url: ''
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('todoTitle');
		await page.getByLabel('description').fill('todoDesc');
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.getByTestId('current-user')).toHaveText(`(${USERNAME})`);
		await expect(page.getByTestId('todos-count')).toHaveText('1 Task');
		await expect(page.getByRole('heading', { level: 3 })).toHaveText('todoTitle');
		await expect(page.locator('p')).toHaveText('todoDesc');
		await expect(page.getByRole('listitem')).toContainClass('bg-rose-700/30');
	});

	test('Input fields clear after successful creation', async ({ page }) => {
		await mockUserLogin(page);
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				await route.fulfill({
					status: 201,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'todoTitle',
						description: 'todoDesc',
						image_url: ''
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('todoTitle');
		await page.getByLabel('description').fill('todoDesc');
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.getByTestId('current-user')).toHaveText('(${USERNAME})');
		await expect(page.getByTestId('todos-count')).toHaveText('1 Task');
		await expect(page.getByRole('heading', { level: 3 })).toHaveText('todoTitle');
		await expect(page.locator('p')).toHaveText('todoDesc');
		await expect(page.getByRole('listitem')).toContainClass('bg-rose-700/30');
		await expect(page.getByLabel('title')).toBeEmpty();
		await expect(page.getByLabel('description')).toBeEmpty();
	});

	test('Create a todo with an image attachment via S3 presign flow', async ({ page }) => {
		await mockUserLogin(page);

		const UPLOAD_URL = 'https://s3bucketname.s3.us-east-2.amazonaws.com/upload-target';
		const IMAGE_URL = 'https://s3bucketname.s3.us-east-2.amazonaws.com/test-image.jpg';

		// 1. Presign endpoint
		await page.route('**/api/todos/s3-presign?filename=**', async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: {
					upload_url: UPLOAD_URL,
					image_url: IMAGE_URL
				}
			});
		});

		// 2. S3 PUT
		await page.route(UPLOAD_URL, async (route) => {
			expect(route.request().method()).toBe('PUT');
			await route.fulfill({ status: 200 });
		});

		// 3. Create-todo POST + initial GET
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				await route.fulfill({
					status: 201,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'todoTitle',
						description: 'todoDesc',
						image_url: IMAGE_URL
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('todoTitle');
		await page.getByLabel('description').fill('todoDesc');
		await page.locator('input[type="file"]').setInputFiles('./tests/assets/img01.jpg');
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.getByTestId('current-user')).toHaveText('(${USERNAME})');
		await expect(page.getByTestId('todos-count')).toHaveText('1 Task');
		await expect(page.getByRole('heading', { level: 3 })).toHaveText('todoTitle');
		await expect(page.locator('p')).toHaveText('todoDesc');
		await expect(page.getByRole('listitem')).toContainClass('bg-rose-700/30');
		await expect(page.getByRole('img')).toHaveAttribute('src', IMAGE_URL);
	});

	test('Error message displays when creation fails', async ({ page }) => {
		await mockUserLogin(page);
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				await route.fulfill({
					status: 500,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'a'.repeat(101),
						description: '',
						image_url: ''
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('a'.repeat(101));
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.locator('#error-message', { hasText: 'Failed to create To-Do.'} )).toBeVisible();
	});

	test.only('Uploading state disables form during submission', async ({ page }) => {
		await mockUserLogin(page);

		const UPLOAD_URL = 'https://s3bucketname.s3.us-east-2.amazonaws.com/upload-target';
		const IMAGE_URL = 'https://s3bucketname.s3.us-east-2.amazonaws.com/test-image.jpg';

		// 1. Presign endpoint
		await page.route('**/api/todos/s3-presign?filename=**', async (route) => {
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				json: {
					upload_url: UPLOAD_URL,
					image_url: IMAGE_URL
				}
			});
		});

		// 2. S3 PUT
		await page.route(UPLOAD_URL, async (route) => {
			expect(route.request().method()).toBe('PUT');
			await route.fulfill({ status: 200 });
		});

		// 3. Create-todo POST + initial GET
		await page.route(TODO_API, async (route) => {
			if (route.request().method() === 'POST') {
				// Mock loading
				await new Promise(resolve => setTimeout(resolve, 2000));
				await route.fulfill({
					status: 201,
					contentType: 'application/json',
					json: {
						id: 1,
						title: 'todoTitle',
						description: '',
						image_url: IMAGE_URL
					}
				});
			} else if (route.request().method() === 'GET') {
				await route.fulfill({
					status: 200,
					contentType: 'application/json',
					json: null
				});
			} else {
				await route.abort()
			}
		});

		await page.goto('/todos');
		await page.getByLabel('title').fill('todoTitle');
		await page.locator('input[type="file"]').setInputFiles('./tests/assets/img01.jpg');
		await page.getByRole('button', { name: 'Add Task' }).click();

		await expect(page.getByRole('button', { name: 'Adding...' })).toBeDisabled();
		await expect(page.getByRole('button', { name: 'Add task' })).toBeEnabled();
	});
});

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
