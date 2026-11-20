# syntax=docker/dockerfile:1
FROM oven/bun:1.4.4

ARG OPENCHAMBER_VERSION=latest
ARG OPENCODE_VERSION=2
ARG GH_VERSION=2.105.0

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
      git \
      less \
      nodejs \
      npm \
      openssh-client \
      python3 \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

# Replace the base image's bun user (UID 1000) with openchamber so mounted
# volumes owned by 1000:1000 keep working.
RUN userdel bun \
    && groupadd -g 1000 openchamber \
    && useradd -u 1000 -g 1000 -m -s /bin/bash openchamber \
    && chown -R openchamber:openchamber /home/openchamber

USER openchamber
WORKDIR /home/openchamber

ENV HOME=/home/openchamber
ENV NPM_CONFIG_PREFIX=/home/openchamber/.npm-global
ENV PATH=/home/openchamber/.npm-global/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin
ENV NODE_ENV=production
ENV LANG=C.UTF-8
ENV OPENCHAMBER_HOST=0.0.0.0

RUN npm config set prefix /home/openchamber/.npm-global \
    && mkdir -p /home/openchamber/.npm-global \
    && npm install -g \
         "@openchamber/web@${OPENCHAMBER_VERSION}" \
         "@opencode/cli@${OPENCODE_VERSION}"

USER root

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv --version

RUN set -eux; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tgz; \
    tar -xzf /tmp/gh.tgz -C /tmp; \
    mv "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh; \
    rm -rf /tmp/gh*; \
    gh --version

RUN uv pip install --system --break-system-packages telethon \
    && python3 -c "import telethon; print(telethon.__version__)"

COPY --chown=openchamber:openchamber scripts/openchamber-entrypoint.sh /home/openchamber/openchamber-entrypoint.sh
RUN chmod +x /home/openchamber/openchamber-entrypoint.sh

USER openchamber
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3000/health || exit 1

ENTRYPOINT ["sh", "/home/openchamber/openchamber-entrypoint.sh"]
CMD ["bun", "/home/openchamber/.npm-global/lib/node_modules/@openchamber/web/build/bin/cli.js", "serve", "--foreground"]
