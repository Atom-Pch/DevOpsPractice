<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();

	function handleLogout() {
		document.cookie = `logged_in=false; username=''; path=/`;
		window.location.href = '/login';
	}
</script>

<nav>
	<div class="grid grid-cols-3">
		<div class="flex items-center justify-start">
			<a href="/">Home</a>
		</div>
		<div>
			<div class="relative">
			</div>
		</div>
		<div class="flex items-center justify-end space-x-4">
			<button onclick={handleLogout}>Logout ()</button>
			<div class="border-l border-gray-300 h-6"></div>
			<a href="/register">Register</a>
			<a href="/login">Login</a>
		</div>
	</div>
</nav>

<style>
	nav {
		background-color: #f8f9fa;
		border-bottom: 1px solid #dee2e6;
		padding: 1rem 5rem;
	}
</style>

<svelte:head><link rel="icon" href={favicon} /></svelte:head>
{@render children()}
