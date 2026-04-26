<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	// Access the environment variable. It defaults to localhost if not set.
	const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

	let todos = $state<any[]>([]);
	let newTitle = $state('');
	let newDescription = $state('');
	let error = $state('');
	let imageFile = $state(<FileList | null>(null));
	let isUploading = $state(false);

	// Fetch the To-Dos as soon as the page loads
	onMount(async () => {
		await fetchTodos();
	});

	async function fetchTodos() {
		try {
			const res = await fetch(`${API_URL}/api/todos`, {
				credentials: 'include' // Important for session cookie
			});
			if (res.status === 401) {
				// THE BOUNCER: If Go says unauthorized, kick the user to the login page!
				goto('/login');
				console.log('Not logged in. Redirecting...');
				return; // Stop running this function
			}
			if (res.ok) {
				// If the DB is empty, the API might return null, so we fallback to an empty array
				todos = (await res.json()) || [];
			} else {
				error = 'Failed to load To-Dos from the server.';
			}
		} catch (err) {
			goto('/login')
			error = 'Could not connect to the API. Is the Go backend running?';
			console.error(err);
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
					`${API_URL}/api/todos/s3-presign?filename=${encodeURIComponent(file.name)}`,
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
			const res = await fetch(`${API_URL}/api/todos`, {
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
			console.error("Error creating To-Do:", err);
		} finally {
			isUploading = false;
		}
	}

	async function deleteTodo(id: number) {
		try {
			const res = await fetch(`${API_URL}/api/todos/${id}`, {
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

<main class="w-full max-w-3xl mx-auto pt-8 sm:pt-12 pb-24 px-4 sm:px-6">
	<div class="flex items-center justify-between mb-8">
		<h1 class="text-3xl sm:text-4xl font-bold text-white tracking-tight">Your Tasks</h1>
		<span class="bg-gray-800 text-indigo-400 py-1.5 px-4 rounded-full text-sm font-semibold border border-gray-700 shadow-sm">
			{todos.length} {todos.length === 1 ? 'Task' : 'Tasks'}
		</span>
	</div>

	{#if error}
		<div class="mb-8 bg-red-900/50 border border-red-500/50 text-red-200 p-4 rounded-xl flex items-center shadow-sm">
			<svg class="w-6 h-6 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
			<p class="text-sm font-medium">{error}</p>
		</div>
	{/if}

	<div class="bg-gray-800 rounded-2xl shadow-lg border border-gray-700 p-5 sm:p-6 mb-10 transition-all focus-within:ring-2 focus-within:ring-indigo-500">
		<form onsubmit={addTodo} class="flex flex-col sm:flex-row gap-4">
			<div class="flex-1 flex flex-col gap-3">
				<input 
					type="text" 
					placeholder="What needs to be done?" 
					bind:value={newTitle} 
					required 
					class="w-full bg-transparent border-b-2 border-gray-600 focus:border-indigo-500 px-2 py-2 text-lg text-white placeholder-gray-500 focus:outline-none transition"
				/>
				<input 
					type="text" 
					placeholder="Add description (Optional)" 
					bind:value={newDescription} 
					class="w-full bg-transparent border-b border-gray-700 focus:border-indigo-500 px-2 py-1 text-sm text-gray-400 placeholder-gray-600 focus:outline-none transition"
				/>
			</div>
			
			<div class="flex flex-row sm:flex-col items-center sm:items-stretch gap-3 sm:w-44 flex-shrink-0 justify-between mt-3 sm:mt-0">
				<label class="flex-1 cursor-pointer w-full text-center py-2.5 px-3 border border-gray-600 rounded-xl text-xs font-medium text-gray-300 hover:bg-gray-700 hover:text-white transition flex items-center justify-center truncate">
					<svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"></path></svg>
					{imageFile && imageFile.length > 0 ? imageFile[0].name : 'Attach Image'}
					<input type="file" accept="image/*" bind:files={imageFile} class="hidden" />
				</label>

				<button 
					type="submit" 
					disabled={isUploading}
					class="flex-1 sm:flex-none py-2.5 px-4 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-semibold rounded-xl shadow-md transition transform hover:-translate-y-0.5 flex justify-center items-center"
				>
					{#if isUploading}
						<svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
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
			<li class="bg-gray-800 rounded-2xl p-5 sm:p-6 shadow-md border border-gray-700 hover:border-gray-600 transition group flex flex-col sm:flex-row gap-4 sm:items-start justify-between">
				<div class="flex-1 min-w-0">
					<h3 class="text-xl font-semibold text-gray-100 break-words">{todo.title}</h3>
					{#if todo.description}
						<p class="mt-2 text-gray-400 text-md leading-relaxed whitespace-pre-wrap break-words">{todo.description}</p>
					{/if}
					{#if todo.image_url}
						<div class="mt-4 overflow-hidden rounded-xl border border-gray-700 inline-block max-w-full">
							<img src={todo.image_url} alt="Task attachment" class="max-h-64 sm:max-h-80 object-cover object-center w-auto shadow-sm" />
						</div>
					{/if}
				</div>
				
				<div class="sm:opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0 flex sm:flex-col justify-end sm:justify-start items-center">
					<button 
						class="text-red-400 hover:text-red-300 hover:bg-red-900/30 p-2 rounded-lg transition" 
						onclick={() => deleteTodo(todo.id)}
						aria-label="Delete task"
						title="Delete"
					>
						<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
					</button>
				</div>
			</li>
		{/each}
		
		{#if todos.length === 0 && !error}
			<div class="text-center py-16 px-4 bg-gray-800/40 rounded-2xl border border-gray-700 border-dashed">
				<svg class="mx-auto h-12 w-12 text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
				<h3 class="text-lg font-medium text-gray-300">No tasks yet</h3>
				<p class="mt-1 text-sm text-gray-500">Get started by creating a new task above.</p>
			</div>
		{/if}
	</ul>
</main>