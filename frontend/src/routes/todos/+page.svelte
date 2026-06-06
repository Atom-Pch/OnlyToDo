<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let todos = $state<any[]>([]);
	let newTitle = $state('');
	let newDescription = $state('');
	let error = $state('');
	let imageFile = $state(<FileList | null>null);
	let isUploading = $state(false);
	let isLoading = $state(true);

	// Fetch the To-Dos as soon as the page loads
	onMount(async () => {
		await fetchTodos();
	});

	async function fetchTodos() {
		try {
			const res = await fetch(`/api/todos`, {
				credentials: 'include'
			});

			if (res.status === 401) {
				goto('/login');
				return;
			}
			if (res.ok) {
				todos = (await res.json()) || [];
			} else {
				error = 'Failed to load To-Dos from the server.';
			}
		} catch (err) {
			goto('/login');
			error = 'Could not connect to the API. Is the Go backend running?';
			console.error(err);
		} finally {
			// NEW: Unblock the UI whether it succeeded or failed
			isLoading = false;
		}
	}

	async function addTodo(event: Event) {
		event.preventDefault(); // Prevent the form from refreshing the page
		error = '';
		isUploading = true;
		let finalImageUrl = '';

		try {
			// 1. If an image is selected, handle the S3 upload first
			if (imageFile && imageFile.length > 0) {
				const file = imageFile[0];

				// Get the presigned URL from Go
				const presignRes = await fetch(
					`/api/todos/s3-presign?filename=${encodeURIComponent(file.name)}`,
					{
						credentials: 'include'
					}
				);
				const presignData = await presignRes.json();

				// Upload the file directly to AWS S3
				const uploadRes = await fetch(presignData.upload_url, {
					method: 'PUT',
					body: file,
					headers: {
						'Content-Type': file.type
					}
				});

				if (!uploadRes.ok) throw new Error('Failed to upload image to S3');
				finalImageUrl = presignData.image_url;
			}

			// 2. Save the To-Do item to the Go backend
			const res = await fetch(`/api/todos`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				credentials: 'include',
				body: JSON.stringify({
					title: newTitle,
					description: newDescription,
					image_url: finalImageUrl // Send the S3 URL to your DB
				})
			});

			if (res.ok) {
				const newTodo = await res.json();
				todos = [...todos, newTodo];
				newTitle = '';
				newDescription = '';
				imageFile = null; // Clear the file input
			} else {
				error = 'Failed to create To-Do.';
			}
		} catch (err) {
			console.error('Error creating To-Do:', err);
		} finally {
			isUploading = false;
		}
	}

	async function toggleTodo(todo: any) {
		const newState = !todo.is_completed;
		try {
			const res = await fetch(`/api/todos/${todo.id}`, {
				method: 'PATCH',
				headers: { 'Content-Type': 'application/json' },
				credentials: 'include',
				body: JSON.stringify({ is_completed: newState })
			});

			if (res.ok) {
				// Flip the completion state in the UI
				todos = todos.map((t) => (t.id === todo.id ? { ...t, is_completed: newState } : t));
			} else {
				console.error('Failed to update task');
			}
		} catch (err) {
			console.error('Could not connect to the API to update the To-Do.', err);
		}
	}

	async function deleteTodo(id: number) {
		try {
			const res = await fetch(`/api/todos/${id}`, {
				method: 'DELETE',
				credentials: 'include' // Must send the cookie!
			});

			if (res.ok) {
				// Instantly remove the deleted item from the UI
				todos = todos.filter((todo) => todo.id !== id);
			} else {
				console.error('Failed to delete task');
			}
		} catch (err) {
			console.error('Could not connect to the API to delete the To-Do.', err);
		}
	}
</script>

<main class="mx-auto w-full max-w-3xl px-4 pt-8 pb-24 sm:px-6 sm:pt-12">
	{#if isLoading}
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
			<p class="font-medium text-gray-400">Authenticating...</p>
		</div>
	{:else}
		<div class="mb-8 flex items-center justify-between">
			<h1 class="text-3xl font-bold tracking-tight text-white sm:text-4xl">Your Tasks</h1>
			<span
				class="rounded-full border border-gray-700 bg-gray-800 px-4 py-1.5 text-sm font-semibold text-indigo-400 shadow-sm"
			>
				{todos.length}
				{todos.length === 1 ? 'Task' : 'Tasks'}
			</span>
		</div>

		{#if error}
			<div
				class="mb-8 flex items-center rounded-xl border border-red-500/50 bg-red-900/50 p-4 text-red-200 shadow-sm"
			>
				<svg
					class="mr-3 h-6 w-6 flex-shrink-0"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
					><path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
					></path></svg
				>
				<p class="text-sm font-medium">{error}</p>
			</div>
		{/if}

		<div
			class="mb-10 rounded-2xl border border-gray-700 bg-gray-800 p-5 shadow-lg transition-all focus-within:ring-2 focus-within:ring-indigo-500 sm:p-6"
		>
			<form onsubmit={addTodo} class="flex flex-col gap-4 sm:flex-row">
				<div class="flex flex-1 flex-col gap-3">
					<input
						type="text"
						placeholder="What needs to be done?"
						bind:value={newTitle}
						required
						class="w-full border-b-2 border-gray-600 bg-transparent px-2 py-2 text-lg text-white placeholder-gray-500 transition focus:border-indigo-500 focus:outline-none"
					/>
					<input
						type="text"
						placeholder="Add description (Optional)"
						bind:value={newDescription}
						class="w-full border-b border-gray-700 bg-transparent px-2 py-1 text-sm text-gray-400 placeholder-gray-600 transition focus:border-indigo-500 focus:outline-none"
					/>
				</div>

				<div
					class="mt-3 flex flex-shrink-0 flex-row items-center justify-between gap-3 sm:mt-0 sm:w-44 sm:flex-col sm:items-stretch"
				>
					<label
						class="flex w-full flex-1 cursor-pointer items-center justify-center truncate rounded-xl border border-gray-600 px-3 py-2.5 text-center text-xs font-medium text-gray-300 transition hover:bg-gray-700 hover:text-white"
					>
						<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
							></path></svg
						>
						{imageFile && imageFile.length > 0 ? imageFile[0].name : 'Attach Image'}
						<input type="file" accept="image/*" bind:files={imageFile} class="hidden" />
					</label>

					<button
						type="submit"
						disabled={isUploading}
						class="flex flex-1 transform items-center justify-center rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-md transition hover:-translate-y-0.5 hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50 sm:flex-none"
					>
						{#if isUploading}
							<svg
								class="mr-2 -ml-1 h-4 w-4 animate-spin text-white"
								fill="none"
								viewBox="0 0 24 24"
								><circle
									class="opacity-25"
									cx="12"
									cy="12"
									r="10"
									stroke="currentColor"
									stroke-width="4"
								></circle><path
									class="opacity-75"
									fill="currentColor"
									d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
								></path></svg
							>
							Adding...
						{:else}
							Add Task
						{/if}
					</button>
				</div>
			</form>
		</div>

		<ul class="space-y-4">
			{#each todos.toReversed() as todo}
				<li
					class={'group flex cursor-pointer flex-col justify-between gap-4 rounded-2xl border p-5 shadow-md transition sm:flex-row sm:items-start sm:p-6 ' +
						(todo.is_completed
							? 'border-green-600 bg-green-900/40 hover:border-green-500'
							: 'border-red-600 bg-red-900/30 hover:border-red-500')}
				>
					<div
						class="min-w-0 flex-1"
						role="button"
						tabindex="0"
						onclick={() => toggleTodo(todo)}
						onkeydown={(e) => {
							if (e.key === 'Enter' || e.key === ' ') {
								e.preventDefault();
								toggleTodo(todo);
							}
						}}
					>
						<h3 class="text-xl font-semibold break-words text-gray-100">{todo.title}</h3>
						{#if todo.description}
							<p class="text-md mt-2 leading-relaxed break-words whitespace-pre-wrap text-gray-400">
								{todo.description}
							</p>
						{/if}
						{#if todo.image_url}
							<div
								class="mt-4 inline-block max-w-full overflow-hidden rounded-xl border border-gray-700"
							>
								<img
									src={todo.image_url}
									alt="Task attachment"
									class="max-h-64 w-auto object-cover object-center shadow-sm sm:max-h-80"
								/>
							</div>
						{/if}
					</div>

					<div
						class="flex flex-shrink-0 items-center justify-end transition-opacity group-hover:opacity-100 sm:flex-col sm:justify-start sm:opacity-0"
					>
						<button
							class="rounded-lg p-2 text-red-400 transition hover:bg-red-900/30 hover:text-red-300"
							onclick={(e) => {
								e.stopPropagation();
								deleteTodo(todo.id);
							}}
							aria-label="Delete task"
							title="Delete"
						>
							<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"
								><path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
								></path></svg
							>
						</button>
					</div>
				</li>
			{/each}
			{#if todos.length === 0 && !error}
				<div
					class="rounded-2xl border border-dashed border-gray-700 bg-gray-800/40 px-4 py-16 text-center"
				>
					<svg
						class="mx-auto mb-4 h-12 w-12 text-gray-600"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
						></path></svg
					>
					<h3 class="text-lg font-medium text-gray-300">No tasks yet</h3>
					<p class="mt-1 text-sm text-gray-500">Get started by creating a new task above.</p>
				</div>
			{/if}
		</ul>
	{/if}
</main>
