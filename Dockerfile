FROM hexpm/elixir:1.18.4-erlang-28.0.1-debian-bookworm-20250630-slim AS build

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential npm git ca-certificates locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Set locale environment
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set environment
ENV MIX_ENV=prod
WORKDIR /app

USER root

# Install Hex + Rebar
RUN mix local.hex --force --if-missing
RUN mix local.rebar --force --if-missing

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
ENV DATABASE_PATH=/app/data/email_collector_prod.db

COPY --from=build /app/_build/prod/rel/email_collector ./
COPY --from=build /app/priv/static ./priv/static

RUN mkdir -p /app/data  # Create data directory

VOLUME ["/app/data"]
EXPOSE 4000

CMD ["bin/email_collector", "start"]
