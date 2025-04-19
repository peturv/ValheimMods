using BepInEx;
using Jotunn.Entities;
using Jotunn.Managers;

namespace LlamaVillagers {
 
public static class PluginInfo {
    public const string PluginGUID = "62548d36-77bc-445e-88da-e48854475c87";
    public const string PluginName = "LlamaVillagers";
    public const string PluginVersion = "0.0.1";
    public const string PluginDescription = "Living NPC:s";
    public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2202, ValheimModding-Jotunn-2.24.3"; // Comma separated string of dependencies
  }

  [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
  [BepInDependency(Jotunn.Main.ModGuid)]
  //[NetworkCompatibility(CompatibilityLevel.EveryoneMustHaveMod, VersionStrictness.Minor)]
  internal class LlamaVillagers : BaseUnityPlugin {

    // Use this class to add your own localization to the game
    // https://valheim-modding.github.io/Jotunn/tutorials/localization.html
    public static CustomLocalization Localization = LocalizationManager.Instance.GetLocalization();

    /*
    private ConfigEntry<T> Config<T>(string group, string name, T value, ConfigDescription description, bool synchronizedConfig = true)
    {

    }
    */

    private void Awake() {
      // Jotunn comes with its own Logger class to provide a consistent Log style for all mods using it
      Jotunn.Logger.LogInfo("LlamaVillagers has landed");



      // To learn more about Jotunn's features, go to
      // https://valheim-modding.github.io/Jotunn/tutorials/overview.html
    }
  }
}