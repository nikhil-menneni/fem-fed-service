FROM golang:1.25-alpine AS build

# Install dependencies
RUN apk add --no-cache git gcc musl-dev

# Install goose
RUN go install github.com/pressly/goose/v3/cmd/goose@latest

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .
RUN go build -o main .

# ---- FINAL STAGE ----
FROM --platform=linux/arm64 alpine:latest

ENV DOCKERIZE_VERSION=v0.9.3

RUN apk add --no-cache wget openssl \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apk del wget

WORKDIR /app

COPY --from=build /app/main .
COPY --from=build /go/bin/goose /usr/local/bin/goose
COPY migrations ./migrations
COPY static ./static
COPY templates ./templates

EXPOSE 8080

CMD ["./main"]