## Optimized Dockerfile for buildx cache and speed
ARG TARGETARCH
FROM golang:1.24-alpine AS builder

WORKDIR /workspace

# Cache go mod and sum for faster builds
COPY go.mod go.sum ./
RUN go mod download

# Copy only necessary source files (avoid copying .git, docs, etc.)
COPY apis/ ./apis/
COPY cmd/ ./cmd/
COPY internal/ ./internal/
COPY package/ ./package/
COPY scripts/ ./scripts/
COPY go.mod go.sum ./

# Build the binary for the target architecture
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH:-amd64} go build -ldflags '-extldflags "-static"' -o provider ./cmd/provider

FROM alpine:3.19

# Copy the binary from the builder stage
COPY --from=builder /workspace/provider /provider

# Make the binary executable
RUN chmod +x /provider

ENTRYPOINT ["/provider"]
CMD ["--debug"]
