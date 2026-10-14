#!/bin/sh
set -e

if [ -n "${CI_WORKSPACE}" ]; then
    cd "${CI_WORKSPACE}" || exit
    git config --global --add safe.directory "${CI_WORKSPACE}" || exit 1
fi

PLUGIN_LEVEL="${PLUGIN_LEVEL:-warning}"
PLUGIN_REPORTER="${PLUGIN_REPORTER:-github-pr-review}"
PLUGIN_STANDARD="${PLUGIN_STANDARD:-PSR1,PSR2,PSR12}"
PLUGIN_TARGET_DIRECTORY="${PLUGIN_TARGET_DIRECTORY:-src}"
PLUGIN_EXECUTABLE="${PLUGIN_EXECUTABLE:-/usr/local/bin/phpcs.phar}"
PLUGIN_FAIL_ON_ERROR="${PLUGIN_FAIL_ON_ERROR:-false}"

if [ -z "${PLUGIN_GITHUB_TOKEN}" ] && [ "${PLUGIN_REPORTER}" != "local" ]; then
    echo "github_token is required. Pass it via settings with from_secret."
    exit 1
fi

if [ -n "${PLUGIN_GITHUB_TOKEN}" ]; then
    export REVIEWDOG_GITHUB_API_TOKEN="${PLUGIN_GITHUB_TOKEN}"
fi

FAIL_LEVEL_ARGS=""
if [ "${PLUGIN_FAIL_ON_ERROR}" = "true" ]; then
    FAIL_LEVEL_ARGS="-fail-level=any"
fi

set +e
php -d memory_limit=-1 -d display_errors=stderr ${PLUGIN_EXECUTABLE} --report=checkstyle --standard=${PLUGIN_STANDARD} ${PLUGIN_TARGET_DIRECTORY} -q > /tmp/lint.out
LINT_EXIT=$?
set -e

# phpcs: 0 = clean, 1-3 = findings, anything else = crash or config error
if [ "${LINT_EXIT}" -gt 3 ]; then
    cat /tmp/lint.out
    echo "phpcs failed with exit code ${LINT_EXIT}"
    exit 1
fi

reviewdog -name=PHPCS -f=checkstyle -reporter=${PLUGIN_REPORTER} ${FAIL_LEVEL_ARGS} -level=${PLUGIN_LEVEL} -diff='git diff' -tee < /tmp/lint.out
