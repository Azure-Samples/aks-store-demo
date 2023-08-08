package main

import (
	"context"
	"crypto/tls"
	"log"
	"net/http"
	"os"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func connectToMongoDB() (*mongo.Collection, error) {
	// Get database uri from environment variable
	mongoUri := os.Getenv("ORDER_DB_URI")
	if mongoUri == "" {
		log.Printf("ORDER_DB_URI is not set")
		return nil, http.ErrAbortHandler
	}

	// get database name from environment variable
	mongoDb := os.Getenv("ORDER_DB_NAME")
	if mongoDb == "" {
		log.Printf("ORDER_DB_NAME is not set")
		return nil, http.ErrAbortHandler
	}

	// get database collection name from environment variable
	mongoCollection := os.Getenv("ORDER_DB_COLLECTION_NAME")
	if mongoCollection == "" {
		log.Printf("ORDER_DB_COLLECTION_NAME is not set")
		return nil, http.ErrAbortHandler
	}

	// get database username from environment variable
	mongoUser := os.Getenv("ORDER_DB_USERNAME")

	// get database password from environment variable
	mongoPassword := os.Getenv("ORDER_DB_PASSWORD")

	// create a context
	ctx := context.Background()

	// create a mongo client
	var clientOptions *options.ClientOptions
	if mongoUser == "" && mongoPassword == "" {
		clientOptions = options.Client().ApplyURI(mongoUri)
	} else {
		clientOptions = options.Client().ApplyURI(mongoUri).
			SetAuth(options.Credential{
				Username: mongoUser,
				Password: mongoPassword,
			}).
			SetTLSConfig(&tls.Config{InsecureSkipVerify: true})
	}

	mongoClient, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Printf("failed to connect to mongodb: %s", err)
		return nil, err
	}

	err = mongoClient.Ping(ctx, nil)
	if err != nil {
		log.Printf("failed to ping database: %s", err)
	} else {
		log.Printf("pong from database")
	}

	// get a handle for the collection
	collection := mongoClient.Database(mongoDb).Collection(mongoCollection)

	return collection, nil
}
