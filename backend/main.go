package main

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"log"
	"net/http"
	"os"
)

// App holds our external dependencies so all our routes can access them
type App struct {
	DB               *sql.DB
	StandardS3Client *s3.Client
	PresignClient    *s3.PresignClient
	BucketName       string
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: Error loading .env file (ignoring if variables are set in environment)")
	}

	// 1. Initialize Database
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASS")
	dbName := os.Getenv("DB_NAME")
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}

	connStr := fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=prefer", dbHost, dbUser, dbPass, dbName)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("FATAL. Failed to open database connection: %v", err)
		return
	}

	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("Failed to close database connection: %v", err)
		}
	}()

	if err := db.Ping(); err != nil {
		log.Printf("FATAL. Database ping failed: %v", err)
		return
	} else {
		log.Println("Successfully connected to PostgreSQL!")
		var v string
		err = db.QueryRow("SELECT version()").Scan(&v)
		if err != nil {
			log.Fatalf("FATAL. Failed to select in database: %v", err)
			return
		}
		log.Println(v)
	}

	// Expose DB connection stats as Prometheus metrics
	promauto.NewGaugeFunc(prometheus.GaugeOpts{
		Name: "db_open_connections",
		Help: "Number of open DB connections.",
	}, func() float64 { return float64(db.Stats().OpenConnections) })

	promauto.NewGaugeFunc(prometheus.GaugeOpts{
		Name: "db_in_use_connections",
		Help: "Number of DB connections in use.",
	}, func() float64 { return float64(db.Stats().InUse) })

	// 2. Initialize AWS S3
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatalf("unable to load AWS SDK config: %v", err)
	}

	// 3. Create the Application Instance
	app := &App{
		DB:               db,
		StandardS3Client: s3.NewFromConfig(cfg),
		PresignClient:    s3.NewPresignClient(s3.NewFromConfig(cfg)),
		BucketName:       os.Getenv("S3_BUCKET_NAME"),
	}

	// 4. Setup Routes
	mux := http.NewServeMux()

	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, err = w.Write([]byte("API is healthy and running!"))
		if err != nil {
			http.Error(w, "Failed to Write", http.StatusInternalServerError)
			return
		}
	})

	// Auth Routes
	mux.HandleFunc("POST /api/register", app.registerUser)
	mux.HandleFunc("POST /api/login", app.loginUser)
	mux.HandleFunc("POST /api/logout", app.logoutUser)
	mux.HandleFunc("GET /api/who", app.getCurrentUser)

	// To-Do Routes (Protected by Auth Middleware)
	mux.HandleFunc("GET /api/todos", app.requireAuth(app.getTodos))
	mux.HandleFunc("POST /api/todos", app.requireAuth(app.createTodo))
	mux.HandleFunc("PATCH /api/todos/{id}", app.requireAuth(app.updateTodo))
	mux.HandleFunc("DELETE /api/todos/{id}", app.requireAuth(app.deleteTodo))
	mux.HandleFunc("GET /api/todos/s3-presign", app.requireAuth(app.presignS3))

	// Expose Prometheus Metrics ---
	go func() {
		metricsMux := http.NewServeMux()
		metricsMux.Handle("GET /metrics", promhttp.Handler())

		log.Println("Metrics server starting on port 9090...")
		log.Fatal(http.ListenAndServe(":9090", metricsMux))
	}()

	// 5. Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s...\n", port)
	// --- NEW: Wrap the mux in BOTH corsMiddleware and metricsMiddleware ---
	log.Fatal(http.ListenAndServe(":"+port, corsMiddleware(metricsMiddleware(mux))))
}
