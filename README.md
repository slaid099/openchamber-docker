# OpenChamber Docker image

Public image with OpenChamber, OpenCode CLI, `uv`, `gh` and Telethon.

- Image: `ghcr.io/slaid099/openchamber:latest`
- Platforms: `linux/amd64`
- Base: `oven/bun:1.4.4`
- User: `openchamber` (UID/GID `1000`)

The image only contains the runtime. Config, sessions, SSH keys and tokens
live in volumes on the host.

## Update

```bash
cd /root/dockers/openchamber
docker compose pull
docker compose up -d
```

Downtime is only the container recreate, normally 10–20 seconds.

## Rollback

Before an update, tag the current image:

```bash
docker tag ghcr.io/slaid099/openchamber:latest openchamber:rollback
```

If the new version is bad:

```bash
docker tag openchamber:rollback ghcr.io/slaid099/openchamber:latest
docker compose up -d --force-recreate
```

## Compose example

```yaml
services:
  openchamber:
    image: ghcr.io/slaid099/openchamber:latest
    pull_policy: always
    container_name: openchamber
    ports:
      - "0.0.0.0:3000:3000"
    mem_limit: 4g
    cpus: 3.0
    restart: unless-stopped
    environment:
      OPENCHAMBER_UI_PASSWORD: ${OPENCHAMBER_UI_PASSWORD:?Set OPENCHAMBER_UI_PASSWORD in .env}
      FORGEJO_TOKEN: ${FORGEJO_TOKEN:?Set FORGEJO_TOKEN in .env}
      GITHUB_TOKEN: ${GITHUB_TOKEN:?Set GITHUB_TOKEN in .env}
      ANTIDETECT_BROWSER_MCP_URL: ${ANTIDETECT_BROWSER_MCP_URL:-http://80.85.139.21:8765/mcp}
      GIT_CONFIG_GLOBAL: /home/openchamber/workspaces/.gitconfig
      TZ: Europe/Moscow
      OPENCHAMBER_ALLOW_REMOTE_OPENAI_COMPAT_URLS: ${OPENCHAMBER_ALLOW_REMOTE_OPENAI_COMPAT_URLS:-true}
    volumes:
      - ./app_data/openchamber:/home/openchamber/.config/openchamber
      - ./app_data/opencode/config:/home/openchamber/.config/opencode
      - ./app_data/opencode/share:/home/openchamber/.local/share/opencode
      - ./app_data/opencode/state:/home/openchamber/.local/state/opencode
      - ./app_data/ssh:/home/openchamber/.ssh
      - ./app_data/workspace:/home/openchamber/workspaces
      - ./app_data/telegram:/home/openchamber/.claude/telegram
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

## Build locally

```bash
docker build -t openchamber:local .
```
