using BepInEx;
using BepInEx.Configuration;
using Jotunn.Entities;
using Jotunn.Managers;
using Jotunn.Utils;

namespace LlamaVillagers
{
    [BepInPlugin(PluginGUID, PluginName, PluginVersion)]
    [BepInDependency(Jotunn.Main.ModGuid)]
    //[NetworkCompatibility(CompatibilityLevel.EveryoneMustHaveMod, VersionStrictness.Minor)]
    internal class LlamaVillagers : BaseUnityPlugin
    {
        public const string PluginGUID = "com.omnivore.LlamaVillagers";
        public const string PluginName = "LlamaVillagers";
        public const string PluginVersion = "0.0.1";
        

        // Use this class to add your own localization to the game
        // https://valheim-modding.github.io/Jotunn/tutorials/localization.html
        public static CustomLocalization Localization = LocalizationManager.Instance.GetLocalization();

        /*
        private ConfigEntry<T> Config<T>(string group, string name, T value, ConfigDescription description, bool synchronizedConfig = true)
        {

        }
        */

        private void Awake()
        {
            // Jotunn comes with its own Logger class to provide a consistent Log style for all mods using it
            Jotunn.Logger.LogInfo("LlamaVillagers has landed");

            
            
            // To learn more about Jotunn's features, go to
            // https://valheim-modding.github.io/Jotunn/tutorials/overview.html
        }
    }
}