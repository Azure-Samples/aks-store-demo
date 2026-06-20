package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
	"github.com/Azure/go-amqp"
)

// startConsumer runs a background loop that continuously reads messages from the
// order queue and persists them to the database. Messages are only acknowledged
// after a successful DB write, giving us at-least-once delivery guarantees.
func startConsumer(ctx context.Context, repo OrderRepo) {
	orderQueueName := os.Getenv("ORDER_QUEUE_NAME")
	if orderQueueName == "" {
		log.Fatalf("ORDER_QUEUE_NAME is not set")
	}

	useWorkloadIdentityAuth := os.Getenv("USE_WORKLOAD_IDENTITY_AUTH")
	orderQueueHostName := os.Getenv("AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE")
	if orderQueueHostName == "" {
		orderQueueHostName = os.Getenv("ORDER_QUEUE_HOSTNAME")
	}

	if orderQueueHostName != "" && useWorkloadIdentityAuth == "true" {
		runServiceBusConsumer(ctx, orderQueueHostName, orderQueueName, repo)
	} else {
		runAMQPConsumer(ctx, orderQueueName, repo)
	}
}

func runServiceBusConsumer(ctx context.Context, hostname string, queueName string, repo OrderRepo) {
	for {
		if err := serviceBusConsumeLoop(ctx, hostname, queueName, repo); err != nil {
			if ctx.Err() != nil {
				return
			}
			log.Printf("Service Bus consumer error: %s. Reconnecting in 5s...", err)
			time.Sleep(5 * time.Second)
		}
	}
}

func serviceBusConsumeLoop(ctx context.Context, hostname string, queueName string, repo OrderRepo) error {
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return fmt.Errorf("failed to get credential: %w", err)
	}

	client, err := azservicebus.NewClient(hostname, cred, nil)
	if err != nil {
		return fmt.Errorf("failed to create service bus client: %w", err)
	}
	defer client.Close(ctx)

	receiver, err := client.NewReceiverForQueue(queueName, nil)
	if err != nil {
		return fmt.Errorf("failed to create receiver: %w", err)
	}
	defer receiver.Close(ctx)

	log.Printf("Service Bus consumer connected to queue: %s", queueName)

	for {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		messages, err := receiver.ReceiveMessages(ctx, 10, nil)
		if err != nil {
			return fmt.Errorf("failed to receive messages: %w", err)
		}

		for _, message := range messages {
			// Unmarshal: Service Bus wraps the JSON as a quoted string
			var jsonStr string
			if err := json.Unmarshal(message.Body, &jsonStr); err != nil {
				log.Printf("failed to deserialize message envelope: %s", err)
				if deadLetterErr := receiver.DeadLetterMessage(ctx, message, nil); deadLetterErr != nil {
					log.Printf("failed to dead-letter message: %s", deadLetterErr)
				}
				continue
			}

			order, err := unmarshalOrderFromQueue([]byte(jsonStr))
			if err != nil {
				log.Printf("failed to unmarshal order: %s", err)
				if deadLetterErr := receiver.DeadLetterMessage(ctx, message, nil); deadLetterErr != nil {
					log.Printf("failed to dead-letter message: %s", deadLetterErr)
				}
				continue
			}

			// Write to DB first, then ack
			if err := repo.InsertOrders([]Order{order}); err != nil {
				log.Printf("failed to persist order %s: %s", order.OrderID, err)
				// Don't ack; message will be retried after lock expires
				continue
			}

			if err := receiver.CompleteMessage(ctx, message, nil); err != nil {
				log.Printf("failed to complete message: %s", err)
			}
		}
	}
}

func runAMQPConsumer(ctx context.Context, queueName string, repo OrderRepo) {
	for {
		if err := amqpConsumeLoop(ctx, queueName, repo); err != nil {
			if ctx.Err() != nil {
				return
			}
			log.Printf("AMQP consumer error: %s. Reconnecting in 5s...", err)
			time.Sleep(5 * time.Second)
		}
	}
}

func amqpConsumeLoop(ctx context.Context, queueName string, repo OrderRepo) error {
	orderQueueUri := os.Getenv("ORDER_QUEUE_URI")
	if orderQueueUri == "" {
		return errors.New("ORDER_QUEUE_URI is not set")
	}

	orderQueueUsername := os.Getenv("ORDER_QUEUE_USERNAME")
	orderQueuePassword := os.Getenv("ORDER_QUEUE_PASSWORD")

	conn, err := amqp.Dial(ctx, orderQueueUri, &amqp.ConnOptions{
		SASLType: amqp.SASLTypePlain(orderQueueUsername, orderQueuePassword),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to queue: %w", err)
	}
	defer conn.Close()

	session, err := conn.NewSession(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to create session: %w", err)
	}

	// RabbitMQ 4.x requires AMQP 1.0 address v2 format: /queues/<name>
	receiver, err := session.NewReceiver(ctx, "/queues/"+queueName, nil)
	if err != nil {
		return fmt.Errorf("failed to create receiver: %w", err)
	}
	defer func() {
		closeCtx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
		defer cancel()
		receiver.Close(closeCtx)
	}()

	log.Printf("AMQP consumer connected to queue: %s", queueName)

	for {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		// Block up to 5 seconds waiting for the next message
		recvCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		msg, err := receiver.Receive(recvCtx, nil)
		cancel()

		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			// Timeout just means no messages available, keep polling
			if recvCtx.Err() != nil {
				continue
			}
			return fmt.Errorf("receive error: %w", err)
		}

		order, err := unmarshalOrderFromQueue(msg.GetData())
		if err != nil {
			log.Printf("failed to unmarshal message, rejecting: %s", err)
			_ = receiver.RejectMessage(ctx, msg, nil)
			continue
		}

		// Write to DB first, then ack
		if err := repo.InsertOrders([]Order{order}); err != nil {
			log.Printf("failed to persist order %s: %s, releasing message", order.OrderID, err)
			_ = receiver.ReleaseMessage(ctx, msg)
			// Back off briefly to avoid hammering a failing DB
			time.Sleep(1 * time.Second)
			continue
		}

		if err := receiver.AcceptMessage(ctx, msg); err != nil {
			log.Printf("failed to accept message: %s", err)
		}
	}
}
