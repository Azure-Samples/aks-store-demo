package main

type Order struct {
	OrderID    string `json:"orderId"`
	CustomerID string `json:"customerId"`
	Items      []Item `json:"items"`
	Status     Status `json:"status"`
}

type Status int

const (
	Pending Status = iota
	Processing
	Complete
)

type Item struct {
	Product  int     `json:"productId"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}

type OrderRepo interface {
	GetPendingOrders() ([]Order, error)
	GetOrder(id string) (Order, error)
	InsertOrders(orders []Order) error
	UpdateOrder(order Order) error
}

type OrderService struct {
	repo OrderRepo
}

func NewOrderService(repo OrderRepo) *OrderService {
	return &OrderService{repo}
}
