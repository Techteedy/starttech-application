package config

import "os"

type Config struct {
	Port        string
	Environment string
	Version     string
	MongoURI    string
	RedisAddr   string
	RedisPass   string
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("APP_ENV", "development"),
		Version:     getEnv("APP_VERSION", "1.0.0"),
		MongoURI:    getEnv("MONGO_URI", "mongodb://localhost:27017/starttech"),
		RedisAddr:   getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPass:   getEnv("REDIS_PASS", ""),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
