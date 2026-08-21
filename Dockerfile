FROM docker.io/library/golang:1.27rc3@sha256:6a284ec7a8c67eff5882aaa53b07a57ee397553f8c85a92e5fc97c517f12201f AS builder

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

FROM gcr.io/distroless/static-debian13:nonroot@sha256:1c2c046bc09ed40fad370b599a0b1ae7987f55b01e247cf27a7c27cd97e5bbc7

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
