using BepInEx;
using HarmonyLib;

namespace SleepWell {
  public static class PluginInfo {
    public const string PluginGUID = "b54fff0c-5dca-4d6d-8899-c3478b85529f";
    public const string PluginName = "SleepWell";
    public const string PluginVersion = "1.0.1";
    public const string PluginDescription = "Changes the sleep prompt to ZZZzzz...";
    public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2332"; // Comma separated string of dependencies
  }

  [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
  public class SleepWell : BaseUnityPlugin {

    private void Awake() {
      Harmony harmony = new("se.omnivore.valheim.sleepwell");
      harmony.PatchAll();
      UnityEngine.Debug.Log($"{PluginInfo.PluginName} v{PluginInfo.PluginVersion} has awakened.");
    }

    [HarmonyPatch]
    internal class FixSleepText {
      [HarmonyPrefix, HarmonyPatch(typeof(SleepText), "OnEnable")]
      private static void SleepText_OnEnable(SleepText __instance) {
        // balance the ZZZs of the sleep text, vanilla is ZZZZZzzzz...
        if (__instance.m_textField.text.StartsWith("ZZZZZ"))
          __instance.m_textField.text = "ZZZzzz...";
      }
    }
  }
}
