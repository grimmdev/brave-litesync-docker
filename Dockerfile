FROM golang:1.25-alpine AS builder

RUN apk add --no-cache gcc musl-dev

WORKDIR /src

COPY litesync/go.mod litesync/go.sum ./
RUN go mod download

COPY litesync/ .

RUN CGO_ENABLED=1 GOOS=linux go build -o /out/litesync ./cmd/litesync

FROM alpine:3.20

RUN apk add --no-cache ca-certificates && \
    addgroup -S litesync && \
    adduser -S -G litesync -s /sbin/nologin litesync

COPY --from=builder /out/litesync /usr/local/bin/litesync

RUN mkdir -p /data && chown litesync:litesync /data
USER litesync

EXPOSE 8295
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/litesync"]
CMD ["-bind", "0.0.0.0:8295", "-db", "/data/litesync.sqlite"]