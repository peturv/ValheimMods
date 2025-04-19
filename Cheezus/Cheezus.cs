using BepInEx;

namespace Cheezus {

  public static class PluginInfo {
    public const string PluginGUID = "62548d36-77bc-445e-88da-e48854475c87";
    public const string PluginName = "Cheezus";
    public const string PluginVersion = "1.0.0";
    public const string PluginDescription = "Much needed wheel of cheese";
    public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2202"; // Comma separated string of dependencies
  }

  [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
  [BepInDependency(Jotunn.Main.ModGuid)]
  public class Cheezus : BaseUnityPlugin {

    private void Awake() {
      Jotunn.Logger.LogInfo($"{PluginInfo.PluginName} v{PluginInfo.PluginVersion} has spread it's aroma.");
    }
  }
}