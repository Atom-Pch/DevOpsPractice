<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import { onMount } from 'svelte';

	let { children } = $props();

	const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

	let currentUser: string | null = $state(null);
	let isCheckingAuth = $state(true);
	let error = $state('')

	async function handleLogout() {
		try {
			await fetch(`${API_URL}/api/logout`, {
				method: 'POST',
				// CRITICAL: Tells the browser to send the cookie so Go can invalidate it
				credentials: 'include'
			});
			console.log('Logged out successfully.');
			// TODO: Clear local UI state and redirect to login page
			window.location.href = '/';
		} catch (err) {
			console.error('Failed to log out', err);
		}
	}

	onMount(async () => {
		// As soon as the app loads, check if we are logged in
		await checkSession();

		isCheckingAuth = false;
	});

	// --- CHECK WHO IS LOGGED IN ---
	async function checkSession() {
		try {
			const res = await fetch(`${API_URL}/api/me`, { credentials: 'include' });
			if (res.ok) {
				const data = await res.json();
				currentUser = data.username; // We found the user!
			} else {
				currentUser = null; // No valid session
				// NEW LOGIC: If the user doesn't exist anymore, destroy the zombie cookie
                if (res.status === 404 || res.status === 401) {
                    await fetch(`${API_URL}/api/logout`, { method: 'POST', credentials: 'include' });
                }
			}
		} catch (err) {
            // FIX THE OFFLINE BYPASS: If network is dead, assume logged out!
            console.error("Auth check failed (offline or backend down?):", err);
            currentUser = null; 
            error = "Cannot connect to server.";
            // Optional: goto('/login'); if using separate routes
        } finally {
            // NEW: Whether it succeeded, failed, or the network died, we are done checking.
            isCheckingAuth = false; 
        }
	}
</script>

<svelte:head><link rel="icon" href={favicon} /></svelte:head>

<style>
	:global(body) {
		background-color: #111827; /* Tailwind bg-gray-900 */
		margin: 0;
	}
</style>

<div class="min-h-screen bg-gray-900 text-gray-100 font-sans selection:bg-indigo-500/30 flex flex-col">
	<nav class="bg-gray-800 border-b border-gray-700 px-4 sm:px-8 py-4 sticky top-0 z-50 shadow-md">
		<div class="max-w-7xl mx-auto flex justify-between items-center">
			<div class="flex items-center">
				<a href="/" class="text-xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-purple-500 hover:opacity-80 transition">
					DevOps App
				</a>
			</div>
			{#if error}
        		<div>{error}</div>
   			 {/if}
			
			<div class="flex items-center space-x-4 sm:space-x-6">
				{#if currentUser}
					<form onsubmit={handleLogout} class="m-0">
						<button type="submit" class="text-sm font-medium text-gray-300 hover:text-white transition bg-gray-700/50 hover:bg-gray-600 px-4 py-2 rounded-lg">
							Logout <span class="opacity-60">({currentUser})</span>
						</button>
					</form>
				{:else}
					<a href="/register" class="text-sm font-medium text-gray-300 hover:text-white transition hidden sm:inline">Register</a>
					<a href="/login" class="text-sm font-medium px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white transition shadow-sm">
						Login
					</a>
				{/if}
			</div>
		</div>
	</nav>

	<div class="flex-grow w-full">
		{@render children()}
	</div>
</div>