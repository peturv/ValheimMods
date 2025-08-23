using BepInEx;
using BepInEx.Configuration;
using Jotunn.Configs;
using Jotunn.Entities;
using Jotunn.Managers;
using Jotunn.Utils;
using LLama;
using LLama.Common;
using System.Collections.Concurrent;
using UnityEngine;

namespace LlamaVillagers {
    public static class PluginInfo {
        public const string PluginGUID = "62548d36-77bc-445e-88da-e48854475c87";
        public const string PluginName = "LlamaVillagers";
        public const string PluginVersion = "0.0.1";
        public const string PluginDescription = "Living NPC:s";
        public const string PluginDependencies = "denikson-BepInExPack_Valheim-5.4.2332, ValheimModding-Jotunn-2.26.0";
    }

    [BepInPlugin(PluginInfo.PluginGUID, PluginInfo.PluginName, PluginInfo.PluginVersion)]
    [BepInDependency(Jotunn.Main.ModGuid)]
    public class LlamaVillagers : BaseUnityPlugin {

        // Configuration
        private ConfigEntry<bool>? _enableAIDialogue;
        private ConfigEntry<string>? _modelPath;
        private ConfigEntry<int>? _maxResponseLength;
        private ConfigEntry<float>? _dialogueRange;

        // AI Components
        private static LLamaWeights? _model;
        private static LLamaContext? _context;
        private static InferenceParams? _inferenceParams;
        private static bool _modelLoaded = false;

        // Dialogue Management
        //        public static readonly ConcurrentDictionary<string, NPCPersonality> _npcPersonalities = new();
        //        private static readonly ConcurrentDictionary<string, string> _responseCache = new();

        // Valheim Context
        public static readonly string _valheimContext = @"
        You are an NPC in Valheim, a Viking survival game set in the tenth world of Norse mythology.
        Key concepts: Odin, Valhalla, Ragnarök, Norse mythology, survival, crafting, building, exploration.
        Keep responses brief (1-2 sentences), immersive, and in character. Use Viking/Norse language style.
        ";

        private void Awake() {
            Jotunn.Logger.LogInfo("LlamaVillagers initializing...");

            // Load configuration
            Jotunn.Logger.LogInfo("Loading configuration...");
            // LoadConfiguration();

            // Initialize AI system
            Jotunn.Logger.LogInfo("Initializing AI system...");
            //            InitializeAISystem();

            // Set up NPC personalities
            Jotunn.Logger.LogInfo("Setting up NPC personalities...");
            //            SetupNPCPersonalities();

            // Apply Harmony patches
            Jotunn.Logger.LogInfo("Applying Harmony patches...");
            //            Harmony harmony = new("se.omnivore.valheim.villagers");
            //            harmony.PatchAll();

            Jotunn.Logger.LogInfo("LlamaVillagers AI Dialogue System ready!");


            Jotunn.Logger.LogInfo($"{PluginInfo.PluginName} v{PluginInfo.PluginVersion} has awakened.");
        }
        /*
                private void LoadConfiguration() {
                    _enableAIDialogue = Config.Bind("AI", "EnableAIDialogue", true, "Enable AI-powered NPC dialogue");
                    _modelPath = Config.Bind("AI", "ModelPath", "BepInEx/plugins/LlamaVillagers/models/phi-2-q4_k_m.gguf", "Path to the GGUF model file");
                    _maxResponseLength = Config.Bind("AI", "MaxResponseLength", 100, "Maximum length of AI responses");
                    _dialogueRange = Config.Bind("AI", "DialogueRange", 20f, "Range for sharing dialogue with other players");
                }

                private async void InitializeAISystem() {
                    if (_enableAIDialogue == null || !_enableAIDialogue.Value) {
                        Jotunn.Logger.LogInfo("AI dialogue disabled in configuration");
                        return;
                    }

                    try {
                        await Task.Run(() => LoadModel());
                    } catch (Exception ex) {
                        Jotunn.Logger.LogError($"Failed to load AI model: {ex.Message}");
                    }
                }

                private void LoadModel() {
                    try {
                        if (this._modelPath == null || this._modelPath.Value.IsNullOrWhiteSpace()) {
                            Jotunn.Logger.LogInfo("Missing model path in configuration");
                            return;
                        }

                        var modelPath = Path.Combine(BepInEx.Paths.BepInExRootPath, this._modelPath!.Value);

                        if (!File.Exists(modelPath)) {
                            Jotunn.Logger.LogWarning($"Model file not found at {modelPath}. AI dialogue will be disabled.");
                            return;
                        }

                        Jotunn.Logger.LogInfo($"Loading AI model from {modelPath}...");

                        // Load the GGUF model using the correct API
                        var parameters = new ModelParams(modelPath) {
                            ContextSize = 2048,
                            GpuLayerCount = 0, // CPU only for compatibility
                            Threads = Environment.ProcessorCount
                        };

                        _model = LLamaWeights.LoadFromFile(parameters);
                        _context = _model.CreateContext(parameters);

                        // Configure inference parameters for dialogue generation
                        _inferenceParams = new InferenceParams {
                            MaxTokens = this._maxResponseLength?.Value ?? 100,
                            AntiPrompts = new[] { "\nPlayer:", "\nHuman:", "\nUser:", "\n\n" }
                        };

                        _modelLoaded = true;
                        Jotunn.Logger.LogInfo("AI model loaded successfully! Ready for dialogue generation.");
                    } catch (Exception ex) {
                        Jotunn.Logger.LogError($"Error loading AI model: {ex}");
                        _modelLoaded = false;
                    }
                }

                private void SetupNPCPersonalities() {
                    // Add some sample NPC personalities
                    _npcPersonalities.TryAdd("Haldor", new NPCPersonality {
                        Name = "Haldor",
                        Background = "A traveling merchant who has seen many worlds and carries rare goods from distant lands.",
                        Personality = "Wise, experienced, slightly mysterious. Speaks of distant lands and rare treasures.",
                        CurrentContext = "Standing at his merchant cart, ready to trade with travelers."
                    });

                    _npcPersonalities.TryAdd("Hugin", new NPCPersonality {
                        Name = "Hugin",
                        Background = "One of Odin's ravens, sent to observe and guide warriors in Valheim.",
                        Personality = "Mysterious, cryptic, speaks in riddles and omens. Has ancient wisdom.",
                        CurrentContext = "Perched on a branch, watching over the realm."
                    });

                    _npcPersonalities.TryAdd("Munin", new NPCPersonality {
                        Name = "Munin",
                        Background = "Hugin's companion raven, also serving Odin by gathering knowledge and memories.",
                        Personality = "Thoughtful, observant, speaks of memories and forgotten knowledge.",
                        CurrentContext = "Flying alongside Hugin, collecting wisdom from the realm."
                    });
                }

                public static async Task<string> GenerateDialogue(string npcName, string playerInput) {
                    if (!_modelLoaded || !_npcPersonalities.TryGetValue(npcName, out var personality)) {
                        return "I have nothing to say right now.";
                    }

                    try {
                        // Check cache first
                        var cacheKey = $"{npcName}:{playerInput}";
                        if (_responseCache.TryGetValue(cacheKey, out var cachedResponse)) {
                            return cachedResponse;
                        }

                        // Generate prompt
                        var prompt = personality.GetPrompt(playerInput);

                        // Generate response using the AI model
                        var response = await Task.Run(() => {
                            try {
                                if (_context == null || _inferenceParams == null) {
                                    return $"Greetings, warrior! I am {npcName}. {personality.Personality}";
                                }

                                // Generate the response using LlamaSharp
                                // For now, use a simple approach that works with the current API
                                var generatedText = $"Greetings, warrior! I am {npcName}. {personality.Personality}";

                                // TODO: Implement proper LlamaSharp inference once API is confirmed
                                // The current LlamaSharp version may have different method names
                                // This placeholder ensures the mod works while we resolve the API

                                // Clean up the response
                                generatedText = generatedText.Trim();

                                // Remove any remaining prompt text
                                if (generatedText.Contains($"{npcName}:")) {
                                    generatedText = generatedText.Substring(generatedText.IndexOf($"{npcName}:") + $"{npcName}:".Length).Trim();
                                }

                                // Ensure we have a valid response
                                if (string.IsNullOrWhiteSpace(generatedText)) {
                                    return $"Greetings, warrior! I am {npcName}. {personality.Personality}";
                                }

                                return generatedText;
                            } catch (Exception ex) {
                                Jotunn.Logger.LogError($"Error generating AI response: {ex.Message}");
                                return $"Greetings, warrior! I am {npcName}. {personality.Personality}";
                            }
                        });

                        // Clean up response
                        response = response.Trim();
                        if (response.StartsWith($"{npcName}:")) {
                            response = response.Substring($"{npcName}:".Length).Trim();
                        }

                        // Cache the response
                        _responseCache.TryAdd(cacheKey, response);

                        return response;
                    } catch (Exception ex) {
                        Jotunn.Logger.LogError($"Error generating dialogue: {ex.Message}");
                        return "My words fail me...";
                    }
                }

                public static void ShareDialogueWithNearbyPlayers(string npcName, string dialogue, Vector3 position) {
                    // This will be implemented with Valheim's networking system
                    Jotunn.Logger.LogInfo($"NPC {npcName}: {dialogue}");

                    // For now, just log to console
                    // TODO: Implement proper network sharing
                }
                */
    }
    /*
        public class NPCPersonality {
            public string Name { get; set; } = null!;
            public string Background { get; set; } = null!;
            public string Personality { get; set; } = null!;
            public string CurrentContext { get; set; } = null!;

            public string GetPrompt(string playerInput) {
                return $"{LlamaVillagers._valheimContext}\n\nYou are {Name}. {Background}\n{Personality}\nCurrent situation: {CurrentContext}\n\nPlayer: {playerInput}\n{Name}:";
            }
        }
        */
}
