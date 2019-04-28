#
FROM openjdk:8-jre-alpine

MAINTAINER Alex Ivkin <alex@ivkin.net>

ENV UID=1000 GID=1000

COPY minecraft-server.sh /
#COPY server.properties *.jar /data/
COPY *.jar /data/
COPY libraries/ /data/libraries/

RUN umask 0002  && \
    deluser $(getent passwd 33 | cut -d: -f1)  && \
    delgroup $(getent group 33 | cut -d: -f1) 2>/dev/null || true  && \
    addgroup -g $GID minecraft  && \
    adduser -Ss /bin/false -u $UID -G minecraft -h /home/minecraft minecraft  && \
    chown -R minecraft:minecraft /data /home/minecraft  && \
    echo "eula=true" >> /data/eula.txt  && \
    chmod 755 /minecraft-server.sh  && \
    chown minecraft:minecraft /data/*

EXPOSE 25565
VOLUME ["/data"]
USER minecraft
WORKDIR /data

ENTRYPOINT [ "/minecraft-server.sh" ]
