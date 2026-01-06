FROM ich777/novnc-baseimage:bullseye_arm64

LABEL maintainer="admin@minenet.at"

RUN apt-get update && \
	apt-get -y install --no-install-recommends fonts-noto-cjk curl  scrot nano iputils-ping

RUN export TZ=Asia/Shanghai && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen && \
	rm -rf /var/lib/apt/lists/*

RUN curl -fsS https://dl.brave.com/install.sh | sh

ENV DATA_DIR=/user
ENV BRAVE_DIR=/user/braveData/brave1
ENV CUSTOM_RES_W=1024
ENV CUSTOM_RES_H=720
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