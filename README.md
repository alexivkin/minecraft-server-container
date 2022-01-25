# Small and secure minecraft server

A minecraft server launcher with the following features:

* supporting multiple mainline and Forge servers running at the same time
* runs in a docker container, fully isolated from the host
* handles stop/shutdown correctly, saving the world data before existing
* automatically restarts if the minecraft server crashes
* starts quickly, unlike other docker minecraft servers that download code each time they start,

## Building

Start by building the docker image for the server version you need. Run `build-image.sh` with the Minecraft Server Version or "latest" for the latest version. If the version ends in "-forge" then the forge server will be built.
Once the server image of the required version is built you will not need to re-build it agian.

## Running

Create a file with a name of your server and extension `.env` using the `server.env.example` as an example. Then run 

`./run.sh <server_name>.env [-f|-d]`

* `-f` will run the server in the foreground
* `-d` will drop into an interactive shell rather than starting the server

## Mods

Everything fron the `world-$NAME-extras/` folder will be copied under `/data/` during the server start, so you can put your `mods/` and `shaderpacks/` there

## Tools

* To send commands to the server inside the container use `cmd`
* To backup the world files run `backup.sh`
* To stop the server run `stop` or type `stop` in the server console if it's running in foreground. It'll give it a chance to save the world before shutting down.

By running the Minecraft server you accept the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula)
