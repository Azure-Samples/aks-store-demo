import json
import os
from datetime import datetime
import time
import random
import requests

def main():
    print(f"[INFO] Serviço virtual-customer iniciado às {datetime.now()}")

    # Configurações de ambiente
    order_service_url = "http://order-service:3000/"

    orders_per_hour = int(os.getenv("ORDERS_PER_HOUR", "100"))

    if orders_per_hour == 0:
        print("[ERROR] ORDERS_PER_HOUR não pode ser zero.")
        return

    order_submission_interval = 3600 / orders_per_hour
    print(f"[INFO] Intervalo entre pedidos: {order_submission_interval} segundos")

    order_counter = 0
    start_time = datetime.now()

    while True:
        order_counter += 1

        # Geração de dados do pedido
        customer_id = str(random.randint(888888888, 1000000001))
        number_of_items = random.randint(4, 10)
  
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

        serialized_order = json.dumps(order)
        print(f"[DEBUG] Pedido gerado: {serialized_order}")

        try:
            response = requests.post(
                order_service_url,
                headers={"Content-Type": "application/json"},
                data=serialized_order,
                timeout=10  # Timeout de 10 segundos
            )

            elapsed_time = (datetime.now() - start_time).total_seconds()
            if response.ok:
                print(f"[INFO] Pedido {order_counter} enviado em {elapsed_time:.2f} segundos com status {response.status_code}")
            else:
                print(f"[ERROR] Erro ao enviar o pedido: {response.status_code} - {response.text}")
                print(f"[DEBUG] Cabeçalhos da resposta: {response.headers}")
        except requests.RequestException as e:
            print(f"[ERROR] Erro de requisição: {e}")


        time.sleep(order_submission_interval)

if __name__ == "__main__":
    main()