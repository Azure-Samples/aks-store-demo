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
	amqp "github.com/rabbitmq/amqp091-go"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type order struct {
	OrderID    string `json:"orderId"`
	CustomerID string `json:"customerId"`
	Items      []item `json:"items"`
	Status     Status `json:"status"`
}

type Status int

const (
	Pending Status = iota
	Processing
	Complete
)

type item struct {
	Product  int     `json:"product"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}

// Fetch orders from the RabbitMQ and store them in MongoDB
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

			// Create a random string to use as the order key
			orderKey := strconv.Itoa(rand.Intn(100000))

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

			// set the status to pending
			order.Status = Pending

			// Add order to []order slice
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

	// Save orders to MongoDB
	var ctx = context.TODO()

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

	// Convert []order to []interface{}
	var ordersInterface []interface{}
	for _, o := range orders {
		ordersInterface = append(ordersInterface, interface{}(o))
	}

	// Insert orders
	insertResult, err := collection.InsertMany(ctx, ordersInterface)
	if err != nil {
		log.Printf("Failed to insert order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	log.Printf("Inserted %v documents into MongoDB\n", len(insertResult.InsertedIDs))

	// Return the orders
	c.IndentedJSON(http.StatusOK, orders)
}

// Get order from MongoDB
func getOrder(c *gin.Context) {
	// TODO: Validate order ID
	orderId := c.Param("id")

	// Read order from MongoDB
	var ctx = context.TODO()

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

	// Find the order by orderId
	singleResult := collection.FindOne(ctx, bson.M{"orderid": orderId})
	var order order
	if singleResult.Decode(&order) != nil {
		log.Printf("Failed to decode order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// return the order to be processed
	c.IndentedJSON(http.StatusOK, order)
}

func updateOrder(c *gin.Context) {
	// unmarsal the order from the request body
	var order order
	if err := c.BindJSON(&order); err != nil {
		log.Printf("Failed to unmarshal order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Read order from MongoDB
	var ctx = context.TODO()

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

	// Update the order
	updateResult, err := collection.UpdateOne(
		ctx,
		bson.M{"orderid": order.OrderID},
		bson.D{
			{Key: "$set", Value: bson.D{{Key: "status", Value: order.Status}}},
		},
	)
	if err != nil {
		log.Printf("Failed to update order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	log.Printf("Matched %v documents and updated %v documents.\n", updateResult.MatchedCount, updateResult.ModifiedCount)

	c.SetAccepted("202")
}

func main() {
	router := gin.Default()
	router.GET("/fetch", fetchOrders)
	router.GET("/order/:id", getOrder)
	router.PUT("/order", updateOrder)
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "UP",
		})
	})
	router.Run(":3001")
}
