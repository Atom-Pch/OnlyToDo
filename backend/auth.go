package main

import (
	"encoding/json"
	"github.com/golang-jwt/jwt/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"golang.org/x/crypto/bcrypt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

type Credentials struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

var authFailuresTotal = promauto.NewCounterVec(prometheus.CounterOpts{
	Name: "auth_failures_total",
	Help: "Total authentication failures.",
}, []string{"reason"})

func (app *App) registerUser(w http.ResponseWriter, r *http.Request) {
	var creds Credentials
	err := json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, "Failed to decode JSON credentials", http.StatusInternalServerError)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(creds.Password), 14)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	timer := prometheus.NewTimer(dbQueryDuration.WithLabelValues("registerUser"))
	_, err = app.DB.Exec("INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3)",
		creds.Username, creds.Email, string(hashedPassword))
	timer.ObserveDuration()

	if err != nil {
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		authFailuresTotal.WithLabelValues("registration_failed").Inc()
		return
	}

	w.WriteHeader(http.StatusCreated)
	_, err = w.Write([]byte(`{"message": "User registered successfully"}`))
	if err != nil {
		http.Error(w, "Failed to Write", http.StatusInternalServerError)
		return
	}
}

func (app *App) loginUser(w http.ResponseWriter, r *http.Request) {
	var creds Credentials
	err:=json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, "Failed to decode JSON credentials", http.StatusInternalServerError)
		return
	}

	var storedHash string
	var userID int

	timer := prometheus.NewTimer(dbQueryDuration.WithLabelValues("loginUser"))
	err = app.DB.QueryRow("SELECT id, password_hash FROM users WHERE username=$1", creds.Username).Scan(&userID, &storedHash)
	timer.ObserveDuration()

	if err != nil {
		http.Error(w, "Failed to get user", http.StatusUnauthorized)
		authFailuresTotal.WithLabelValues("invalid_user").Inc()
		return
	}

	if err = bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(creds.Password)); err != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		authFailuresTotal.WithLabelValues("invalid_credentials").Inc()
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	jwtSecret := os.Getenv("BACKEND_JWT_STRING")
	tokenString, _ := token.SignedString([]byte(jwtSecret))

	secureCookieStr := os.Getenv("SECURE_COOKIE")
	secureCookie, err := strconv.ParseBool(secureCookieStr)
	if err != nil {
		log.Fatalf("FATAL. SECURE_COOKIE env %v", err)
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name:     "session_token",
		Value:    tokenString,
		Expires:  time.Now().Add(time.Hour * 24),
		HttpOnly: true,
		Secure:   secureCookie,
		Path:     "/",
		SameSite: http.SameSiteLaxMode,
	})

	_, err = w.Write([]byte(`{"message": "Logged in successfully"}`))
	if err != nil {
		http.Error(w, "Failed to Write", http.StatusInternalServerError)
		return
	}
}

func (app *App) logoutUser(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     "session_token",
		Value:    "",
		Expires:  time.Now().Add(-1 * time.Hour),
		HttpOnly: true,
		Path:     "/",
	})
	_, err := w.Write([]byte(`{"message": "Logged out"}`))
	if err != nil {
		http.Error(w, "Failed to Write", http.StatusInternalServerError)
		return
	}
}

func (app *App) getCurrentUser(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("session_token")
	if err != nil {
		http.Error(w, "Not logged in", http.StatusUnauthorized)
		return
	}

	jwtSecret := []byte(os.Getenv("BACKEND_JWT_STRING"))
	token, err := jwt.Parse(cookie.Value, func(token *jwt.Token) (any, error) {
		return jwtSecret, nil
	})

	if err != nil || !token.Valid {
		http.Error(w, "Invalid session", http.StatusUnauthorized)
		authFailuresTotal.WithLabelValues("Invalid session").Inc()
		return
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		http.Error(w, "Invalid token claims", http.StatusUnauthorized)
		authFailuresTotal.WithLabelValues("Invalid token claims").Inc()
		return
	}

	userID := int(claims["user_id"].(float64))

	var username string

	timer := prometheus.NewTimer(dbQueryDuration.WithLabelValues("getCurrentUser"))
	err = app.DB.QueryRow("SELECT username FROM users WHERE id=$1", userID).Scan(&username)
	timer.ObserveDuration()

	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		authFailuresTotal.WithLabelValues("user_not_found").Inc()
		return
	}

	w.Header().Set("Content-Type", "application/json")
	err = json.NewEncoder(w).Encode(map[string]string{
		"username": username,
	})
	if err != nil {
		http.Error(w, "Failed to encode JSON", http.StatusInternalServerError)
		return
	}
}
