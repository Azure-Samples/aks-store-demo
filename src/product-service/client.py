import grpc
from product_service_pb2 import ProductRequest
from product_service_pb2_grpc import ProductServiceStub

def get_product_details(product_id):
    with grpc.insecure_channel('localhost:50051') as channel:
        stub = ProductServiceStub(channel)
        response = stub.GetProduct(ProductRequest(id=product_id))
        return response

def list_products():
    with grpc.insecure_channel('localhost:50051') as channel:
        stub = ProductServiceStub(channel)
        response = stub.ListProducts(Empty())
        return response

def run():
    product_details = get_product_details("123")
    print("Product details:", product_details)
    
    products = list_products()
    print("Product list:", products)

if __name__ == '__main__':
    run()