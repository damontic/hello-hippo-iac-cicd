# Build stage
FROM golang:1.22.4-alpine3.20 as builder

# Define build arguments with default values
ARG VERSION=dev
ARG COMMIT=none
ARG DATE=none

RUN echo "$VERSION" | grep -E '[[:digit:]]+.[[:digit:]]+.[[:digit:]]+' || (echo VERSION $VERSION build-arg has an incorrect format && false)
RUN test "$COMMIT" != "none" || (echo "COMMIT must be specified as a build arg" && false)
RUN test "$DATE" != "none" || (echo "DATE must be specified as a build arg" && false)

# Set the working directory inside the builder container
WORKDIR /app

# Copy the Go application source code into the container
COPY --from=src . .

# Build the Go application with the build arguments
RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags \
    "-X main.Version=${VERSION} -X main.Commit=${COMMIT} -X main.Date=${DATE}" \
    -o golang-app

# Final stage
FROM alpine:3.20

# Set the working directory inside the final container
WORKDIR /root/

# Copy the compiled Go binary from the builder stage
COPY --from=builder /app/golang-app .
COPY --from=builder /app/templates ./templates

# Command to run the binary
ENTRYPOINT ["./golang-app"]
