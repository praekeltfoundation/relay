###############
# Build stage #
###############

FROM elixir:1.6-alpine AS builder

# FIXME: We need git to fetch some pre-release dependencies
RUN apk add --no-cache git

WORKDIR /build

# We need hex and rebar build tools installed.
RUN mix local.hex --force && mix local.rebar --force

# .dockerignore filters out all the files we don't need.
COPY . .

# Build the release to put in the next image.
ENV MIX_ENV=prod
RUN mix deps.get
RUN mix compile
RUN mix release --env=prod


###############
# Image stage #
###############

# We don't actually need Erlang/Elixir installed, because it's all included in
# the release package. Thus, we start from the base alpine image.
FROM alpine:3.7

# We need bash for the generated scripts, tini for signal propagation, and
# openssl for crypto.
RUN apk add --no-cache bash tini openssl

WORKDIR /app

# Get the release we built earlier from the build container.
COPY --from=builder /build/_build/prod/rel/relay/ ./

# We need runtime write access to /app/var as a non-root user.
RUN addgroup -S relay && adduser -S -g relay -h /app relay
RUN mkdir var && chown relay var

# Run as non-root.
USER relay

# REPLACE_OS_VARS lets us use envvars to configure some runtime parameters.
# Currently we only support using $ERLANG_COOKIE to set the cookie.
ENV REPLACE_OS_VARS=true

# Signals are swallowed by the pile of generated scripts that run the app, so
# we need tini to manage them.
ENTRYPOINT ["tini", "--"]

# By default, run our application in the foreground.
CMD ["./bin/relay", "foreground"]
