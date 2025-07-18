FROM hexpm/elixir:1.18.4-erlang-28.0.1-debian-bookworm-20250630-slim AS build

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
ENV DATABASE_PATH=/app/data/email_collector_prod.db  # Point to data directory

COPY --from=build /app/_build/prod/rel/email_collector ./
COPY --from=build /app/priv/static ./priv/static

RUN mkdir -p /app/data  # Create data directory

VOLUME ["/app/data"]  # Only the data directory is a volume
EXPOSE 4000
CMD ["bin/email_collector", "start"]
