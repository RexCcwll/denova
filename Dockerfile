# Denova v0.5.0 自封装镜像 —— 复刻 panda-995/denova 的配方，独立发行
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash ca-certificates curl git python3 \
        chromium fonts-noto-cjk tini tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 denova \
    && useradd --create-home --uid 1000 --gid 1000 --home-dir /data denova \
    && mkdir -p /data /opt/denova \
    && chown -R 1000:1000 /data

COPY denova/ /opt/denova/

COPY entrypoint.sh /usr/local/bin/denova-entrypoint
COPY chromium.sh  /usr/local/bin/chromium
RUN chmod +x /usr/local/bin/denova-entrypoint /usr/local/bin/chromium

ENV PATH="/opt/denova:/opt/denova/tools:/usr/local/bin:/usr/bin:/bin" \
    DENOVA_DIR="/data/.denova" HOME="/data"

USER denova
WORKDIR /data
EXPOSE 8080

ENTRYPOINT ["tini", "--", "/usr/local/bin/denova-entrypoint"]
CMD ["/opt/denova/denova", "--no-open", "--port", "8080"]

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=10 \
    CMD curl -fsS http://127.0.0.1:8080/api/auth/status >/dev/null || exit 1
