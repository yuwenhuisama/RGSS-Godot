FROM ubuntu:24.04
COPY --from=rgss-linux-godot-verified:local /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
RUN sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g; s|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends libfontconfig1 libicu74 \
    && rm -rf /var/lib/apt/lists/*
