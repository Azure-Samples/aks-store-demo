import time  # Certifique-se de ter importado a biblioteca time

def main():
    # Adicione uma mensagem de log única
    print(f"[INFO] Serviço virtual-customer iniciado às {datetime.now()}")

    # Configurações de ambiente
    order_service_url = os.getenv("ORDER_SERVICE_URL", "http://localhost:3000")
    orders_per_hour = int(os.getenv("ORDERS_PER_HOUR", "1"))

    if orders_per_hour == 0:
        print("Por favor, defina a variável de ambiente ORDERS_PER_HOUR")
        return

    print(f"Pedidos a serem enviados por hora: {orders_per_hour}")

    # Cálculo do intervalo entre os envios em segundos
    order_submission_interval = 3600 / orders_per_hour
    print(f"Intervalo entre pedidos: {order_submission_interval} segundos")

    order_counter = 0
    start_time = datetime.now()

    while True:
        order_counter += 1

        # Geração de dados do pedido
        customer_id = str(random.randint(1000000000, 2147483647))
        number_of_items = random.randint(1, 5)

        items = [
            {
                "productId": random.randint(1, 10),
                "quantity": random.randint(1, 5),
                "price": round(random.uniform(1.0, 100.0), 2)
            }
            for _ in range(number_of_items)
        ]

        order = {
            "customerId": customer_id,
            "items": items
        }

        # Serialização para JSON
        serialized_order = json.dumps(order)

        # Envio do pedido ao serviço remoto
        try:
            response = requests.post(
                order_service_url,
                headers={"Content-Type": "application/json"},
                data=serialized_order
            )

            # Processamento da resposta
            elapsed_time = (datetime.now() - start_time).total_seconds()
            if response.ok:
                print(
                    f"[INFO] Pedido {order_counter} enviado em {elapsed_time:.2f} segundos "
                    f"com status {response.status_code}. {serialized_order}"
                )
            else:
                print(f"[ERROR] Falha ao enviar o pedido: {response.status_code} - {response.text}")

        except requests.RequestException as e:
            print(f"[ERROR] Erro ao enviar o pedido: {e}")

        # Pausa entre os envios
        time.sleep(order_submission_interval)

if __name__ == "__main__":
    main()
