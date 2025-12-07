#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

# Best-effort migrations (DB might need a moment on cold start)
if [ -f artisan ]; then
  for i in {1..5}; do
    if php artisan migrate --force; then
      break
    fi
    echo "Migration attempt ${i} failed, retrying in 3s..." >&2
    sleep 3
  done
fi

exec apache2-foreground
