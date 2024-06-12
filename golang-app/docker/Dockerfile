ARG VERSION=dev
ARG COMMIT=none
ARG DATE=unknown

FROM golang:1.22.4-alpine3.20

COPY golang-app /golang-app

WORKDIR /golang-app

RUN go build -ldflags \
    "-X main.Version=1.0.0 \
    -X main.Commit=$(git rev-parse HEAD) \
    -X main.Date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -o golang-app

CMD ./golang-app