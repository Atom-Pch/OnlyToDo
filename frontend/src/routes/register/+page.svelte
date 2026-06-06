<script lang="ts">
	import { CircleAlert } from "@lucide/svelte";

	// State variables for your UI to bind to (adjust if you named yours differently)
	let username = $state('');
	let email = $state('');
	let password = $state('');
	let errorMessage = $state('');

	// --- REGISTRATION LOGIC ---
	async function handleRegister(event: Event) {
		if (event) event.preventDefault();
		errorMessage = '';

		try {
			const res = await fetch(`/api/register`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				// We don't strictly need credentials: 'include' for registration,
				// but it's good practice to keep the payload consistent.
				body: JSON.stringify({ username, email, password })
			});

			if (res.ok) {
				console.log('Registration successful! You can now log in.');
				// Optional: Automatically trigger handleLogin here, or redirect to a login view
				window.location.href = '/login'; // Redirect to login page after successful registration
			} else {
				const data = await res.text();
				errorMessage = `Registration failed: ${data}`;
			}
		} catch (err) {
			errorMessage = 'Network error. You\'re offline or server not running.';
			console.error(err);
		}
	}
</script>

<div class="min-h-[80vh] flex items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
	<div class="w-full max-w-md bg-gray-800 rounded-2xl shadow-2xl border border-gray-700 p-8 sm:p-10">
		<h1 class="text-3xl font-bold text-center text-white mb-8">Create Account</h1>

		{#if errorMessage}
			<div class="mb-6 bg-red-900/50 border border-red-500/50 text-red-200 px-4 py-3 rounded-lg text-sm text-center shadow-sm flex items-center justify-center gap-2">
				<CircleAlert class="w-5 h-5" />
				{errorMessage}
			</div>
		{/if}

		<form onsubmit={handleRegister} class="space-y-5">
			<div>
				<label for="email" class="block text-sm font-medium text-gray-300 mb-2">Email</label>
				<input type="email" id="email" bind:value={email} placeholder="you@example.com" required class="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition" />
			</div>

			<div>
				<label for="username" class="block text-sm font-medium text-gray-300 mb-2">Username</label>
				<input
					type="text"
					id="username"
					bind:value={username}
					placeholder="Choose a username"
					required
					class="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
				/>
			</div>

			<div>
				<label for="password" class="block text-sm font-medium text-gray-300 mb-2">Password</label>
				<input
					type="password"
					id="password"
					bind:value={password}
					placeholder="Create a password"
					required
					class="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
				/>
			</div>

			<button type="submit" class="w-full flex justify-center mt-6 py-3.5 px-4 border border-transparent rounded-xl shadow-md text-base font-medium text-white bg-gradient-to-r from-indigo-600 to-purple-600 hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 focus:ring-offset-gray-900 transition-all transform hover:-translate-y-0.5">
				Register
			</button>
		</form>
		
		<p class="mt-8 text-center text-sm text-gray-400">
			Already have an account? 
			<a href="/login" class="font-medium text-indigo-400 hover:text-indigo-300 transition hover:underline">Log in</a>
		</p>
	</div>
</div>