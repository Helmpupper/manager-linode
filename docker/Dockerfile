# syntax=docker/dockerfile:1.7

# ---------- Stage 1: dependencies & build ----------
ARG NODE_VERSION=22.19
ARG PNPM_VERSION=10.2.0

FROM node:${NODE_VERSION}-bookworm-slim AS builder

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV CI=1

ARG PNPM_VERSION
RUN corepack enable \
 && corepack prepare pnpm@${PNPM_VERSION} --activate

WORKDIR /app

# Copy workspace manifests first for better layer caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY .npmrc* ./
COPY packages/ ./packages/
COPY scripts/ ./scripts/

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile

# Build-time env baked into the bundle (Vite inlines REACT_APP_*).
# Real values are injected at runtime via entrypoint.sh.
ARG REACT_APP_CLIENT_ID=__RUNTIME__
ARG REACT_APP_API_ROOT=https://api.linode.com/v4
ARG REACT_APP_LOGIN_ROOT=https://login.linode.com
ARG REACT_APP_LAUNCH_DARKLY_ID=
ARG REACT_APP_DISABLE_NEW_RELIC=true
ARG REACT_APP_APP_ROOT=http://localhost:3000

ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID \
    REACT_APP_API_ROOT=$REACT_APP_API_ROOT \
    REACT_APP_LOGIN_ROOT=$REACT_APP_LOGIN_ROOT \
    REACT_APP_LAUNCH_DARKLY_ID=$REACT_APP_LAUNCH_DARKLY_ID \
    REACT_APP_DISABLE_NEW_RELIC=$REACT_APP_DISABLE_NEW_RELIC \
    REACT_APP_APP_ROOT=$REACT_APP_APP_ROOT

RUN pnpm run --filter @linode/validation build \
 && pnpm run --filter @linode/api-v4 build \
 && pnpm run --filter linode-manager build

# ---------- Stage 2: runtime (nginx) ----------
FROM nginx:1.27-alpine AS runtime

COPY --from=builder /app/packages/manager/build/ /usr/share/nginx/html/
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint.sh /docker-entrypoint.d/40-runtime-env.sh
RUN chmod +x /docker-entrypoint.d/40-runtime-env.sh

LABEL org.opencontainers.image.source="https://github.com/Helmpupper/manager-linode" \
      org.opencontainers.image.title="manager-linode" \
      org.opencontainers.image.description="Dockerized Akamai/Linode Cloud Manager fork" \
      org.opencontainers.image.licenses="Apache-2.0"

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost/healthz || exit 1
