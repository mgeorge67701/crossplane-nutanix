FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY provider /manager
USER 65532:65532

ENTRYPOINT ["/manager"]
