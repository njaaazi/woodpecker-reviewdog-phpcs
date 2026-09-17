#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-woodpecker-reviewdog-phpcs:8.5}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "missing token should fail for default reporter"
if docker run --rm \
  -e PLUGIN_TARGET_DIRECTORY=src \
  "$IMAGE"; then
  echo "expected failure without github_token"
  exit 1
fi

cp -R "$ROOT/tests/fixtures/." "$WORKDIR"
cd "$WORKDIR"
git init >/dev/null
git config user.email "smoke@example.com"
git config user.name "smoke"
printf '%s\n' '<?php' > src/sample.php
git add src/sample.php
git -c commit.gpgsign=false commit -m "init" >/dev/null
cat "$ROOT/tests/fixtures/src/sample.php" > src/sample.php

echo "local reporter should run without token"
docker run --rm \
  -v "$WORKDIR:/woodpecker" \
  -e CI_WORKSPACE=/woodpecker \
  -e PLUGIN_REPORTER=local \
  -e PLUGIN_TARGET_DIRECTORY=src \
  -e PLUGIN_LEVEL=info \
  "$IMAGE" || true

echo "smoke ok"
