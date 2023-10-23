package main

import (
	"context"
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"

	amqp "github.com/Azure/go-amqp"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
)

// Fetch orders from the order queue and store them in database
func fetchOrders(c *gin.Context) {
	var orders []order

	// Get order queue connection string from environment variable
	orderQueueUri := os.Getenv("ORDER_QUEUE_URI")
	if orderQueueUri == "" {
		log.Printf("ORDER_QUEUE_URI is not set")
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

	// Get queue username from environment variable
	orderQueueUsername := os.Getenv("ORDER_QUEUE_USERNAME")
	if orderQueueName == "" {
		log.Printf("ORDER_QUEUE_USERNAME is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Get queue password from environment variable
	orderQueuePassword := os.Getenv("ORDER_QUEUE_PASSWORD")
	if orderQueuePassword == "" {
		log.Printf("ORDER_QUEUE_PASSWORD is not set")
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	ctx := context.Background()

	// Connect to order queue
	conn, err := amqp.Dial(ctx, orderQueueUri, &amqp.ConnOptions{
		SASLType: amqp.SASLTypePlain(orderQueueUsername, orderQueuePassword),
	})
	if err != nil {
		log.Printf("%s: %s", "Failed to connect to order queue", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	defer conn.Close()

	session, err := conn.NewSession(ctx, nil)
	if err != nil {
		log.Printf("Unable to create a new session")
	}

	{
		// create a receiver
		receiver, err := session.NewReceiver(ctx, orderQueueName, nil)
		if err != nil {
			log.Printf("Creating receiver link: %s", err)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}
		defer func() {
			ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
			receiver.Close(ctx)
			cancel()
		}()

		for {
			log.Printf("getting orders")

			ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
			defer cancel()

			// receive next message
			msg, err := receiver.Receive(ctx, nil)
			if err != nil {
				if err.Error() == "context deadline exceeded" {
					log.Printf("No more orders for you: %v", err.Error())
					break
				} else {
					c.AbortWithStatus(http.StatusInternalServerError)
					return
				}
			}

			messageBody := string(msg.GetData())
			log.Printf("Message received: %s\n", messageBody)

			// Create a random string to use as the order key
			orderKey := strconv.Itoa(rand.Intn(100000))

			// Deserialize msg data to order and add to []order slice
			var order order
			err = json.Unmarshal(msg.GetData(), &order)

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

			// accept message
			if err = receiver.AcceptMessage(context.TODO(), msg); err != nil {
				log.Printf("Failure accepting message: %s", err)
				// remove the order from the slice so that we pick it up on the next run
				orders = orders[:len(orders)-1]
			}
		}
	}

	// Save orders to database
	ctx = context.TODO()

	// Connect to MongoDB
	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	} else {
		log.Printf("Connected to MongoDB")
	}

	defer collection.Database().Client().Disconnect(context.Background())

	var ordersInterface []interface{}
	for _, o := range orders {
		ordersInterface = append(ordersInterface, interface{}(o))
	}

	if len(ordersInterface) == 0 {
		log.Printf("No orders to insert into database")
	} else {
		// Insert orders
		insertResult, err := collection.InsertMany(ctx, ordersInterface)
		if err != nil {
			log.Printf("Failed to insert order: %s", err)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}

		log.Printf("Inserted %v documents into database\n", len(insertResult.InsertedIDs))
	}

	// Return all pending orders
	orders = nil
	cursor, err := collection.Find(ctx, bson.M{"status": Pending})
	if err != nil {
		log.Printf("Failed to find records: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	// Check if there was an error during iteration
	if err := cursor.Err(); err != nil {
		log.Printf("Failed to find records: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Iterate over the cursor and decode each document
	for cursor.Next(ctx) {
		var pendingOrder order
		if err := cursor.Decode(&pendingOrder); err != nil {
			log.Printf("Failed to decode order: %s", err)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}
		orders = append(orders, pendingOrder)
	}

	// Return the pending orders
	c.IndentedJSON(http.StatusOK, orders)
}

// Get order from database
func getOrder(c *gin.Context) {
	// TODO: Validate order ID
	orderId := c.Param("id")

	// Read order from database
	var ctx = context.TODO()

	// Connect to MongoDB
	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	} else {
		log.Printf("Connected to MongoDB")
	}

	defer collection.Database().Client().Disconnect(context.Background())

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

	// Connect to MongoDB
	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	} else {
		log.Printf("Connected to MongoDB")
	}

	defer collection.Database().Client().Disconnect(context.Background())

	log.Printf("Updating order: %v", order)

	// Update the order
	updateResult, err := collection.UpdateMany(
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
	router.Use(cors.Default())
	router.GET("/order/fetch", fetchOrders)
	router.GET("/order/:id", getOrder)
	router.PUT("/order", updateOrder)
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"version": os.Getenv("APP_VERSION"),
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
