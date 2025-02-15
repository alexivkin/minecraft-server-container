# A small and secure minecraft server

A minecraft server launcher with the following features:

* run multiple mainline/vanilla, Forge and NeoForge servers at the same time, in docker containers isolated from the host.
* fast start, unlike other docker minecraft servers that download and install minecraft each time they start
* handle stop/shutdown/restart correctly, saving the world data before exiting
* send minecraft commands directly from the host

## Running

Create a file with a name of your server and extension `.env` using the `server.env.example` as an example. Then run

`./run.sh <server_name>.env [-f|-d]`

* `-f` will run the server in the foreground
* `-d` will drop into an interactive shell rather than starting the server

If the docker image for the version given in the `.env` file is missing, the image will be built automatically.

## (Neo)Forge mods

Put your mods into the `world-$NAME-extras/mods/` subfolder. In fact everything from the `world-$NAME-extras/` folder will be copied into the minecraft server root folder during the server startup, so you can put your `shaderpacks/` and everything else there.

## Building manually

Run `./build` with the Minecraft Server Version or "latest" for the latest version. If the version ends in "-forge" then the Forge server will be built.

## Tools

* To send commands to the server inside the container use `cmd`
* To backup the world files run `backup.sh`
* To stop the server run `stop` or type `stop` in the server console if it's running in foreground. It'll give it a chance to save the world before shutting down.

By running the Minecraft server you accept the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula)
