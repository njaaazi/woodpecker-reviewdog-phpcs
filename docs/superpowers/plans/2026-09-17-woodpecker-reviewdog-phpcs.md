# Woodpecker Reviewdog PHPCS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create public GitHub repo `njaaazi/woodpecker-reviewdog-phpcs` with a Woodpecker Docker plugin that runs PHPCS through Reviewdog and reports to GitHub.

**Architecture:** One `Dockerfile` with `ARG PHP_VERSION` producing tags `8.3`, `8.4`, `8.5`, and `latest` (8.5). `entrypoint.sh` reads `PLUGIN_*` settings, runs PHPCS checkstyle, pipes to Reviewdog. GitHub Actions matrix publishes to Docker Hub.

**Tech Stack:** PHP Alpine images, PHP_CodeSniffer phar (PHPCSStandards), Reviewdog, Woodpecker plugin conventions, GitHub Actions + Docker Hub.

## Global Constraints

- Repo: `njaaazi/woodpecker-reviewdog-phpcs` (public GitHub)
- Image: `njaaazi/woodpecker-reviewdog-phpcs`
- Tags: `8.3`, `8.4`, `8.5`; `latest` retags `8.5`
- PHPCS URL: `https://github.com/PHPCSStandards/PHP_CodeSniffer/releases/latest/download/phpcs.phar`
- Settings via `PLUGIN_*` only; required `github_token` except when `reporter=local`
- Default reporter `github-pr-review`; defaults match the GitHub Action
- No `pipefail`; MIT license copyright njaaazi 2026
- Commits use `--no-gpg-sign`

## File structure

- Create: `.gitignore`
- Create: `LICENSE`
- Create: `Dockerfile`
- Create: `entrypoint.sh`
- Create: `tests/fixtures/src/sample.php`
- Create: `tests/smoke.sh`
- Create: `README.md`
- Create: `docs.md`
- Create: `.github/workflows/docker.yml`

---

### Task 1: Plugin runtime (Dockerfile + entrypoint + smoke test)

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `Dockerfile`
- Create: `entrypoint.sh`
- Create: `tests/fixtures/src/sample.php`
- Create: `tests/smoke.sh`

**Interfaces:**
- Consumes: Woodpecker `PLUGIN_*`, `CI_WORKSPACE`
- Produces: Docker image that runs PHPCS | Reviewdog

- [ ] **Step 1: Write fixture and smoke script (fail before image exists)**

`tests/fixtures/src/sample.php`:

```php
<?php
echo "hello";
```

`tests/smoke.sh`:

```sh
#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-woodpecker-reviewdog-phpcs:8.5}"

echo "missing token should fail for default reporter"
if docker run --rm \
  -e PLUGIN_TARGET_DIRECTORY=src \
  "$IMAGE"; then
  echo "expected failure without github_token"
  exit 1
fi

echo "local reporter should run without token"
docker run --rm \
  -v "$ROOT/tests/fixtures:/woodpecker" \
  -e CI_WORKSPACE=/woodpecker \
  -e PLUGIN_REPORTER=local \
  -e PLUGIN_TARGET_DIRECTORY=src \
  -e PLUGIN_LEVEL=info \
  "$IMAGE" || true
```

- [ ] **Step 2: Implement Dockerfile and entrypoint**

Dockerfile uses `ARG PHP_VERSION=8.5`, `php:${PHP_VERSION}-alpine`, git, Reviewdog install.sh, PHPCSStandards phpcs.phar.

entrypoint: cd `CI_WORKSPACE`, defaults, require token unless reporter is `local`, export `REVIEWDOG_GITHUB_API_TOKEN`, phpcs | reviewdog.

- [ ] **Step 3: Build 8.3, 8.4, 8.5 and run smoke against 8.5**

```sh
docker build --build-arg PHP_VERSION=8.3 -t woodpecker-reviewdog-phpcs:8.3 .
docker build --build-arg PHP_VERSION=8.4 -t woodpecker-reviewdog-phpcs:8.4 .
docker build --build-arg PHP_VERSION=8.5 -t woodpecker-reviewdog-phpcs:8.5 .
IMAGE=woodpecker-reviewdog-phpcs:8.5 sh tests/smoke.sh
```

- [ ] **Step 4: Commit** with `--no-gpg-sign`

---

### Task 2: Docs

**Files:**
- Create: `README.md`
- Create: `docs.md`

- [ ] **Step 1: Write README and docs.md** matching laravel-forge-woodpecker tone, spec settings table, PHP tags, token notes, example YAML.
- [ ] **Step 2: Commit** with `--no-gpg-sign`

---

### Task 3: Docker Hub publish workflow + public GitHub repo

**Files:**
- Create: `.github/workflows/docker.yml`

- [ ] **Step 1: Add matrix workflow** building `8.3`/`8.4`/`8.5`, pushing `njaaazi/woodpecker-reviewdog-phpcs:$php`, then retag `8.5` as `latest`. Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.
- [ ] **Step 2: Commit** with `--no-gpg-sign`
- [ ] **Step 3: Create public GitHub repo and push**

```sh
gh repo create njaaazi/woodpecker-reviewdog-phpcs --public --source=. --remote=origin --push --description "Woodpecker CI plugin that runs PHP_CodeSniffer with Reviewdog and reports to GitHub."
```

---
