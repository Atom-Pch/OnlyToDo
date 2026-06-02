<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/temp_logo.png';
	import { onMount } from 'svelte';

	let { children } = $props();

	let currentUser: string | null = $state(null);
	// NEW: Add the loading state, default to true so it blocks the UI immediately
	let isCheckingAuth = $state(true);

	async function handleLogout() {
		try {
			await fetch(`/api/logout`, {
				method: 'POST',
				credentials: 'include'
			});
			console.log('Logged out successfully.');
			window.location.href = '/';
		} catch (err) {
			console.error('Failed to log out', err);
		}
	}

	onMount(async () => {
		// As soon as the app loads, check if we are logged in
		await checkSession();
	});

	// --- CHECK WHO IS LOGGED IN ---
	async function checkSession() {
		try {
			const res = await fetch(`/api/who`, { credentials: 'include' });
			if (res.ok) {
				const data = await res.json();
				currentUser = data.username;
			} else {
				currentUser = null;
				if (res.status === 404 || res.status === 401) {
					await fetch(`/api/logout`, { method: 'POST', credentials: 'include' });
				}
			}
		} catch (err) {
			console.error('Auth check failed (offline or backend down?):', err);
			currentUser = null;
		} finally {
			// NEW: Unblock the UI whether the check succeeded or failed
			isCheckingAuth = false;
		}
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>To-Do App</title>
</svelte:head>

<div
	class="flex min-h-screen flex-col bg-gray-900 font-sans text-gray-100 selection:bg-indigo-500/30"
>
	<nav class="sticky top-0 z-50 border-b border-gray-700 bg-gray-800 px-4 py-4 shadow-md sm:px-8">
		<div class="mx-auto flex max-w-7xl items-center justify-between">
			<div class="flex items-center">
				<a
					href="/"
					class="bg-gradient-to-r from-indigo-400 to-purple-500 bg-clip-text text-xl font-bold text-transparent transition hover:opacity-80"
				>
					To-Do App
				</a>
			</div>

			<div class="flex items-center space-x-4 sm:space-x-6">
				{#if currentUser}
					<form onsubmit={handleLogout} class="m-0">
						<button
							type="submit"
							class="rounded-lg bg-gray-700/50 px-4 py-2 text-sm font-medium text-gray-300 transition hover:bg-gray-600 hover:text-white"
						>
							Logout <span class="opacity-60">({currentUser})</span>
						</button>
					</form>
				{:else}
					<a
						href="/register"
						class="hidden text-sm font-medium text-gray-300 transition hover:text-white sm:inline"
						>Register</a
					>
					<a
						href="/login"
						class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-500"
					>
						Login
					</a>
				{/if}
			</div>
		</div>
	</nav>

	<div class="w-full flex-grow">
		{#if isCheckingAuth}
			<div class="flex min-h-[60vh] flex-col items-center justify-center gap-4">
				<svg class="h-10 w-10 animate-spin text-indigo-500" fill="none" viewBox="0 0 24 24">
					<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"
					></circle>
					<path
						class="opacity-75"
						fill="currentColor"
						d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
					></path>
				</svg>
				<p class="font-medium text-gray-400">Connecting...</p>
			</div>
		{:else}
			{@render children()}
		{/if}
	</div>
</div>

<style>
	:global(body) {
		background-color: #111827;
		margin: 0;
	}
</style>
