ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-alpine

ENV REVIEWDOG_VERSION=

RUN apk --no-cache add git
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}
RUN wget -q https://github.com/PHPCSStandards/PHP_CodeSniffer/releases/latest/download/phpcs.phar -O /usr/local/bin/phpcs.phar

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
