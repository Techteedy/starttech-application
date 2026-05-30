package handlers

import (
	"net/http"
	"time"

	"starttech-backend/internal/models"

	"github.com/gin-gonic/gin"
)

// In-memory store for simplicity (replace with MongoDB calls in production)
var itemStore = []models.Item{}

func GetItems(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"items": itemStore,
		"count": len(itemStore),
	})
}

func GetItemByID(c *gin.Context) {
	id := c.Param("id")
	for _, item := range itemStore {
		if item.ID == id {
			c.JSON(http.StatusOK, item)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "item not found"})
}

func CreateItem(c *gin.Context) {
	var input models.ItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item := models.Item{
		ID:        generateID(),
		Name:      input.Name,
		CreatedAt: time.Now().UTC(),
	}
	itemStore = append(itemStore, item)

	c.JSON(http.StatusCreated, item)
}

func generateID() string {
	return time.Now().Format("20060102150405.000000000")
}
