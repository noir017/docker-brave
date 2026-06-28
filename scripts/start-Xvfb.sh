#!/bin/bash
# arm64 路径使用：启动 Xvfb 虚拟显示
until Xvfb :99 -screen scrn ${CUSTOM_RES_W}x${CUSTOM_RES_H}x${CUSTOM_DEPTH}; do
	echo "Xvfb server crashed with exit code $?.  Respawning.." >&2
	sleep 1
done
