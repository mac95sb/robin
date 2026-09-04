# Deploy a Persistent Robin Server

Run the release executable as one long-lived service and put TLS termination in a reverse proxy.

## Build and verify the artifact

Run `robin build`. The application executable and `deployment.json` are written beneath
`.robin/build`. Copy the executable, its runtime libraries, and any static assets listed in
`manifest.json` as one release. Keep databases, uploads, logs, and secrets outside `.robin`, because
the next build can replace that directory.

Before switching traffic, start the copied executable and verify its health endpoint:

```sh
./RobinApp &
curl --fail http://127.0.0.1:8080/health
kill -TERM $!
```

Register ``Middleware/health(path:check:)`` and include database, queue, and storage readiness in
the check. Robin drains existing connections when the process receives cancellation. Give the
process manager enough stop time for the longest accepted request.

## Run in a container

Build on the same Linux distribution and architecture used by the runtime image. A minimal
multi-stage container copies only the release executable and required runtime libraries:

```dockerfile
FROM swift:6.3.3-jammy AS build
WORKDIR /src
COPY . .
RUN swift build -c release --static-swift-stdlib && \
    ROBIN_BUILD=1 .build/release/RobinApp

FROM ubuntu:jammy
RUN useradd --system --uid 10001 robin
COPY --from=build /src/.robin/build/RobinApp /usr/local/bin/RobinApp
USER robin
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/RobinApp"]
```

Bind Robin to `0.0.0.0` inside a container. Mount writable application data under `/var/lib/robin`
and inject secrets through the platform's secret store. Do not bake credentials or a production
database into the image.

## Run a bare executable on Linux

Install the binary at `/opt/robin/RobinApp`, store secrets in `/etc/robin/robin.env` with mode
`0600`, and use this systemd unit:

```ini
[Unit]
Description=Robin application
After=network-online.target
Wants=network-online.target

[Service]
User=robin
Group=robin
WorkingDirectory=/var/lib/robin
EnvironmentFile=/etc/robin/robin.env
ExecStart=/opt/robin/RobinApp
Restart=on-failure
KillSignal=SIGTERM
TimeoutStopSec=45
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

After installing or replacing the unit, run `systemctl daemon-reload`, `systemctl enable --now
robin`, and `systemctl status robin`. Validate `/health` locally before enabling the public route.

## Run a bare executable on macOS

Install the binary and a root-owned environment wrapper outside the build directory. The launchd
property list should keep the process alive and send logs to persistent paths:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>dev.robin.app</string>
  <key>ProgramArguments</key>
  <array><string>/opt/robin/RobinApp</string></array>
  <key>WorkingDirectory</key><string>/var/lib/robin</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/var/log/robin.log</string>
  <key>StandardErrorPath</key><string>/var/log/robin-error.log</string>
</dict>
</plist>
```

Load it with `launchctl bootstrap system /Library/LaunchDaemons/dev.robin.app.plist`, then verify
the local health endpoint. Use a wrapper executable or launchd `EnvironmentVariables` only when the
values can be protected; never put secrets in a source-controlled property list.

## Terminate TLS at a reverse proxy

Keep Robin on loopback and let Caddy manage certificates and forwarding:

```caddyfile
example.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:8080
}
```

For nginx, preserve the original host and forwarding information explicitly:

```nginx
server {
  listen 443 ssl http2;
  server_name example.com;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

Configure ``ClientAddressResolver`` only for proxy addresses you control. Do not trust forwarded
headers from arbitrary clients. Apply request-size and timeout limits at both the proxy and
``ServerRuntime``; make the proxy timeout slightly longer than Robin's request timeout so Robin can
return the error response.

## Roll out safely

Build on the deployment platform, inspect `manifest.json` and `deployment.json`, migrate the
database as a separate controlled step, start the new process, verify `/health`, then switch
traffic. Roll back by restoring the previous immutable release; do not roll back a database unless
the migration has a separately tested reverse operation.
