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

// Fetch orders from the order queue and store them in database
func fetchOrders(c *gin.Context) {
	var orders []order

	// Get order queue connection string from environment variable
	orderQueueConn := os.Getenv("ORDER_QUEUE_CONNECTION_STRING")
	if orderQueueConn == "" {
		log.Printf("ORDER_QUEUE_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Get queue name from environment variable
	orderQueueName := os.Getenv("ORDER_QUEUE_NAME")
	if orderQueueName == "" {
		log.Printf("ORDER_QUEUE_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Connect to order queue
	conn, err := amqp.Dial(orderQueueConn)
	if err != nil {
		log.Printf("%s: %s", "Failed to connect to order queue", err)
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
		orderQueueName, // name
		false,          // durable
		false,          // delete when unused
		false,          // exclusive
		false,          // no-wait
		nil,            // arguments
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
		msg, ok, err := ch.Get(orderQueueName, false)
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

	// Save orders to database
	var ctx = context.TODO()

	// Get database connection string from environment variable
	orderDBConn := os.Getenv("ORDER_DB_CONNECTION_STRING")
	if orderDBConn == "" {
		log.Printf("ORDER_DB_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database name from environment variable
	orderDBName := os.Getenv("ORDER_DB_NAME")
	if orderDBName == "" {
		log.Printf("ORDER_DB_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database collection from environment variable
	orderDBCollection := os.Getenv("ORDER_DB_COLLECTION_NAME")
	if orderDBCollection == "" {
		log.Printf("ORDER_DB_COLLECTION_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	clientOptions := options.Client().ApplyURI(orderDBConn)
	mongoClient, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Printf("Failed to connect to database: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// Get a handle for the orders collection
	collection := mongoClient.Database(orderDBName).Collection(orderDBCollection)

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

	log.Printf("Inserted %v documents into database\n", len(insertResult.InsertedIDs))

	// Return the orders
	c.IndentedJSON(http.StatusOK, orders)
}

// Get order from database
func getOrder(c *gin.Context) {
	// TODO: Validate order ID
	orderId := c.Param("id")

	// Read order from database
	var ctx = context.TODO()

	// Get database connection string from environment variable
	mongoConn := os.Getenv("ORDER_DB_CONNECTION_STRING")
	if mongoConn == "" {
		log.Printf("ORDER_DB_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database name from environment variable
	mongoDb := os.Getenv("ORDER_DB_NAME")
	if mongoDb == "" {
		log.Printf("ORDER_DB_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database collection from environment variable
	mongoCollection := os.Getenv("ORDER_DB_COLLECTION_NAME")
	if mongoCollection == "" {
		log.Printf("ORDER_DB_COLLECTION_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	clientOptions := options.Client().ApplyURI(mongoConn)
	mongoClient, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Printf("Failed to connect to database: %s", err)
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

	// Read order from database
	var ctx = context.TODO()

	// Get database connection string from environment variable
	mongoConn := os.Getenv("ORDER_DB_CONNECTION_STRING")
	if mongoConn == "" {
		log.Printf("ORDER_DB_CONNECTION_STRING is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database name from environment variable
	mongoDb := os.Getenv("ORDER_DB_NAME")
	if mongoDb == "" {
		log.Printf("ORDER_DB_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	// get database collection from environment variable
	mongoCollection := os.Getenv("ORDER_DB_COLLECTION_NAME")
	if mongoCollection == "" {
		log.Printf("ORDER_DB_COLLECTION_NAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
	}

	clientOptions := options.Client().ApplyURI(mongoConn)
	mongoClient, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Printf("Failed to connect to database: %s", err)
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

type order struct {
	OrderID    string `json:"orderId"`
	CustomerID string `json:"customerId"`
	Items      []item `json:"items"`
	Status     status `json:"status"`
}

type status int

const (
	Pending status = iota
	Processing
	Complete
)

type item struct {
	Product  int     `json:"productId"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}
