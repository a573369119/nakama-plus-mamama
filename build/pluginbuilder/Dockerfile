# nakama-plus  pluginbuild 
FROM golang:1.25.0-bookworm AS builder

ARG VERSION
ARG TARGETOS
ARG TARGETARCH

LABEL maintainer="Heroic Labs"
LABEL contact="support@heroiclabs.com"
LABEL version=$VERSION
LABEL variant=nakama-pluginbuilder
LABEL description="A support container to build Go code for Nakama server's runtime."

ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
ENV CGO_ENABLED=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends ca-certificates gcc libc6-dev git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /builder

ENTRYPOINT ["go"]
