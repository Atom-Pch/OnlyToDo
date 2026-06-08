import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vitest/config';
import type { ESBuildOptions } from 'vite';
import { playwright } from '@vitest/browser-playwright';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	esbuild: {
		drop: ['console', 'debugger']
	} as ESBuildOptions,
	test: {
		expect: { requireAssertions: true },
		projects: [
			{
				extends: './vite.config.ts',
				test: {
					name: 'client',
					browser: {
						enabled: true,
						provider: playwright(),
						instances: [{ browser: 'chromium', headless: true }]
					},
					include: ['src/**/*.svelte.{test,spec}.{js,ts}'],
					exclude: ['src/lib/server/**']
				}
			},

			{
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	},
	server: {
		proxy: {
			// Replicates your AWS ALB path-based routing locally
			'/api': {
				target: 'http://localhost:8080', // Replace with your local backend port
				changeOrigin: true
				// rewrite: (path) => path.replace(/^\/api/, '') // Optional: Use if backend doesn't expect /api prefix
			}
		}
	}
});
