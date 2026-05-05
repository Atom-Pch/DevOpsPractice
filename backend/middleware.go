package main

import (
	"context"
	"net/http"
	"os"
	"regexp"
	"slices"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const userIDKey = contextKey("user_id")

var pattern = `^http://todo-app-alb-\d+\.us-east-2\.elb\.amazonaws\.com$`
var alb_origin = regexp.MustCompile(pattern)

var localhost_origin = []string{
	"http://localhost:5173",
	"http://localhost:3000",
}

// Global Middleware for CORS
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if alb_origin.MatchString(origin) || slices.Contains(localhost_origin, origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
		}

		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// App Method Middleware for Authentication
func (app *App) requireAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		cookie, err := r.Cookie("session_token")
		if err != nil {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		tokenString := cookie.Value
		jwtSecret := []byte(os.Getenv("JWT_SECRET"))

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Unauthorized | "+err.Error(), http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "Invalid token claims", http.StatusUnauthorized)
			return
		}

		userID := int(claims["user_id"].(float64))

		// Check if user exists in DB
		var exists bool
		err = app.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE id=$1)", userID).Scan(&exists)
		if err != nil || !exists {
			http.Error(w, "Unauthorized: User no longer exists", http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, userID)
		reqWithContext := r.WithContext(ctx)

		next.ServeHTTP(w, reqWithContext)
	}
}
