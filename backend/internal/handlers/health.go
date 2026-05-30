package handlers

import (
	"net/http"
	"time"

	"starttech-backend/internal/config"

	"github.com/gin-gonic/gin"
)

type HealthResponse struct {
	Status      string    `json:"status"`
	Environment string    `json:"environment"`
	Version     string    `json:"version"`
	Timestamp   time.Time `json:"timestamp"`
}

// HealthCheck returns 200 OK — used by the ALB target group health check
func HealthCheck(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, HealthResponse{
			Status:      "healthy",
			Environment: cfg.Environment,
			Version:     cfg.Version,
			Timestamp:   time.Now().UTC(),
		})
	}
}
