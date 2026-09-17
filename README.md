# woodpecker-reviewdog-phpcs

Woodpecker CI plugin that runs [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer) with [Reviewdog](https://github.com/reviewdog/reviewdog) and reports findings to GitHub.

Based on [`mikebronner/action-reviewdog-phpcs`](https://github.com/mikebronner/action-reviewdog-phpcs).

## Usage

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

`github-pr-review` posts inline GitHub PR comments as the token's identity. Use this step on `pull_request` events so Woodpecker sets `CI_COMMIT_PULL_REQUEST`.

## Images

| Tag | PHP |
| --- | --- |
| `njaaazi/woodpecker-reviewdog-phpcs:8.3` | 8.3 |
| `njaaazi/woodpecker-reviewdog-phpcs:8.4` | 8.4 |
| `njaaazi/woodpecker-reviewdog-phpcs:8.5` | 8.5 |
| `njaaazi/woodpecker-reviewdog-phpcs:latest` | 8.5 |

## Settings

Store `github_token` using [Woodpecker secrets](https://woodpecker-ci.org/docs/usage/secrets).

| Setting | Default | Description |
| --- | --- | --- |
| `github_token` | _none_ | GitHub PAT (`repo` / `public_repo`) or GitHub App installation token. Required unless `reporter` is `local`. |
| `level` | `warning` | Reviewdog report level: `info`, `warning`, `error`. |
| `reporter` | `github-pr-review` | Reviewdog reporter: `github-pr-review`, `github-pr-check`, `github-check`. |
| `standard` | `PSR1,PSR2,PSR12` | PHPCS coding standard or path to a ruleset. |
| `target_directory` | `src` | Directory to scan. |
| `executable` | `/usr/local/bin/phpcs.phar` | PHPCS executable. Override for a project-local binary. |

`github-pr-review` works with a PAT. `github-check` and `github-pr-check` use the GitHub Checks API and need an App installation token.

## License

MIT.
