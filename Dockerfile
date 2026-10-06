# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# open-code-review — build-lane dev container (A2A build lane, node-ph-02).
# Stage 1 builds the `opencodereview` binary with the pinned Go toolchain;
# stage 2 is a slim runtime (git + CA certs — reviews shell out to git).
# Dispatched via the A2A build lane: descriptor v0.1, docs/build-lane.md.
# ---------------------------------------------------------------------------

FROM golang:1.25.5-bookworm AS build
ENV CGO_ENABLED=0
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
ARG GIT_COMMIT=unknown
RUN go build -trimpath \
      -ldflags "-s -w -X main.Version=${VERSION} -X main.GitCommit=${GIT_COMMIT}" \
      -o /out/opencodereview ./cmd/opencodereview

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/opencodereview /usr/local/bin/opencodereview
ENTRYPOINT ["opencodereview"]
CMD ["--version"]
