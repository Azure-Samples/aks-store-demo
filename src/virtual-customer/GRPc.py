import os
import time
import random
import grpc
import mensagem_pb2
import mensagem_pb2_grpc
from datetime import datetime
from prometheus_client import start_http_server, Summary, Counter, Gauge
import time

def main():
    print(f"[INFO] Serviço virtual-customer iniciado às {datetime.now()}")

    # Define as métricas usadas para medir o prometheus
    REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')
    ORDER_COUNTER = Counter('orders_total', 'Total number of orders processed')
    ORDER_SIZE_GAUGE = Gauge('order_size_items', 'Number of items in an order')
    PROMETHEUS_PORT = 8000  # Escolha uma porta
    start_http_server(PROMETHEUS_PORT)
    print(f"[INFO] Servidor de métricas Prometheus iniciado na porta {PROMETHEUS_PORT}")
 
    
    # Configurações de ambiente
    grpc_server_address = "order-service:50051"  # This is the gRPC server address (not HTTP)

    orders_per_hour = int(os.getenv("ORDERS_PER_HOUR", "6"))

    if orders_per_hour == 0:
        print("[ERROR] ORDERS_PER_HOUR não pode ser zero.")
        return

    order_submission_interval = 3600 / orders_per_hour
    print(f"[INFO] Intervalo entre pedidos: {order_submission_interval} segundos")

    order_counter = 0
    start_time = datetime.now()

    # Create gRPC channel and stub
    channel = grpc.insecure_channel(grpc_server_address)
    stub = mensagem_pb2_grpc.MensagemServiceStub(channel)

    while True:
        order_counter += 1

        # Geração de dados do pedido
        customer_id = str(random.randint(1, 100))
        number_of_items = random.randint(1, 5)
        
        items = [
            {
                "productId": random.randint(1, 10),
                "quantity": random.randint(1, 5),
                "price": round(random.uniform(1.0, 10.0), 2)
            }
            for _ in range(number_of_items)
        ]

        order = {
            "customerId": customer_id,
            "items": items
        }
        print(f"Pedido do cliente: {customer_id}")

        ORDER_COUNTER.inc()  # Incrementa o contador de pedidos
        ORDER_SIZE_GAUGE.set(len(items))  # Define o tamanho do pedido

        # Prepare the request for gRPC
        request = mensagem_pb2.MensagemRequest(conteudo=str(order))

        try:
            # Call the gRPC method
            print(f"pedido enviada: {order} ")
            response = stub.EnviarMensagem(request)

            elapsed_time = (datetime.now() - start_time).total_seconds()

            if response.resposta:
                print(f"[INFOMATION] Pedido {order_counter} enviado em {elapsed_time:.2f} segundos com resposta: {response.resposta}")
            else:
                print(f"[ERROR] Erro ao enviar o pedido.")
                print(f"[DEBUG] Resposta: {response.resposta}")

        except grpc.RpcError as e:
            print(f"[ERROR] Erro de requisição gRPC: {e}")

        # Sleep between orders
        time.sleep(order_submission_interval)

if __name__ == "__main__":
    main()
 