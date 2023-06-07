package main

import (
	"context"
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/redis/go-redis/v9"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type order struct {
	OrderID    string `json:"orderId"`
	CustomerID string `json:"customerId"`
	Items      []item `json:"items"`
}

type item struct {
	Product  int     `json:"product"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}

// Fetch orders from the RabbitMQ and store them in Redis
func fetchOrders(c *gin.Context) {
	var orders []order

	// Get RabbitMQ connection string from environment variable
	rabbitmqConn := os.Getenv("RABBITMQ_CONNECTION_STRING")
	if rabbitmqConn == "" {
		log.Printf("RABBITMQ_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Get queue name from environment variable
	rabbitmqQueueName := os.Getenv("RABBITMQ_QUEUE_NAME")
	if rabbitmqQueueName == "" {
		log.Printf("RABBITMQ_QUEUE_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Connect to RabbitMQ
	conn, err := amqp.Dial(rabbitmqConn)
	if err != nil {
		log.Printf("%s: %s", "Failed to connect to RabbitMQ", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		log.Printf("%s: %s", "Failed to open a channel", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	defer ch.Close()

	// Peek into the queue to get the number of messages
	queue, err := ch.QueueDeclarePassive(
		rabbitmqQueueName, // name
		false,             // durable
		false,             // delete when unused
		false,             // exclusive
		false,             // no-wait
		nil,               // arguments
	)
	if err != nil {
		log.Printf("Failed to inspect queue: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	numMessages := queue.Messages
	log.Printf("Number of messages in the queue: %d\n", numMessages)

	// Get the number of messages to consume from an environment variable
	numMessagesStr := os.Getenv("NUM_MESSAGES")
	numMessagesEnv, err := strconv.Atoi(numMessagesStr)
	if err != nil {
		log.Printf("NUM_MESSAGES is not set. Will read all messages from the queue\n")
	}

	// If the numMessageEnv is set, use it, otherwise use the number of messages in the queue
	if numMessagesEnv > 0 {
		numMessages = numMessagesEnv
	}

	// declare an empty redis client
	var client *redis.Client

	if numMessages > 0 {
		// Get Redis connection string from environment variable
		redisConn := os.Getenv("REDIS_CONNECTION_STRING")
		if redisConn == "" {
			log.Printf("REDIS_CONNECTION_STRING is not set")
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}

		opt, err := redis.ParseURL(redisConn)
		if err != nil {
			log.Printf("Unable to parse REDIS_CONNECTION_STRING %s", err)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}

		client = redis.NewClient(opt)
	}

	// Consume the specified number of messages from the queue
	for i := 0; i < numMessages; i++ {
		msg, ok, err := ch.Get(rabbitmqQueueName, false)
		if err != nil {
			log.Printf("Failed to consume message: %s", err)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}
		if !ok {
			log.Println("No message received")
		} else {
			log.Printf("Received: %s\n", msg.Body)

			// Process the message
			// Create a random string to use as the order key
			orderKey := strconv.Itoa(rand.Intn(100000))

			ctx := context.Background()
			err := client.Set(ctx, orderKey, msg.Body, 0).Err()
			if err != nil {
				log.Printf("Failed to set key: %s", err)
				c.AbortWithStatus(http.StatusInternalServerError)
				return
			}

			// Deserialize msg.Body to order and add to []order slice
			var order order
			err = json.Unmarshal(msg.Body, &order)

			if err != nil {
				log.Printf("Failed to deserialize message: %s", err)
				c.AbortWithStatus(http.StatusInternalServerError)
				return
			}

			// add orderkey to order
			order.OrderID = orderKey
			orders = append(orders, order)

			// Send an acknowledgement to remove the message from the queue
			if err := msg.Ack(false); err != nil {
				log.Printf("Failed to send acknowledgement: %s", err)
				c.AbortWithStatus(http.StatusInternalServerError)
				return
			}
		}
	}

	// Close the channel
	if err := ch.Close(); err != nil {
		log.Printf("Failed to close channel: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Close the connection
	if err := conn.Close(); err != nil {
		log.Printf("Failed to close connection: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Return the orders
	c.IndentedJSON(http.StatusOK, orders)
}

// Get order from Redis
func getOrder(c *gin.Context) {
	// Get Redis connection string from environment variable
	redisConn := os.Getenv("REDIS_CONNECTION_STRING")
	if redisConn == "" {
		log.Printf("REDIS_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	opt, err := redis.ParseURL(redisConn)
	if err != nil {
		log.Printf("Unable to parse REDIS_CONNECTION_STRING %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	client := redis.NewClient(opt)

	orderKey := c.Param("id")
	ctx := context.Background()

	// issue the GET command to retrieve the record
	val, err := client.Get(ctx, orderKey).Result()
	if err != nil {
		log.Printf("Failed to retrieve order: %s", err)
		c.AbortWithStatus(http.StatusNotFound)
		return
	}

	log.Printf("Order: %s\n", val)

	var order order
	err = json.Unmarshal([]byte(val), &order)
	if err != nil {
		log.Printf("Failed to deserialize message: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// add orderKey to order
	order.OrderID = orderKey

	// save a new record with the lockKey
	lockKey := uuid.New().String()

	// marshal the order to JSON
	orderJson, err := json.Marshal(order)
	if err != nil {
		log.Printf("Failed to marshal order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// save the order with the lockKey for later retrieval
	result, err := client.SetNX(ctx, lockKey, orderJson, 0).Result()
	if err != nil {
		log.Printf("Failed to set key: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}
	if !result {
		log.Printf("Resource %v did not lock\n", lockKey)
	}

	// lock the order with the lockKey to signal that it is being processed
	result, err = client.SetXX(ctx, orderKey, lockKey, 0).Result()
	if err != nil {
		log.Printf("Failed to lock resource: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	if !result {
		log.Printf("Resource %v did not lock\n", orderKey)
	}

	// return the order to be processed
	c.IndentedJSON(http.StatusOK, order)
}

func completeOrder(c *gin.Context) {
	// Get Redis connection string from environment variable
	redisConn := os.Getenv("REDIS_CONNECTION_STRING")
	if redisConn == "" {
		log.Printf("REDIS_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	opt, err := redis.ParseURL(redisConn)
	if err != nil {
		log.Printf("Unable to parse REDIS_CONNECTION_STRING %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	client := redis.NewClient(opt)

	orderKey := c.Param("id")
	ctx := context.Background()

	// issue the GET command to retrieve the record
	lockKey, err := client.Get(ctx, orderKey).Result()
	if err != nil {
		log.Printf("Failed to retrieve order: %s", err)
		c.AbortWithStatus(http.StatusNotFound)
		return
	}

	// using the value, retrieve the lockKey
	val, err := client.Get(ctx, lockKey).Result()
	if err != nil {
		log.Printf("Failed to retrieve lockKey: %s", err)
		c.AbortWithStatus(http.StatusNotFound)
		return
	}

	// deserialize the order
	var order order
	err = json.Unmarshal([]byte(val), &order)
	if err != nil {
		log.Printf("Failed to deserialize message: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	log.Printf("Processing order: %s\n", order.OrderID)

	// update the order

	// Get MongoDB connection string from environment variable
	mongoConn := os.Getenv("MONGO_CONNECTION_STRING")
	if mongoConn == "" {
		log.Printf("MONGO_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get MongoDB name from environment variable
	mongoDb := os.Getenv("MONGO_DATABASE_NAME")
	if mongoDb == "" {
		log.Printf("MONGO_DATABASE_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get MongoDB collection from environment variable
	mongoCollection := os.Getenv("MONGO_COLLECTION_NAME")
	if mongoCollection == "" {
		log.Printf("MONGO_COLLECTION_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	clientOptions := options.Client().ApplyURI(mongoConn)
	mongoClient, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// Get a handle for the orders collection
	collection := mongoClient.Database(mongoDb).Collection(mongoCollection)

	// Insert a single document
	insertResult, err := collection.InsertOne(ctx, order)
	if err != nil {
		log.Printf("Failed to insert order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	log.Printf("Inserted a single document: %s\n", insertResult.InsertedID)

	// delete the lockKey
	err = client.Del(ctx, lockKey).Err()
	if err != nil {
		log.Printf("Failed to delete lockKey: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// delete the order
	err = client.Del(ctx, orderKey).Err()
	if err != nil {
		log.Printf("Failed to delete order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}
}

func incompleteOrder(c *gin.Context) {
	// Get Redis connection string from environment variable
	redisConn := os.Getenv("REDIS_CONNECTION_STRING")
	if redisConn == "" {
		log.Printf("REDIS_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	opt, err := redis.ParseURL(redisConn)
	if err != nil {
		log.Printf("Unable to parse REDIS_CONNECTION_STRING %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	client := redis.NewClient(opt)

	orderKey := c.Param("id")
	ctx := context.Background()

	// issue the GET command to retrieve the record
	lockKey, err := client.Get(ctx, orderKey).Result()
	if err != nil {
		log.Printf("Failed to retrieve order: %s", err)
		c.AbortWithStatus(http.StatusNotFound)
		return
	}

	// using the value, retrieve the lockKey
	val, err := client.Get(ctx, lockKey).Result()
	if err != nil {
		log.Printf("Failed to retrieve lockKey: %s", err)
		c.AbortWithStatus(http.StatusNotFound)
		return
	}

	// deserialize the order
	var order order
	err = json.Unmarshal([]byte(val), &order)
	if err != nil {
		log.Printf("Failed to deserialize message: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	log.Printf("Un-procesing order: %s\n", order.OrderID)

	// delete the lockKey
	err = client.Del(ctx, lockKey).Err()
	if err != nil {
		log.Printf("Failed to delete lockKey: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// delete the order
	err = client.Del(ctx, orderKey).Err()
	if err != nil {
		log.Printf("Failed to delete order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// put the order back
	orderJson, err := json.Marshal(order)
	if err != nil {
		log.Printf("Failed to serialize order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	err = client.Set(ctx, orderKey, orderJson, 0).Err()
	if err != nil {
		log.Printf("Failed to set key: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
}

func main() {
	router := gin.Default()
	router.GET("/fetch", fetchOrders)
	router.GET("/order/:id", getOrder)
	router.PUT("/order/:id/complete", completeOrder)
	router.PUT("/order/:id/incomplete", incompleteOrder)
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "UP",
		})
	})
	router.Run(":3001")
}
