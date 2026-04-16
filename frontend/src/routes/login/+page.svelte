<script lang="ts">
	// Access the environment variable. It defaults to localhost if not set.
	const API_URL = import.meta.env.VITE_PUBLIC_API_URL || 'http://localhost:8080';

	let username = $state('');
	let password = $state('');
	let error = $state('');

	async function handleLogin() {
		if (!username || !password) {
			error = 'Please fill in all fields';
			return;
		}

		try {
			const response = await fetch(`${API_URL}/api/login`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ username: username, password_hash: password })
			});

			if (response.ok) {
				document.cookie = `logged_in=true; username=${username}; path=/`;
				window.location.href = '/todos';
			} else {
				error = 'Invalid username or password';
			}
		} catch (err) {
			error = 'An error occurred. Please try again.' + err;
		}
	}
</script>

<div class="login-container">
	<div class="login-card">
		<h1>Login</h1>

		{#if error}
			<div class="error-message">{error}</div>
		{/if}

		<form onsubmit={handleLogin}>
			<div class="form-group">
				<label for="username">Username</label>
				<input
					type="text"
					id="username"
					bind:value={username}
					placeholder="Enter your username"
					required
				/>
			</div>

			<div class="form-group">
				<label for="password">Password</label>
				<input
					type="password"
					id="password"
					bind:value={password}
					placeholder="Enter your password"
					required
				/>
			</div>

			<button type="submit" class="login-btn">Login</button>
		</form>
	</div>
</div>

<style>
	.login-container {
		display: flex;
		justify-content: center;
		align-items: center;
		min-height: 50vh;
	}

	.login-card {
		background: white;
		padding: 2rem;
		border-radius: 8px;
		box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
		width: 100%;
		max-width: 400px;
	}

	h1 {
		text-align: center;
		color: #333;
		margin-bottom: 1.5rem;
		font-size: 1.5rem;
	}

	.error-message {
		background-color: #fee;
		color: #c33;
		padding: 0.75rem;
		border-radius: 4px;
		margin-bottom: 1rem;
		text-align: center;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	label {
		display: block;
		margin-bottom: 0.5rem;
		color: #555;
		font-weight: 500;
	}

	input {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-size: 1rem;
		box-sizing: border-box;
		transition: border-color 0.3s;
	}

	input:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.login-btn {
		width: 100%;
		padding: 0.75rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		border-radius: 4px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition:
			transform 0.2s,
			box-shadow 0.2s;
	}

	.login-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
	}

	.login-btn:active {
		transform: translateY(0);
	}
</style>
