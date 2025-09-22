# Use Alpine for better Docker compatibility with ENTRYPOINT

# Use build ARG to set architecture
ARG TARGETARCH
FROM golang:1.24-alpine AS builder

WORKDIR /workspace

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary for the target architecture
RUN CGO_ENABLED=0 GOARCH=${TARGETARCH:-amd64} go build -a -ldflags '-extldflags "-static"' -o provider ./cmd/provider

# Use a smaller base image for the final container

FROM alpine:3.19


# Copy the binary from the builder stage
COPY --from=builder /workspace/provider /provider

# Make the binary executable
RUN chmod +x /provider

# Set very explicit ENTRYPOINT and CMD (fixing "no command specified" error)
ENTRYPOINT ["/provider"]
CMD ["--debug"]
