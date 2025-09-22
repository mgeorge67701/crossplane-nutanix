FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

WORKDIR /workspace

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static"' -o provider ./cmd/provider && chmod +x provider

FROM alpine:3.19

# Copy the binary from the builder stage
COPY --from=builder /workspace/provider /provider

# Set very explicit ENTRYPOINT and CMD (fixing "no command specified" error)
ENTRYPOINT ["/provider"]
CMD ["--debug"]
