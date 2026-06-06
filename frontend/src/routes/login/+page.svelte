<script lang="ts">
	import { CircleAlert } from '@lucide/svelte';

	let username = $state('');
	let password = $state('');
	let errorMessage = $state('');

	async function handleLogin(event: Event) {
		if (event) event.preventDefault();
		errorMessage = '';

		try {
			const res = await fetch(`/api/login`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				// CRITICAL DEVOPS DETAIL: This tells the browser to accept the Set-Cookie header
				// from the Go backend and store the session token securely.
				credentials: 'include',
				body: JSON.stringify({ username, password })
			});

			if (res.ok) {
				console.log('Login successful! Cookie saved.');
				// TODO: Redirect the user to the To-Do dashboard
				window.location.href = '/todos';
			} else {
				errorMessage = 'Invalid username or password';
			}
		} catch (err) {
			errorMessage = "Network error. You're offline or server not running";
			console.error(err);
		}
	}
</script>

<div class="flex min-h-[80vh] items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
	<div
		class="w-full max-w-md rounded-2xl border border-gray-700 bg-gray-800 p-8 shadow-2xl sm:p-10"
	>
		<h1 class="mb-8 text-center text-3xl font-bold text-white">Welcome Back</h1>

		{#if errorMessage}
			<div
				class="mb-6 flex items-center justify-center gap-2 rounded-lg border border-red-500/50 bg-red-900/50 px-4 py-3 text-center text-sm text-red-200 shadow-sm"
			>
				<CircleAlert class="h-5 w-5" />
				{errorMessage}
			</div>
		{/if}

		<form onsubmit={handleLogin} class="space-y-6">
			<div>
				<label for="username" class="mb-2 block text-sm font-medium text-gray-300">Username</label>
				<input
					type="text"
					id="username"
					bind:value={username}
					placeholder="Enter your username"
					required
					class="w-full rounded-xl border border-gray-700 bg-gray-900 px-4 py-3 text-white placeholder-gray-500 transition focus:border-transparent focus:ring-2 focus:ring-indigo-500 focus:outline-none"
				/>
			</div>

			<div>
				<label for="password" class="mb-2 block text-sm font-medium text-gray-300">Password</label>
				<input
					type="password"
					id="password"
					bind:value={password}
					placeholder="Enter your password"
					required
					class="w-full rounded-xl border border-gray-700 bg-gray-900 px-4 py-3 text-white placeholder-gray-500 transition focus:border-transparent focus:ring-2 focus:ring-indigo-500 focus:outline-none"
				/>
			</div>

			<button
				type="submit"
				class="flex w-full transform justify-center rounded-xl border border-transparent bg-gradient-to-r from-indigo-600 to-purple-600 px-4 py-3.5 text-base font-medium text-white shadow-md transition-all hover:-translate-y-0.5 hover:opacity-90 focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 focus:ring-offset-gray-900 focus:outline-none"
			>
				Log in
			</button>
		</form>

		<p class="mt-8 text-center text-sm text-gray-400">
			Don't have an account?
			<a
				href="/register"
				class="font-medium text-indigo-400 transition hover:text-indigo-300 hover:underline"
				>Register here</a
			>
		</p>
	</div>
</div>
