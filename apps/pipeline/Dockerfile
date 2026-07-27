FROM golang:1.26-alpine AS builder

WORKDIR /build
COPY go.mod .
COPY main.go .

RUN go build -o /pipeline .

FROM alpine:3.20

RUN adduser -D -u 10001 appuser

COPY --from=builder /pipeline /usr/local/bin/pipeline

USER 10001

ENTRYPOINT ["pipeline"]
