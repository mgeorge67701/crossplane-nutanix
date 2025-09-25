FROM golang:1.24-alpine AS builder

WORKDIR /workspace

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o provider ./cmd/provider

FROM alpine:3.19

COPY --from=builder /workspace/provider /provider

RUN addgroup -S crossplane && adduser -S crossplane -G crossplane
USER crossplane

ENTRYPOINT ["/provider"]

CMD ["--debug"]