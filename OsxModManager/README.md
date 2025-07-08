# Omnivore Mod Manager.

Simple console based mod-manager for macos that allows you to install mods for Valheim. 
It is designed to be easy to use and lightweight.

## Quickstart
1. Download & extract.
2. Put files from ./scripts into `~/Library/Application Support/Steam/steamapps/common/Valheim` or wherever you have valheim.app and the BepInEx folder.
3. Change permissions for the command file `chmod +x ~/Library/Application Support/Steam/steamapps/common/Valheim/valheim_modmanager.command"` in the console
4. Run the `valheim_modmanager.command` file by double-clicking. See [macOS complains about the script being from an unidentified developer].
5. Follow the prompts.

## Background

Being a family without any loyalty to operating systems or platforms, most of us play games on both Windows, macos and sometimes Linux.

This is all good and well, but some things become a bit of a hassle, like managing mods for Valheim.

On Windows we have the thunderstore client which is great, but on macOS we have to handle things through manual downloads which is a pain
especially when playing on servers that are modded. A lot of time is spent on downloading, ensuring dependencies are correct,
and renaming plugin folders to plugins_serverX and back & forth.

I got tired of this, so I made a simple mod manager that allows me to install mods and handle dependencies for Valheim on macOS.

## Concepts

### Modpacks
Instead of the traditional concept of "profiles", I use the concept of "modpacks" (Might transition to "servers" later).

The manager allows you to point out a modpack for a server on thunderstore.io 
for example https://thunderstore.io/c/valheim/p/Suudo/SweetAroma/ (I don't play there and am not intentionally promoting it, 
this was just the first server modpack that showed up in the browsing on thunderstore at the time of writing).

The manager will then download the modpack and all its dependencies recursively, you can then select which of the downloaded modpacks 
you want to apply. The manager remebers previously selected modpack so on next run you can simply press enter/p to start directly.

### Client mods
Client mods are mods that don't need server support, and that can be enabled no matter which modpack you are using. The manager does not
do any validation of that the mods you install as client mods ARE actually client-only, that judgement is left to the user.

## Prerequisites

To run the script, you need the following installed and available on the command line:
* curl
* jq
* bash version 4.0 or later (The default bash on macOS is v3.5, so you will need to install a newer version)

The easiest way to ensure this is to install [Homebrew](https://brew.sh/) and then run: `brew install curl jq bash`
Note that bash will not overwrite the default macos version. I'm writing this from my windows computer and can't 
remeber exactly where the default bash is located (`/bin/bash` or similar), the new one will be installed under `/opt/homebrew/bin`.

The script should find the newly installed one anyhow.

And while I have added a poor-mans setup for BepInEx, I have not actually tested it properly, am assuming I'm using the wrong libdoorstop.dylib.
You can check out : [This excellent post on steam on setting up BepInEx for macos](https://steamcommunity.com/sharedfiles/filedetails/?id=3269574338)

## Installation
1. Download
2. Unzip
3. Move the FILES from the ./scripts to the folder that contains BepInEx. This is usually `~/Library/Application Support/Steam/steamapps/common/Valheim`
4. Create an Alias to the valheim_modmanager.command file and place on the desktop or wherever you want. 

### Optional steps
5. You can rename this alias file if you want,
6. Copy the icon from the valheim.app by pressing selecting each file and pressing command-i, and then dragging the icon from the app to the alias file.
7. Associate the .command file with a terminal of your choosing. If you feel the need to do this, I'm assuming you know what you are doing.

 :)

## Usage

Run the script by double-clicking the alias file you created in the installation step 4.

If BepInEx is not installed, you will be prompted to install it. If you choose to install BepInEx, the script will attempt to download and set it up for you. 
I do NOT guarantee success here, feel free to submit PR:s if you have a better way of doing this.

You will be presented with a menu where you can select to install a modpack, install client mods, or exit the script.
If modpacks are already installed, you will also see a list of previously installed modpacks that you can select from.

The selection is saved between runs.

You can also press `p` or `enter` to start the game (with or without modpack), or `q` to exit the script.

When installing a modpack, you will be prompted to enter the URL of the modpack on thunderstore.io. This is in the format https://thunderstore.io/c/valheim/p/Suudo/SweetAroma/
You can also point to a local file that conforms to the manifest.json format.

When installing client mods, you will be prompted to enter the dependency string of the mod on thunderstore.io, with or without a version number. 
For example `oathorse-TubaWalk-0.1.3` or `oathorse-TubaWalk` (a mod which should be part of the actual game btw.)

When lacking version number, the latest version will be installed. The mod will also do checks for updated modpacks when starting the game, to ensure it is in sync with the server.

## Troubleshooting
### macOS complains about the script being from an unidentified developer
If macos complains about the script being from an unidentified developer, you can open System Settings > Privacy & Security and click "Open Anyway" next to the warning about the script.

I always recommend people to read through the code before running it, so you know what it does and that it is safe to run. All the code is there in the scripts, so please do have a look.

## Improvements or contributions
* [Post me an issue on github](https://github.com/peturv/ValheimMods/issues) if you have any problems, or if you have suggestions for improvements.
* Create a PR [on github](https://github.com/peturv/ValheimMods) if you have fixes or improvements.