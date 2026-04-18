#!/bin/sh
set -eu

HTML_DIR="${HTML_DIR:-/usr/share/nginx/html}"
RUNTIME_ENV_FILE="${HTML_DIR}/runtime-env.js"

RUNTIME_VARS="
REACT_APP_CLIENT_ID
REACT_APP_API_ROOT
REACT_APP_LOGIN_ROOT
REACT_APP_APP_ROOT
REACT_APP_LAUNCH_DARKLY_ID
REACT_APP_DISABLE_NEW_RELIC
"

echo "[entrypoint] Writing ${RUNTIME_ENV_FILE}"

{
  echo "// Auto-generated at container start. Do not edit."
  echo "window.__ENV__ = window.__ENV__ || {};"
  for var in $RUNTIME_VARS; do
    val=$(eval "printf '%s' \"\${$var:-}\"")
    esc=$(printf '%s' "$val" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    echo "window.__ENV__.${var} = \"${esc}\";"
  done
} > "$RUNTIME_ENV_FILE"

if [ -n "${REACT_APP_CLIENT_ID:-}" ]; then
  echo "[entrypoint] Substituting __RUNTIME__ -> REACT_APP_CLIENT_ID"
  find "$HTML_DIR" -type f \( -name '*.js' -o -name '*.html' \) \
    -exec sed -i "s|__RUNTIME__|${REACT_APP_CLIENT_ID}|g" {} +
fi

echo "[entrypoint] Done."
