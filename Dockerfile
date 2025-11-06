FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder

WORKDIR /workspace

# Install build dependencies
RUN apk add --no-cache git

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH

# Build the provider binary with proper cross-compilation
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o provider ./cmd/provider

FROM --platform=$TARGETPLATFORM alpine:3.20

COPY --from=builder /workspace/provider /provider

RUN addgroup -S crossplane && adduser -S crossplane -G crossplane
USER crossplane

ENTRYPOINT ["/provider"]

CMD ["--debug"]