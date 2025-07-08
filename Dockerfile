FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY bin/provider /manager
USER 65532:65532

ENTRYPOINT ["/manager"]
