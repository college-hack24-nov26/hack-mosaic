# Build stage
FROM golang:1.23-alpine AS builder
WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/pashuvani-server ./cmd/server

# Runtime stage
FROM alpine:3.20
WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && \
    adduser -D -g '' appuser && \
    mkdir -p /app/data/uploads && \
    chown -R appuser:appuser /app

COPY --from=builder /app/pashuvani-server /app/pashuvani-server
COPY --from=builder /app/migrations /app/migrations

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["/app/pashuvani-server"]

