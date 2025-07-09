# Use an official Golang runtime as a parent image
FROM golang:1.23-alpine AS builder

# Set the working directory to /app
WORKDIR /app

# Set the build argument for the app version number
ARG APP_VERSION=0.1.0

# Copy the current directory contents into the container at /app
COPY . /app

# Build the Go app
RUN go build -ldflags "-X main.version=$APP_VERSION" -o main .

# Run the app on alpine
FROM alpine:latest AS runner

ARG APP_VERSION=0.1.0

# Copy the build output from the builder container
COPY --from=builder /app/main .

# Expose port 3001 for the container
EXPOSE 3001

# Set the environment variable for the app version number
ENV APP_VERSION=$APP_VERSION

# Run the Go app when the container starts
CMD ["./main"]