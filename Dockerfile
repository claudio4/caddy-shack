FROM docker.io/library/golang:1.26.5@sha256:079e59808d2d252516e27e3f3a9c003740dee7f75e55aa71528766d52bcfc16a AS builder

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

FROM gcr.io/distroless/static-debian13:nonroot@sha256:d29e660cc75a5b6b1334e03c5c81ccf9bc0884a002c6000dbf0fb96034814478

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
