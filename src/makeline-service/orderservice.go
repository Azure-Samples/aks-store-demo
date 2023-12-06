package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"math/rand"
	"os"
	"strconv"
	"time"

	amqp "github.com/Azure/go-amqp"
	"go.mongodb.org/mongo-driver/bson"
)

func getOrdersFromQueue() ([]order, error) {
	var orders []order

	// Get order queue connection string from environment variable
	orderQueueUri := os.Getenv("ORDER_QUEUE_URI")
	if orderQueueUri == "" {
		log.Printf("ORDER_QUEUE_URI is not set")
		return nil, errors.New("ORDER_QUEUE_URI is not set")
	}

	// Get queue name from environment variable
	orderQueueName := os.Getenv("ORDER_QUEUE_NAME")
	if orderQueueName == "" {
		log.Printf("ORDER_QUEUE_NAME is not set")
		return nil, errors.New("ORDER_QUEUE_URI is not set")
	}

	// Get queue username from environment variable
	orderQueueUsername := os.Getenv("ORDER_QUEUE_USERNAME")
	if orderQueueName == "" {
		log.Printf("ORDER_QUEUE_USERNAME is not set")
		return nil, errors.New("ORDER_QUEUE_URI is not set")
	}

	// Get queue password from environment variable
	orderQueuePassword := os.Getenv("ORDER_QUEUE_PASSWORD")
	if orderQueuePassword == "" {
		log.Printf("ORDER_QUEUE_PASSWORD is not set")
		return nil, errors.New("ORDER_QUEUE_URI is not set")
	}

	ctx := context.Background()

	// Connect to order queue
	conn, err := amqp.Dial(ctx, orderQueueUri, &amqp.ConnOptions{
		SASLType: amqp.SASLTypePlain(orderQueueUsername, orderQueuePassword),
	})
	if err != nil {
		log.Printf("%s: %s", "Failed to connect to order queue", err)
		return nil, errors.New("ORDER_QUEUE_URI is not set")
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
			return nil, errors.New("ORDER_QUEUE_URI is not set")
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
					return nil, errors.New("ORDER_QUEUE_URI is not set")
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
				return nil, errors.New("ORDER_QUEUE_URI is not set")
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
	return orders, nil
}

func insertOrdersToDB(orders []order) error {
	ctx := context.TODO()

	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		return err
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
			return err
		}

		log.Printf("Inserted %v documents into database\n", len(insertResult.InsertedIDs))
	}
	return nil
}

func getPendingOrdersFromDB() ([]order, error) {
	ctx := context.TODO()

	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		return nil, err
	} else {
		log.Printf("Connected to MongoDB")
	}

	defer collection.Database().Client().Disconnect(context.Background())

	var orders []order
	cursor, err := collection.Find(ctx, bson.M{"status": Pending})
	if err != nil {
		log.Printf("Failed to find records: %s", err)
		return nil, err
	}
	defer cursor.Close(ctx)

	// Check if there was an error during iteration
	if err := cursor.Err(); err != nil {
		log.Printf("Failed to find records: %s", err)
		return nil, err
	}

	// Iterate over the cursor and decode each document
	for cursor.Next(ctx) {
		var pendingOrder order
		if err := cursor.Decode(&pendingOrder); err != nil {
			log.Printf("Failed to decode order: %s", err)
			return nil, err
		}
		orders = append(orders, pendingOrder)
	}

	return orders, nil
}

func getOrderFromDB(orderId string) (order, error) {
	var ctx = context.TODO()

	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		return order{}, err
	} else {
		log.Printf("Connected to MongoDB")
	}

	defer collection.Database().Client().Disconnect(context.Background())

	// Find the order by orderId
	singleResult := collection.FindOne(ctx, bson.M{"orderid": orderId})
	var order order
	if singleResult.Decode(&order) != nil {
		log.Printf("Failed to decode order: %s", err)
		return order, err
	}

	return order, nil
}

func updateOrderStatus(order order) error {
	var ctx = context.TODO()

	// Connect to MongoDB
	collection, err := connectToMongoDB()
	if err != nil {
		log.Printf("Failed to connect to MongoDB: %s", err)
		return err
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
		return err
	}

	log.Printf("Matched %v documents and updated %v documents.\n", updateResult.MatchedCount, updateResult.ModifiedCount)
	return nil
}
