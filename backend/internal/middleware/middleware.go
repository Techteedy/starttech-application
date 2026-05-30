package middleware

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

// Logger logs each request in a structured format (picked up by CloudWatch)
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		log.Printf(
			"[%s] %s %s | status=%d | latency=%s | ip=%s",
			time.Now().Format(time.RFC3339),
			c.Request.Method,
			c.Request.URL.Path,
			c.Writer.Status(),
			time.Since(start),
			c.ClientIP(),
		)
	}
}

// Recovery handles panics gracefully
func Recovery() gin.HandlerFunc {
	return gin.Recovery()
}

// CORS allows frontend to call the backend
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
