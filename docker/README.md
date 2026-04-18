# Docker

Production Docker image for `manager-linode`. Multi-stage pnpm build,
served by `nginx:alpine` with runtime env injection.

## Quick start

```sh
cp docker/.env.example docker/.env
# edit docker/.env — at minimum set REACT_APP_CLIENT_ID

docker compose -f docker/docker-compose.yml --env-file docker/.env up -d --build
```

Open <http://localhost:3000>.

## Build manually

```sh
# From repo root
docker build \
  -f docker/Dockerfile \
  -t ghcr.io/helmpupper/manager-linode:dev \
  --build-arg REACT_APP_CLIENT_ID=your-oauth-client-id \
  .
```

## Run manually

```sh
docker run --rm -p 3000:80 \
  -e REACT_APP_CLIENT_ID=your-oauth-client-id \
  -e REACT_APP_API_ROOT=https://api.linode.com/v4 \
  -e REACT_APP_LOGIN_ROOT=https://login.linode.com \
  -e REACT_APP_APP_ROOT=http://localhost:3000 \
  ghcr.io/helmpupper/manager-linode:dev
```

## Environment variables

| Variable | Purpose | Default |
|---|---|---|
| `REACT_APP_CLIENT_ID` | OAuth client ID from cloud.linode.com/profile/clients | _required_ |
| `REACT_APP_API_ROOT` | Linode API base URL | `https://api.linode.com/v4` |
| `REACT_APP_LOGIN_ROOT` | Login service URL | `https://login.linode.com` |
| `REACT_APP_APP_ROOT` | Public URL where the app is served | `http://localhost:3000` |
| `REACT_APP_LAUNCH_DARKLY_ID` | LaunchDarkly client ID (optional) | — |
| `REACT_APP_DISABLE_NEW_RELIC` | Disable New Relic RUM | `true` |

## Runtime vs build-time configuration

Vite inlines `REACT_APP_*` at build time. Two patterns are supported:

1. **Build-time:** pass values as `--build-arg` or via compose `build.args`.
2. **Runtime (one image, many envs):** build with the `__RUNTIME__` sentinel.
   The entrypoint rewrites those sentinels in the bundle and writes
   `/runtime-env.js` exposing `window.__ENV__`.

## Healthcheck

`GET /healthz` returns `200 ok`.
