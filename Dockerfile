# Multi-stage build for multi-architecture support
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG BUILDPLATFORM

WORKDIR /workspace

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary for the target platform
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -ldflags '-extldflags "-static"' -o provider ./cmd/provider

# Final stage
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/provider /manager
USER 65532:65532

ENTRYPOINT ["/manager"]
