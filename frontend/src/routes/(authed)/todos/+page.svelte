<script lang="ts">
	import { onMount } from 'svelte';

	// Access the environment variable. It defaults to localhost if not set.
	const API_URL = import.meta.env.VITE_PUBLIC_API_URL || 'http://localhost:8080';

	let todos = $state<any[]>([]);
	let newTitle = $state('');
	let newDescription = $state('');
	let error = $state('');

	// Fetch the To-Dos as soon as the page loads
	onMount(async () => {
		await fetchTodos();
	});

	async function fetchTodos() {
		try {
			const res = await fetch(`${API_URL}/api/todos`);
			if (res.ok) {
				// If the DB is empty, the API might return null, so we fallback to an empty array
				todos = (await res.json()) || [];
			} else {
				error = 'Failed to load To-Dos from the server.';
			}
		} catch (err) {
			error = 'Could not connect to the API. Is the Go backend running?';
			console.error(err);
		}
	}

	async function addTodo(event: Event) {
		event.preventDefault(); // Prevent the form from refreshing the page
		error = '';

		try {
			const res = await fetch(`${API_URL}/api/todos`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({
					title: newTitle,
					description: newDescription
				})
			});

			if (res.ok) {
				const newTodo = await res.json();
				todos = [...todos, newTodo]; // Update the UI state
				newTitle = ''; // Clear the form
				newDescription = '';
			} else {
				error = 'Failed to create To-Do.';
			}
		} catch (err) {
			error = 'Could not connect to the API to save the To-Do.';
			console.error(err);
		}
	}
</script>

<main>
	{#if error}
		<div class="error-banner">{error}</div>
	{/if}

	<form onsubmit={addTodo}>
		<input type="text" placeholder="To-Do Title" bind:value={newTitle} required />
		<input type="text" placeholder="Description (Optional)" bind:value={newDescription} />
		<button type="submit">Add Task</button>
	</form>

	<ul>
		{#each todos as todo}
			<li>
				<strong>{todo.title}</strong>
				{#if todo.description}
					<p>{todo.description}</p>
				{/if}
			</li>
		{/each}
		{#if todos.length === 0 && !error}
			<p class="empty-state">No tasks yet. Create one above to test the database!</p>
		{/if}
	</ul>
</main>

<style>
	/* Clean, minimal styling for the UI */
	:global(body) {
		font-family:
			system-ui,
			-apple-system,
			sans-serif;
		background-color: #f9fafb;
		color: #111827;
	}
	main {
		max-width: 600px;
		margin: 3rem auto;
		padding: 0 1rem;
	}
	.error-banner {
		background-color: #fee2e2;
		color: #991b1b;
		padding: 1rem;
		border-radius: 6px;
		margin-bottom: 1rem;
		text-align: center;
	}
	form {
		display: flex;
		gap: 0.5rem;
		margin-bottom: 2rem;
	}
	input {
		flex: 1;
		padding: 0.75rem;
		border: 1px solid #d1d5db;
		border-radius: 6px;
	}
	button {
		padding: 0.75rem 1.5rem;
		background-color: #2563eb;
		color: white;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-weight: bold;
	}
	button:hover {
		background-color: #1d4ed8;
	}
	ul {
		list-style: none;
		padding: 0;
	}
	li {
		background: white;
		margin-bottom: 1rem;
		padding: 1.5rem;
		border-radius: 8px;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
		border: 1px solid #e5e7eb;
	}
	li strong {
		display: block;
		font-size: 1.1rem;
	}
	li p {
		margin: 0.5rem 0 0 0;
		color: #4b5563;
	}
	.empty-state {
		text-align: center;
		color: #6b7280;
		font-style: italic;
	}
</style>
