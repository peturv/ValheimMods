# Omnivore Valheim Mods

This solution and projects are based on the Valheim mod stub project from [Jötunn](https://github.com/Valheim-Modding/Jotunn) 
Please see [Jötunn Docs](https://valheim-modding.github.io/Jotunn/guides/overview.html) detailed documentation and setup.

## State of sub-projects

### Working
* SleepWell
* OsxModManager (Not a C# project, it just lives here as well. Needs manual packaging)
* MetadataCreator (Supporting project)
* OmnivoreCommon (Supporting project)

### Development
* Cheezus

### Early experimental stage
* LlamaVillagers

### Post Build automations

Included in this repo is a PowerShell script `publish.ps1`.
The script is referenced in the project file as a post-build event.
Depending on the chosen configuration in Visual Studio the script executes the following actions.

### Building Debug

The compiled dll and a dll.mdb debug file are copied to `<ValheimDir>\BepInEx\plugins` (or the path set in MOD_DEPLOYPATH).

### Building Release

A compressed file with the binaries is created in `<JotunnModStub>\Packages`ready for upload to ThunderStore.

## Developing Assets with Unity

New Assets can be created with Unity and imported into Valheim using the mod.

## Debugging

See the Wiki page [Debugging Plugins via IDE](https://github.com/Valheim-Modding/Wiki/wiki/Debugging-Plugins-via-IDE) for more information

## Actions after a game update

When Valheim updates it is likely that parts of the assembly files change. If this is the case, the references to the assembly files must be renewed in Visual Studio and Unity.

### Prebuild actions

1. There is a file called DoPrebuild.props included in the solution. When you set the ExecutePrebuild value to true, Jötunn will automatically generate publicized assemblies for you. Otherwise you have to do this step manually.

### Unity actions

1. Copy all `assembly_*.dll` from `<ValheimDir>\valheim_Data\Managed` into `<JotunnModStub>\JotunnModUnity\Assets\Assemblies`. <br />
  **Do this directly in the filesystem - don't import the dlls in Unity**.
2. Go to Unity Editor and press `Ctrl+R`. This reloads all files from the filesystem and "re-imports" the copied dlls into the project.

### Deploy to plugin folder
To deploy output to local valheim for testing and debugging, add an Environment.props file into the root of the project with the following content:
```xml
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="Current" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <MOD_DEPLOYPATH>C:\PATH\TO\BepInEx\plugins</MOD_DEPLOYPATH>
  </PropertyGroup>
</Project>
````