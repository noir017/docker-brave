# syntax=docker/dockerfile:1
# 多架构构建：buildx 会自动注入 TARGETARCH（amd64 / arm64）
# 用法示例：
#   docker buildx build --platform linux/amd64,linux/arm64 -t <repo>/docker-brave .

# 按架构选择基础镜像
FROM ich777/novnc-baseimage AS base-amd64
FROM ich777/novnc-baseimage:bullseye_arm64 AS base-arm64

ARG TARGETARCH
FROM base-${TARGETARCH}

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/noir017/docker-brave"

# FROM 之后需重新声明 ARG 才能在后续 RUN 中使用
ARG TARGETARCH

# 通用依赖 + 时区/语言
RUN export TZ=Asia/Shanghai && \
	apt-get update && \
	apt-get -y install --no-install-recommends curl gnupg fonts-noto-cjk scrot nano iputils-ping && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen

# 安装 Brave：amd64 走官方 APT 源，arm64 走官方安装脚本
RUN if [ "$TARGETARCH" = "amd64" ]; then \
		curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list && \
		apt-get update && \
		apt-get -y install --no-install-recommends brave-browser libgtk-3-0; \
	else \
		curl -fsS https://dl.brave.com/install.sh | sh; \
	fi && \
	rm -rf /var/lib/apt/lists/*

# 自定义 noVNC 标题并清空默认图标
RUN sed -i '/    document.title =/c\    document.title = "Brave浏览器 - noVNC";' /usr/share/novnc/app/ui.js && \
	rm -f /usr/share/novnc/app/images/icons/*

ENV DATA_DIR=/user
ENV BRAVE_DIR=/user/braveData/brave1
ENV CUSTOM_RES_W=1024
ENV CUSTOM_RES_H=768
ENV CUSTOM_DEPTH=16
ENV NOVNC_PORT=8080
ENV RFB_PORT=5900
ENV TURBOVNC_PARAMS="-securitytypes none"
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="user"
ENV PATH="/opt/scripts:${PATH}"

RUN mkdir -p $DATA_DIR && mkdir -p $BRAVE_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	chown -R $USER $BRAVE_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
COPY /icons/* /usr/share/novnc/app/images/icons/
COPY /conf/ /etc/.fluxbox/

RUN chmod -R 770 /opt/scripts/

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
