using BepInEx;
using HarmonyLib;
using TMPro;
using UnityEngine;

namespace SleepWell {
    [BepInPlugin(PluginGUID, PluginName, PluginVersion)]
    [BepInDependency(Jotunn.Main.ModGuid)]
    public class SleepWell : BaseUnityPlugin {

        public const string PluginGUID = "b54fff0c-5dca-4d6d-8899-c3478b85529f";
        public const string PluginName = "SleepWell";
        public const string PluginVersion = "1.0.0";

        private void Awake() {
            Harmony harmony = new("se.omnivore.valheim.sleepwell");
            harmony.PatchAll();
            Jotunn.Logger.LogInfo("Sleep well has awakened");
        }

        [HarmonyPatch(typeof(TextMeshProUGUI), "Awake")]
        public class Patch_TMPUGUI {
            static void Postfix(TextMeshProUGUI __instance) {
                if (__instance != null && __instance.gameObject.GetComponent<TextInterceptor>() == null) {
                    __instance.gameObject.AddComponent<TextInterceptor>();
                }
            }
        }

        /*
        private void Awake() {
            Harmony harmony = new("se.omnivore.valheim.sleepwell");
            harmony.PatchAll();
            UnityEngine.Debug.Log($"Sleep well has awakened");
        }

        [HarmonyPatch(typeof(Player), nameof(Player.Message))]
        [HarmonyPatch(new[] { typeof(MessageHud.MessageType), typeof(string), typeof(int), typeof(UnityEngine.Sprite) })]
        public static class Patch_Player_Message {
            static bool Prefix(ref MessageHud.MessageType type, ref string msg) {
                UnityEngine.Debug.Log($"[Intercepted Message] Type: {type}, Msg: {msg}");
                if (type == MessageHud.MessageType.Center && msg.TrimStart().StartsWith("ZZZZ", System.StringComparison.OrdinalIgnoreCase)) {
                    msg = "ZZZzzz...";
                }
                return true; // continue original method
            }
        }
        */
        /*
            [HarmonyPatch(typeof(Player), nameof(Player.AttachStart))]
            public static class Patch_Player_AttachStart {
                [HarmonyTranspiler]
                public static IEnumerable<CodeInstruction> ReplaceZZZMessage(IEnumerable<CodeInstruction> instructions) {
                    foreach (var instruction in instructions) {
                        if (instruction.opcode == OpCodes.Ldstr && instruction.operand is string s && s.Trim().StartsWith("ZZZZ")) {
                            yield return new CodeInstruction(OpCodes.Ldstr, "ZZZzzz...");
                        } else {
                            yield return instruction;
                        }
                    }
                }
            }
        */
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