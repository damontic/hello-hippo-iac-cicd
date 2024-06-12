# Build stage
FROM golang:1.22.4-alpine3.20 as builder

# Define build arguments with default values
ARG VERSION=dev
ARG COMMIT=none
ARG DATE=unknown

# Set the working directory inside the builder container
WORKDIR /app

# Copy the Go application source code into the container
COPY . .

# Build the Go application with the build arguments
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.Version=${VERSION} -X main.Commit=${COMMIT} -X main.Date=${DATE}" -o myapp

# Final stage
FROM alpine:3.20

# Set the working directory inside the final container
WORKDIR /root/

# Copy the compiled Go binary from the builder stage
COPY --from=builder /app/myapp .

# Command to run the binary
CMD ["./myapp"]
