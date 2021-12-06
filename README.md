# Small and secure minecraft server

A simple minecraft server launcher, supporting multiple mainline and Forge servers. Runs in a docker container and, unlike other docker minecraft servers, it does not need to download anything when starting.
It's fully pre-built, so it starts quickly.

## Building

Start by building the docker image for the server version you need. Run `build-image.sh` with the Minecraft Server Version or "latest" for the latest version. If the version ends in "-forge" then the forge server will be built.
Once the server image of the required version is built you will not need to re-build it agian.

## Running

Create a file with a name of your server and extension `.env` using the `server.env.example` as an example. Then run 

`./run.sh <server_name>.env [-f]`

`-f` will run the server in the foreground

## Mods

Everything fron the `world-$NAME-extras/` folder will be copied under `/data/` during the server start, so you can put your `mods/` and `shaderpacks/` there

## Tools

* To send commands to the server inside the container use `cmd`
* To backup the world files run `backup.sh`
* To stop the server run `stop` or type `stop` in the server console if it's running in foreground. It'll give it a chance to save the world before shutting down.

By running the Minecraft server you accept the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula)
