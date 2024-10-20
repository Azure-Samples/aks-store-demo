from concurrent import futures
import grpc
import product_service_pb2
import product_service_pb2_grpc

class ProductService(product_service_pb2_grpc.ProductServiceServicer):
    def GetProduct(self, request, context):
        return product_service_pb2.ProductResponse(
            id=request.id,
            name="Product Name",
            description="Product Description",
            price=99.99
        )

    def ListProducts(self, request, context):
        # Implementação do método ListProducts
        products = [
            product_service_pb2.Product(id="1", name="Product 1", description="Description 1", price=10.0),
            product_service_pb2.Product(id="2", name="Product 2", description="Description 2", price=20.0)
        ]
        return product_service_pb2.ProductListResponse(products=products)


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    product_service_pb2_grpc.add_ProductServiceServicer_to_server(ProductService(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
