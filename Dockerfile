## Optimized Dockerfile for buildx cache and speed
ARG TARGETOS
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
COPY go.mod go.sum ./

# Build the binary for the target architecture
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH:-amd64} go build -ldflags '-extldflags "-static"' -o bin/${TARGETOS}_${TARGETARCH}/crossplane-nutanix-provider ./cmd/provider

FROM gcr.io/distroless/static@sha256:87bce11be0af225e4ca761c40babb06d6d559f5767fbf7dc3c47f0f1a466b92c

ARG TARGETOS
ARG TARGETARCH

ADD bin/${TARGETOS}_${TARGETARCH}/crossplane-nutanix-provider /usr/local/bin/crossplane-nutanix-provider

USER 65532
ENTRYPOINT ["/usr/local/bin/crossplane-nutanix-provider"]
