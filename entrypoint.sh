#!/bin/sh
set -eu
# Denova v0.5.0 已把初始化内嵌进主程序，无需 panda 0.4.4 的 denova-container-init
exec "$@"
