using BepInEx;
using Jotunn.Configs;
using Jotunn.Entities;
using Jotunn.Managers;
using Jotunn.Utils;
using UnityEngine;

namespace Cheezus {

  public static class PluginInfo {
    public const string PluginGUID = "f40ab7cd-b390-49bf-b196-1bcd3137a438";
    public const string PluginName = "Cheezus";
    public const string PluginVersion = "1.0.0";
    public const string PluginDescription = "Much needed wheel of cheese";
    public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2202, ValheimModding-Jotunn-2.24.3"; // Comma separated string of dependencies
  }

  [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
  [BepInDependency(Jotunn.Main.ModGuid)]
  public class Cheezus : BaseUnityPlugin {

    private CustomLocalization? Localization;

    private void Awake() {
      Jotunn.Logger.LogInfo($"{PluginInfo.PluginName} v{PluginInfo.PluginVersion} has spread it's aroma.");
      PrefabManager.OnVanillaPrefabsAvailable += AddTheCheeze;
    }

    private void AddTheCheeze() {
      // Create and add a custom item
      ItemConfig cheeseConfig = new() {
        Amount = 1
      };
      cheeseConfig.AddRequirement("Wood", 1);

      AssetBundle cheese = LoadAssets();

      // Prefab did not use mocked refs so no need to fix them
      var cheeseItem = new CustomItem(cheese, "CheeseWheel", fixReference: false, cheeseConfig);
      ItemManager.Instance.AddItem(cheeseItem);
      KeyHintsCheese();
      AddLocalizations();

      PrefabManager.OnVanillaPrefabsAvailable -= AddTheCheeze;
    }

    private AssetBundle LoadAssets() {
      // Print Embedded Resources
      // Jotunn.Logger.LogInfo($"Embedded resources: {string.Join(", ", typeof(Cheezus).Assembly.GetManifestResourceNames())}");

      // Load asset bundles from embedded resources
      return AssetUtils.LoadAssetBundleFromResources("cheese_wheel");
      // return EmbeddedResourceBundle.LoadAsset<GameObject>("cheese_wheel");
    }

    private void KeyHintsCheese() {
      // Create custom KeyHints for the item
      KeyHintManager.Instance.AddKeyHint(new KeyHintConfig {
        Item = "CheeseWheel",
        ButtonConfigs = new[]
          {
            // Override vanilla "Attack" key text
            new ButtonConfig { Name = "Use", HintToken = "$cheese_wheel_use" },
            // Override Right Click
            new ButtonConfig { Name = "Block", HintToken = "$cheese_wheel_nomnom" }
        }
      });
    }

    private void AddLocalizations() {
      // Get your mod translation instance
      Localization = LocalizationManager.Instance.GetLocalization();

      // Add translations for the custom item in AddClonedItems
      Localization.AddTranslation("English", new Dictionary<string, string> {
        {"item_cheese_wheel", "Wheel of Cheese"},
        {"item_cheese_wheel_description", "A surprisingly tempting wheel of cheese"},
        {"cheese_wheel_use", "Yoink!"},
        {"cheese_wheel_nomnom", "Nomnomnom"},
      });
    }
  }
}