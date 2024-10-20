# Use a base Python image
FROM python:3.9-slim

# Install the necessary dependencies
RUN pip install grpcio grpcio-tools

# Copy the service files
COPY . /app

# Set the working directory
WORKDIR /app

# Generate Python files from the Protobuf
RUN python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. product_service.proto

# Run the gRPC server
CMD ["python", "server.py"]