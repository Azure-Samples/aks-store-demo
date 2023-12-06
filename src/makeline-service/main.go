package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// Fetches orders from the order queue and stores them in database
func fetchOrders(c *gin.Context) {
	// Get orders from the queue
	orders, err := getOrdersFromQueue()
	if err != nil {
		log.Printf("Failed to fetch orders from queue: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Save orders to database
	insertOrdersToDB(orders)
	if err != nil {
		log.Printf("Failed to save orders to database: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	// Return the orders to be processed
	orders, err = getPendingOrdersFromDB()
	if err != nil {
		log.Printf("Failed to get pending orders from database: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.IndentedJSON(http.StatusOK, orders)
}

// Gets a single order from database by order ID
func getOrder(c *gin.Context) {
	order, err := getOrderFromDB(c.Param("id"))
	if err != nil {
		log.Printf("Failed to get order from database: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.IndentedJSON(http.StatusOK, order)
}

// Updates the status of an order
func updateOrder(c *gin.Context) {
	// unmarsal the order from the request body
	var order order
	if err := c.BindJSON(&order); err != nil {
		log.Printf("Failed to unmarshal order: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	err := updateOrderStatus(order)
	if err != nil {
		log.Printf("Failed to update order status: %s", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

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
