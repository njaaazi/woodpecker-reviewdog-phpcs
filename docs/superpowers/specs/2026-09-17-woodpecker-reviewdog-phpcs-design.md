# Woodpecker Reviewdog PHPCS Plugin — Design

Date: 2026-09-17

## Goal

Ship a Woodpecker CI plugin that runs PHP_CodeSniffer and posts findings to GitHub the same way `njaaazi/action-reviewdog-phpcs` does as a GitHub Action. New GitHub repo: `njaaazi/woodpecker-reviewdog-phpcs`. Docker image: `njaaazi/woodpecker-reviewdog-phpcs`.

This is a sibling of `njaaazi/laravel-forge-woodpecker`, not a second remote on the existing Action repo.

## Non-goals

- Dual GitHub Action + Woodpecker image
- Gitea, GitLab, Forgejo, or Bitbucket reporters
- Minting GitHub App installation tokens inside the plugin
- Live GitHub-comment tests in CI (needs a real PR and token)

## Architecture

One Docker plugin. Woodpecker `settings:` become `PLUGIN_*` environment variables. Entrypoint runs PHPCS in checkstyle mode and pipes output to Reviewdog. Reviewdog talks to the GitHub API using `REVIEWDOG_GITHUB_API_TOKEN`.

Layout matches `laravel-forge-woodpecker`:

- `Dockerfile`
- `entrypoint.sh`
- `README.md`
- `docs.md` (Woodpecker plugin-index metadata)
- `LICENSE` (MIT, copyright njaaazi, year 2026)
- `.gitignore` (`.DS_Store`, `.idea/`, `.vscode/`, `*.swp`)
- `.github/workflows/docker.yml` (build and push image tags)

No `action.yml`.

## Images and PHP versions

One Dockerfile parameterized with `ARG PHP_VERSION`.

| Tag | Base image |
| --- | --- |
| `8.3` | `php:8.3-alpine` |
| `8.4` | `php:8.4-alpine` |
| `8.5` | `php:8.5-alpine` |
| `latest` | same image as `8.5` |

Also install:

- `git` (apk) for `git diff` and `safe.directory`
- Reviewdog latest via `https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh` with empty `REVIEWDOG_VERSION` (same as the Action)
- PHPCS phar from `https://github.com/PHPCSStandards/PHP_CodeSniffer/releases/latest/download/phpcs.phar` to `/usr/local/bin/phpcs.phar` (Mike Bronner commit `3f0502747a2bf5afa4a5df0ab2cba3315697b489`; do not use the old Squizlabs URL)

Default `PLUGIN_EXECUTABLE` is `/usr/local/bin/phpcs.phar`.

## Settings

All configuration is `settings:` only. Do not require `environment:` or a specific secret name beyond `from_secret`.

| Setting | Env var | Default | Required |
| --- | --- | --- | --- |
| `github_token` | `PLUGIN_GITHUB_TOKEN` | none | yes, except when `reporter` is `local` |
| `level` | `PLUGIN_LEVEL` | `warning` | no |
| `reporter` | `PLUGIN_REPORTER` | `github-pr-review` | no |
| `standard` | `PLUGIN_STANDARD` | `PSR1,PSR2,PSR12` | no |
| `target_directory` | `PLUGIN_TARGET_DIRECTORY` | `src` | no |
| `executable` | `PLUGIN_EXECUTABLE` | `/usr/local/bin/phpcs.phar` | no |

`github_token` is a Woodpecker secret (`from_secret`). It may be a PAT (`repo` / `public_repo`) or a GitHub App installation token. The plugin does not mint App tokens. Callers who want Checks API reporters (`github-check`, `github-pr-check`) must pass an installation token; a PAT is enough for `github-pr-review`.

Allowed `level` values: `info`, `warning`, `error`.

Allowed `reporter` values: `github-pr-review`, `github-pr-check`, `github-check`. Default is `github-pr-review` so a PAT posts inline PR comments.

## Runtime flow

1. If `CI_WORKSPACE` is set, `cd` there and `git config --global --add safe.directory` on that path. (Woodpecker analogue of the Action’s `GITHUB_WORKSPACE` handling.)
2. Apply defaults for unset `PLUGIN_LEVEL`, `PLUGIN_REPORTER`, `PLUGIN_STANDARD`, `PLUGIN_TARGET_DIRECTORY`, `PLUGIN_EXECUTABLE`.
3. If `PLUGIN_GITHUB_TOKEN` is empty and `PLUGIN_REPORTER` is not `local`, print that `github_token` is required and exit `1`.
4. If a token is present, export `REVIEWDOG_GITHUB_API_TOKEN="$PLUGIN_GITHUB_TOKEN"`.
5. Run:

```sh
php -d memory_limit=-1 ${PLUGIN_EXECUTABLE} --report=checkstyle --standard=${PLUGIN_STANDARD} ${PLUGIN_TARGET_DIRECTORY} -q \
  | reviewdog -name=PHPCS -f=checkstyle -reporter=${PLUGIN_REPORTER} -level=${PLUGIN_LEVEL} -diff='git diff' -tee
```

6. Script uses `set -e` and **no** `pipefail`, matching the GitHub Action: the pipe’s exit status is Reviewdog’s. Findings at or above `level` fail the step.

Do not map extra CI variables. Reviewdog already reads Woodpecker: `CI_REPO_OWNER`, `CI_REPO_NAME`, `CI_COMMIT_SHA`, `CI_COMMIT_PULL_REQUEST`, `CI_COMMIT_BRANCH`.

## GitHub comments

With `reporter: github-pr-review` on a `pull_request` event, Reviewdog posts inline GitHub PR review comments as the token’s identity.

- Requires `CI_COMMIT_PULL_REQUEST` (Woodpecker sets this only for pull-request pipelines).
- On `push`, `github-pr-review` has no PR to attach to. Document that this step should use `when: event: pull_request`, or switch to `github-check` with an App installation token.
- Comments appear as the token user, not `github-actions[bot]`.

## Consumer usage

```yaml
steps:
  phpcs:
    image: njaaazi/woodpecker-reviewdog-phpcs:8.4
    settings:
      github_token:
        from_secret: github_token
      level: warning
      reporter: github-pr-review
      standard: PSR1,PSR2,PSR12
      target_directory: src
    when:
      event: pull_request
```

Pin `:8.3`, `:8.4`, or `:8.5` to match the project PHP version. `:latest` tracks 8.5.

## Publishing

GitHub Actions workflow on this plugin repo (not Woodpecker) builds a matrix of `8.3`, `8.4`, `8.5` and pushes to Docker Hub as `njaaazi/woodpecker-reviewdog-phpcs`. After the three version tags succeed, tag the 8.5 image as `latest`.

Trigger: push to `main` and version tags. Secrets on the repo: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`. After the matrix builds, retag the already-built `8.5` image as `latest` and push (do not rebuild a fourth image).

## Testing

- Build each PHP tag locally (`docker build --build-arg PHP_VERSION=8.3|8.4|8.5`).
- Smoke-run with `PLUGIN_REPORTER=local` and a fixture PHP file so no GitHub token is required. Assert PHPCS/Reviewdog run and print findings.
- Do not automate live GitHub comment posting. Manual check: run the plugin on a real Woodpecker `pull_request` pipeline and confirm comments on the GitHub PR.

## Docs

`docs.md` front matter for the Woodpecker plugin index:

- `name`: Reviewdog PHPCS
- `description`: Run PHP_CodeSniffer with Reviewdog and report to GitHub
- `author`: Njazi Shehu
- `tags`: `[php, phpcs, reviewdog, lint]`
- `containerImage`: `njaaazi/woodpecker-reviewdog-phpcs`
- `url`: `https://github.com/njaaazi/woodpecker-reviewdog-phpcs`

README covers settings table, the three PHP tags, token vs reporter notes, and copy-paste Woodpecker YAML. Same tone as `laravel-forge-woodpecker`.
