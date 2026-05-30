package handlers_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"starttech-backend/internal/config"
	"starttech-backend/internal/handlers"

	"github.com/gin-gonic/gin"
)

func setupRouter(cfg *config.Config) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.GET("/health", handlers.HealthCheck(cfg))
	r.GET("/api/items", handlers.GetItems)
	return r
}

func TestHealthCheck(t *testing.T) {
	cfg := &config.Config{
		Port:        "8080",
		Environment: "test",
		Version:     "1.0.0",
	}
	router := setupRouter(cfg)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("Failed to parse response body: %v", err)
	}

	if response["status"] != "healthy" {
		t.Errorf("Expected status 'healthy', got '%v'", response["status"])
	}
}

func TestGetItemsEmpty(t *testing.T) {
	cfg := &config.Config{}
	router := setupRouter(cfg)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/items", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}
}
