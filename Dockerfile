FROM hexpm/elixir:1.18.4-erlang-28.0.1-debian-bookworm-20250630-slim as build

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential npm

# Set environment
ENV MIX_ENV=prod
WORKDIR /app

# Install Hex + Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix files and install deps
COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the rest of the app
COPY . .

# Build assets
# RUN cd assets && npm install && npm run build
RUN mix assets.deploy

# Compile the app
RUN mix compile

# Prepare release
RUN mix release

# ---
# Production image
FROM debian:bookworm-slim AS app
RUN apt-get update && apt-get install -y libssl-dev openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app

ENV LANG=C.UTF-8
ENV REPLACE_OS_VARS=true
ENV DATABASE_PATH=/app/email_collector_prod.db

COPY --from=build /app/_build/prod/rel/email_collector ./
COPY --from=build /app/priv/static ./priv/static

VOLUME ["/app"]

EXPOSE 4000

CMD ["bin/email_collector", "start"] 
