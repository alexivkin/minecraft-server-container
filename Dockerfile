# "java-base-image" is a tag dynamically set to the required java image in the build script
FROM java-base-image

MAINTAINER Alex Ivkin

ENV UID=1000 GID=1000

# Name of the Forge installer if present
ARG FORGE_INSTALLER

COPY minecraft-server.sh /
COPY *.jar /data/
COPY libraries/ /data/libraries/

RUN umask 0002  && \
    deluser $(getent passwd 33 | cut -d: -f1)  && \
    delgroup $(getent group 33 | cut -d: -f1) 2>/dev/null || true  && \
    addgroup -g $GID minecraft  && \
    adduser -Ss /bin/false -u $UID -G minecraft -h /home/minecraft minecraft  && \
    echo $FORGE_INSTALLER && \
    echo "eula=true" >> /data/eula.txt  && \
    chmod 755 /minecraft-server.sh && \
    chown -R minecraft:minecraft /data /home/minecraft

RUN if ls /data/$FORGE_INSTALLER 1>/dev/null 2>&1; then cd /data; java -jar $FORGE_INSTALLER --installServer; rm $FORGE_INSTALLER; \
    chown -R minecraft:minecraft /data; fi

EXPOSE 25565
USER minecraft
VOLUME ["/data/world"]
VOLUME ["/extras"]
WORKDIR /data

ENTRYPOINT [ "/minecraft-server.sh" ]
