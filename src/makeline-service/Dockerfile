# Use an official Golang runtime as a parent image
FROM golang:1.20.5-alpine as builder

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Build the Go app
RUN go build -o main .

# Run the app on alpine
FROM alpine:latest as runner

# Copy the build output from the builder container
COPY --from=builder /app/main .

# Expose port 3001 for the container
EXPOSE 3001

# Run the Go app when the container starts
CMD ["./main"]