<script lang="ts">
	import { goto } from '$app/navigation';
	import { ListPlus, Trash2, Upload, CircleAlert, SquarePen } from '@lucide/svelte';
	import { onMount } from 'svelte';

	let todos = $state<any[]>([]);
	let newTitle = $state('');
	let newDescription = $state('');
	let error = $state('');
	let imageFile = $state(<FileList | null>null);
	let isUploading = $state(false);
	let isLoading = $state(true);
	let editingId = $state<number | null>(null);
	let editTitle = $state('');
	let editDescription = $state('');

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

	function startEdit(todo: any) {
		editingId = todo.id;
		editTitle = todo.title;
		editDescription = todo.description ?? '';
	}

	function cancelEdit() {
		editingId = null;
	}

	async function saveEdit(todo: any) {
		const title = editTitle.trim();
		if (!title) {
			error = 'Title cannot be empty.';
			return;
		}
		try {
			const res = await fetch(`/api/todos/${todo.id}`, {
				method: 'PATCH',
				headers: { 'Content-Type': 'application/json' },
				credentials: 'include',
				body: JSON.stringify({ title, description: editDescription })
			});

			if (res.ok) {
				todos = todos.map((t) =>
					t.id === todo.id ? { ...t, title, description: editDescription } : t
				);
				editingId = null;
				error = '';
			} else {
				error = 'Failed to update task.';
			}
		} catch (err) {
			console.error('Could not connect to the API to update the To-Do.', err);
			error = 'Could not connect to the API to update the To-Do.';
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
				data-testid="todos-count"
			>
				{todos.length}
				{todos.length === 1 ? 'Task' : 'Tasks'}
			</span>
		</div>

		{#if error}
			<div
				class="mb-8 flex items-center rounded-xl border border-red-500/50 bg-red-900/50 p-4 text-red-200 shadow-sm"
			>
				<CircleAlert class="mr-3 h-6 w-6 flex-shrink-0" />
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
						<Upload class="mr-1 h-4 w-4" />
						{imageFile && imageFile.length > 0 ? imageFile[0].name : 'Attach Image'}
						<input type="file" accept="image/*" bind:files={imageFile} class="hidden" />
					</label>

					<button
						type="submit"
						disabled={isUploading}
						class="flex flex-1 transform cursor-pointer items-center justify-center rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-md transition hover:-translate-y-0.5 hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50 sm:flex-none"
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
					class={'group flex flex-col justify-between gap-4 rounded-2xl border p-5 shadow-md transition sm:flex-row sm:items-start sm:p-6 ' +
						(todo.is_completed
							? 'border-emerald-500 bg-emerald-700/30 hover:bg-emerald-600/30'
							: 'border-rose-500 bg-rose-700/30 hover:bg-rose-600/30')}
				>
					{#if editingId === todo.id}
						<div class="min-w-0 flex-1">
							<input
								type="text"
								bind:value={editTitle}
								class="w-full border-b-2 border-gray-600 bg-transparent px-2 py-2 text-lg text-white placeholder-gray-500 transition focus:border-indigo-500 focus:outline-none"
								placeholder="Title"
							/>
							<textarea
								bind:value={editDescription}
								rows="2"
								class="text-md mt-2 w-full resize-none border-b border-gray-700 bg-transparent px-2 py-1 text-gray-300 placeholder-gray-600 transition focus:border-indigo-500 focus:outline-none"
								placeholder="Add description (Optional)"
							></textarea>
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
							<div class="mt-3 flex gap-2">
								<button
									onclick={() => saveEdit(todo)}
									class="cursor-pointer rounded-lg bg-indigo-600 px-4 py-1.5 text-sm font-semibold text-white transition hover:bg-indigo-500"
								>
									Save
								</button>
								<button
									onclick={cancelEdit}
									class="cursor-pointer rounded-lg border border-gray-600 px-4 py-1.5 text-sm font-medium text-gray-300 transition hover:bg-gray-700 hover:text-white"
								>
									Cancel
								</button>
							</div>
						</div>
					{:else}
						<button
							type="button"
							onclick={() => toggleTodo(todo)}
							aria-pressed={todo.is_completed}
							title="Toggle complete"
							class="min-w-0 flex-1 cursor-pointer text-left"
						>
							<h3 class="text-xl font-semibold break-words text-gray-100">{todo.title}</h3>
							{#if todo.description}
								<p
									class="text-md mt-2 leading-relaxed break-words whitespace-pre-wrap text-gray-400"
								>
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
						</button>
					{/if}

					{#if editingId !== todo.id}
						<div
							class="flex flex-shrink-0 items-center justify-end transition-opacity group-hover:opacity-100 sm:flex-col sm:justify-start sm:opacity-0"
						>
							<button
								class="cursor-pointer rounded-lg p-2 text-gray-300 transition hover:bg-gray-700 hover:text-white"
								onclick={() => {
									startEdit(todo);
								}}
								aria-label="Edit task"
								title="Edit"
							>
								<SquarePen class="h-5 w-5" />
							</button>
							<button
								class="cursor-pointer rounded-lg p-2 text-red-400 transition hover:bg-red-900/30 hover:text-red-300"
								onclick={() => {
									deleteTodo(todo.id);
								}}
								aria-label="Delete task"
								title="Delete"
							>
								<Trash2 class="h-5 w-5" />
							</button>
						</div>
					{/if}
				</li>
			{/each}
			{#if todos.length === 0 && !error}
				<div
					class="rounded-2xl border border-dashed border-gray-700 bg-gray-800/40 px-4 py-16 text-center"
				>
					<ListPlus class="mx-auto mb-2 h-10 w-10 text-gray-600" />
					<h3 class="text-lg font-medium text-gray-300">No tasks yet</h3>
					<p class="mt-1 text-sm text-gray-500">Get started by creating a new task above.</p>
				</div>
			{/if}
		</ul>
	{/if}
</main>
