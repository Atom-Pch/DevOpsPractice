package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq" // Import the PostgreSQL driver anonymously
)

// Todo represents our database model and JSON structure
type Todo struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	IsCompleted bool   `json:"is_completed"`
}

// User represents user authentication model
type User struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	PasswordHash string `json:"password_hash"`
	Email    string `json:"email"`
}

// AuthResponse represents the response after login/register
type AuthResponse struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Message  string `json:"message"`
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		// If it's a preflight OPTIONS request, stop here and return 200 OK
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Otherwise, pass the request down to the actual router
		next.ServeHTTP(w, r)
	})
}

func main() {
	// 1. Database Connection Configuration
	// We read these from the environment. Later, Docker and Terraform will inject these!
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASS")
	dbName := os.Getenv("DB_NAME")
	dbHost := os.Getenv("DB_HOST")

	// Default to localhost if DB_HOST isn't set (useful for quick local testing)
	if dbHost == "" {
		dbHost = "localhost"
	}

	// Construct the connection string
	connStr := fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbUser, dbPass, dbName)

	// Open the database connection
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	// Ping the database to ensure our credentials actually work
	if err := db.Ping(); err != nil {
		log.Printf("Warning: Database ping failed (Is Postgres running?): %v", err)
	} else {
		fmt.Println("Successfully connected to PostgreSQL!")
	}

	// 2. Setup API Routes
	// We use the standard HTTP multiplexer (router)
	mux := http.NewServeMux()

	// Health check endpoint - This is CRITICAL for DevOps!
	// AWS Load Balancers and Docker will use this to check if your app is alive.
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("API is healthy and running!"))
	})

	// Authentication endpoints
	mux.HandleFunc("POST /api/register", func(w http.ResponseWriter, r *http.Request) {
		var user User
		if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
			http.Error(w, "Invalid request payload", http.StatusBadRequest)
			return
		}

		if user.Username == "" || user.PasswordHash == "" || user.Email == "" {
			http.Error(w, "Username, password, and email are required", http.StatusBadRequest)
			return
		}

		// Hash the password (simple example - in production use bcrypt)
		hashedPassword := fmt.Sprintf("hashed_%s", user.PasswordHash)

		// Insert into database
		err := db.QueryRow(
			"INSERT INTO users (username, password_hash, email) VALUES ($1, $2, $3) RETURNING id",
			user.Username, hashedPassword, user.Email,
		).Scan(&user.ID)

		if err != nil {
			http.Error(w, "Failed to register user - " + err.Error(), http.StatusInternalServerError)
			return
		}

		// Return success response
		response := AuthResponse{
			ID:       user.ID,
			Username: user.Username,
			Email:    user.Email,
			Message:  "User registered successfully",
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(response)
	})

	mux.HandleFunc("POST /api/login", func(w http.ResponseWriter, r *http.Request) {
		var creds User
		if err := json.NewDecoder(r.Body).Decode(&creds); err != nil {
			http.Error(w, "Invalid request payload", http.StatusBadRequest)
			return
		}

		var storedUser User
		err := db.QueryRow(
			"SELECT id, username, password_hash FROM users WHERE username = $1",
			creds.Username,
		).Scan(&storedUser.ID, &storedUser.Username, &storedUser.PasswordHash)

		if err != nil {
			http.Error(w, "Failed to authenticate user - " + err.Error(), http.StatusUnauthorized)
			return
		}

		// In a real application, you would compare the hashed password
		if storedUser.PasswordHash != fmt.Sprintf("hashed_%s", creds.PasswordHash) {
			http.Error(w, "Invalid credentials", http.StatusUnauthorized)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(storedUser)
	})

	// GET: Fetch all To-Dos
	mux.HandleFunc("GET /api/todos", func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Query("SELECT id, title, description, is_completed FROM todos")
		if err != nil {
			http.Error(w, "Failed to query database", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var todos []Todo
		for rows.Next() {
			var t Todo
			// We use sql.NullString for description in case it's empty in the DB
			var desc sql.NullString
			if err := rows.Scan(&t.ID, &t.Title, &desc, &t.IsCompleted); err != nil {
				http.Error(w, "Failed to parse data", http.StatusInternalServerError)
				return
			}
			if desc.Valid {
				t.Description = desc.String
			}
			todos = append(todos, t)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(todos)
	})

	// POST: Create a new To-Do
	mux.HandleFunc("POST /api/todos", func(w http.ResponseWriter, r *http.Request) {
		var t Todo
		if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
			http.Error(w, "Invalid request payload", http.StatusBadRequest)
			return
		}

		// Insert into DB and return the new ID
		err := db.QueryRow(
			"INSERT INTO todos (title, description) VALUES ($1, $2) RETURNING id",
			t.Title, t.Description,
		).Scan(&t.ID)

		if err != nil {
			http.Error(w, "Failed to create To-Do", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(t)
	})

	// 3. Start the Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default port
	}

	fmt.Printf("Server starting on port %s...\n", port)
	log.Fatal(http.ListenAndServe(":"+port, corsMiddleware(mux)))
}
