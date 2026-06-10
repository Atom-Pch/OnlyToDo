import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
	webServer: {
		command: 'npm run build && npm run preview',
		url: 'http://localhost:4173',
		reuseExistingServer: !process.env.CI
	},
	testDir: './tests',
	testMatch: '**/*.e2e.{ts,js}',
	projects: [
		{
			name: 'chromium',
			use: { ...devices['Desktop Chrome'] }
		},
		{
			name: 'firefox',
			use: { ...devices['Desktop Firefox'] }
		},
		{
			name: 'webkit',
			use: { ...devices['Desktop Safari'] }
		}
	],
	use: {
		// launchOptions: {
		// 	slowMo: 1000
		// },
		baseURL: 'http://localhost:4173'
	}
});
