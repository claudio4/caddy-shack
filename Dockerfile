FROM docker.io/library/golang:1.26.4@sha256:11fd8f7f63db3b6fb198797042ba4c40a4a34dc83325d3328ca3bc4bb7726786 AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./

RUN CGO_ENABLED=0 go build \
    -ldflags="-w -s" \
    -trimpath -tags nobadger,nomysql,nopgx \
    -o /usr/bin/caddy \
    main.go

# We create the required directories here to later copy them because we can't directly create
# them in a distroless image as there is no coreutils.
RUN mkdir -p /config /data /etc/caddy

FROM gcr.io/distroless/static-debian13:nonroot@sha256:963fa6c544fe5ce420f1f54fb88b6fb01479f054c8056d0f74cc2c6000df5240

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY --from=builder --chown=nonroot:nonroot /config /config
COPY --from=builder --chown=nonroot:nonroot /data /data
COPY --from=builder --chown=nonroot:nonroot /etc/caddy /etc/caddy

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data
VOLUME /config
VOLUME /data

LABEL org.opencontainers.image.title="Caddy Shack"
LABEL org.opencontainers.image.description="Distroless Caddy image with Caddy OIDC and CF DNS"
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source="https://github.com/claudio4/caddy-shack"

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
