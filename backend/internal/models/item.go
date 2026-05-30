package models

import "time"

type Item struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

type ItemInput struct {
	Name string `json:"name" binding:"required"`
}
