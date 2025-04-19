using BepInEx;
using HarmonyLib;
using TMPro;
using UnityEngine;

namespace SleepWell {
  public static class PluginInfo {
    public const string PluginGUID = "b54fff0c-5dca-4d6d-8899-c3478b85529f";
    public const string PluginName = "SleepWell";
    public const string PluginVersion = "1.0.0";
    public const string PluginDescription = "Changes the sleep prompt to ZZZzzz...";
    public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2202"; // Comma separated string of dependencies
  }

  [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
  public class SleepWell : BaseUnityPlugin {

    private void Awake() {
      Harmony harmony = new("se.omnivore.valheim.sleepwell");
      harmony.PatchAll();
      UnityEngine.Debug.Log($"{PluginInfo.PluginName} v{PluginInfo.PluginVersion} has awakened.");
    }

    [HarmonyPatch(typeof(TextMeshProUGUI), "Awake")]
    public class Patch_TMPUGUI {
      static void Postfix(TextMeshProUGUI __instance) {
        if (__instance != null && __instance.gameObject.GetComponent<TextInterceptor>() == null) {
          __instance.gameObject.AddComponent<TextInterceptor>();
        }
      }
    }

  }
  public class TextInterceptor : MonoBehaviour {
    private TextMeshProUGUI? tmp;
    private string? lastText;

    void Awake() {
      tmp = GetComponent<TextMeshProUGUI>();
    }

    void Update() {
      if (tmp?.text != null && tmp?.text != "" && tmp?.text != lastText) {
        lastText = tmp?.text;
        if (tmp?.text?.TrimStart()?.StartsWith("ZZZZ", System.StringComparison.OrdinalIgnoreCase) == true) {
          tmp.text = "ZZZzzz...";
        }
      }
    }
  }
}