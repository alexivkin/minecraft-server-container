# Small and secure minecraft server in a docker container

A simple minecraft server container, supporting mainline and Forge servers. Unlike other docker minecraft servers, it does not need to download anything when starting.
It's fully pre-built, so it starts quickly.

## Running

Create a file with a name of your server and extension .env using the `server.env.example` as an example. Then run

        ./run.sh <server_name> [-f]

By running it you accept the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula)

`-f` will run the server in the foreground

## Building

Run `build-image.sh` with the Minecraft Server Version or "latest" for the latest version. If the version ends in "-forge" then the forge server will be built.

## Mods

Everything fron the world-$NAME-extras/ foldeer will be copied under /data/ during the server start, so you can put your mods/ and shaderpacks/ there

## Tools

* To communicate with the server inside the container use `cmd.sh`
* To backup world files run `backup.sh`
* To stop the server run `stop.sh` or type `stop` in the server console
