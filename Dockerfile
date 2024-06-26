FROM --platform=$BUILDPLATFORM rust:1.76.0-slim-buster@sha256:fa8fea738b02334822a242c8bf3faa47b9a98ae8ab587da58d6085ee890bbc33 as planner
WORKDIR /app
RUN cargo install cargo-chef --locked
COPY Cargo.toml Cargo.toml
COPY Cargo.lock Cargo.lock
RUN cargo chef prepare --recipe-path recipe.json

FROM --platform=$BUILDPLATFORM planner AS cacher
WORKDIR /app
COPY --from=planner /app/recipe.json recipe.json
RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config=0.29-6 libssl-dev=1.1.1n-0+deb10u6 \
    && rm -rf /var/lib/apt/lists/*
RUN cargo chef cook --release --recipe-path recipe.json

FROM --platform=$BUILDPLATFORM rust:1.76.0-slim-buster@sha256:fa8fea738b02334822a242c8bf3faa47b9a98ae8ab587da58d6085ee890bbc33 AS builder
WORKDIR /app
COPY . .
RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config=0.29-6 libssl-dev=1.1.1n-0+deb10u6 \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y wget unzip

# Install protoc from source
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v26.0/protoc-26.0-linux-x86_64.zip && \
    unzip protoc-26.0-linux-x86_64.zip -d /usr/local && \
    rm protoc-26.0-linux-x86_64.zip

COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

FROM --platform=$BUILDPLATFORM gcr.io/distroless/cc-debian11
LABEL org.opencontainers.image.source=https://github.com/TidyBee/tidybee-agent
WORKDIR /app
COPY --from=builder /app/config /app/config
COPY --from=builder /app/tests/assets /app/tests/assets
COPY --from=builder /app/target/release/tidybee-agent /app/tidybee-agent
COPY --from=builder /usr/local/bin/protoc /usr/local/bin/protoc
COPY --from=builder /usr/local/include/google /usr/local/include/google
ENV TIDY_ENV=docker

CMD ["/app/tidybee-agent"]
