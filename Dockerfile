# Denova v0.5.0 自封装镜像 —— 复刻 panda-995/denova 的配方，独立发行
# 基础镜像链：debian:bookworm-slim（与 panda 一致）
# 关键差异（0.5.0 已内嵌初始化，无需 panda 0.4.4 的独立 denova-container-init）

FROM debian:bookworm-slim

# --- 系统依赖（与 panda 0.4.4 完全一致）---
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        python3 \
        chromium \
        fonts-noto-cjk \
        tini \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# --- 运行用户：denova (uid/gid 1000)，家目录 /data（与 panda 一致）---
RUN useradd --create-home --uid 1000 --gid 1000 --home-dir /data denova \
    && mkdir -p /data /opt/denova \
    && chown -R 1000:1000 /data

# --- 复制 Denova 程序本体（0.5.0 release tar 解压后的 denova/ 目录）---
COPY denova/ /opt/denova/

# --- 入口 & chromium 无沙箱包装（panda 原版）---
COPY entrypoint.sh /usr/local/bin/denova-entrypoint
COPY chromium.sh  /usr/local/bin/chromium
RUN chmod +x /usr/local/bin/denova-entrypoint /usr/local/bin/chromium

# --- 环境变量（与 panda 一致）---
ENV PATH="/opt/denova:/opt/denova/tools:/usr/local/bin:/usr/bin:/bin" \
    DENOVA_DIR="/data/.denova" \
    HOME="/data"

# --- 非 root 运行 ---
USER denova
WORKDIR /data

EXPOSE 8080

ENTRYPOINT ["tini", "--", "/usr/local/bin/denova-entrypoint"]
CMD ["/opt/denova/denova", "--no-open", "--port", "8080"]

# 健康检查（与 panda 一致，让面板/编排能识别 healthy）
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=10 \
    CMD curl -fsS http://127.0.0.1:8080/api/auth/status >/dev/null || exit 1