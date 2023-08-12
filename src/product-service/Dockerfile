FROM rust:1.70 as builder

RUN USER=root cargo new --bin product-service

# Create a new directory for our application
WORKDIR /product-service

# Copy the Cargo.toml and Cargo.lock files to the container
COPY Cargo.toml Cargo.lock ./

# Build the dependencies and cache them
RUN cargo build --release

# Remove the .rs files created by cargo
RUN rm src/*.rs

# Copy the source files to the container
ADD . ./

# Remove the dummy target directory created by cargo
RUN rm ./target/release/deps/product_service*

# Build the application
RUN cargo build --release

# Create a new stage and copy the binary from the builder stage
FROM debian:bullseye-slim as runner
WORKDIR /app

# Not ideal but needed to execute health checks in docker-compose
RUN apt-get update && apt-get install -y wget

# Copy the binary from the builder stage
COPY --from=builder /product-service/target/release/product-service /app

# Run the application
CMD ["./product-service"]