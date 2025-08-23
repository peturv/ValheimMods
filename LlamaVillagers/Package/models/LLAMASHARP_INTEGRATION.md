# LlamaSharp Integration Guide

## Current Status
The LlamaVillagers mod is successfully built and ready for testing with placeholder AI responses. The full LlamaSharp integration requires API method resolution.

## Model Loading (✅ Working)
The model loading code is implemented and will:
- Load your GGUF model from the specified path
- Create a context with optimized parameters
- Set up inference parameters

## AI Response Generation (🔄 Needs API Update)
Currently using placeholder responses. To implement full AI generation, replace the placeholder in `LlamaVillagers.cs`:

### Current Placeholder (Line ~208):
```csharp
// For now, use a simple approach that works with the current API
var generatedText = $"Greetings, warrior! I am {npcName}. {personality.Personality}";

// TODO: Implement proper LlamaSharp inference once API is confirmed
// The current LlamaSharp version may have different method names
// This placeholder ensures the mod works while we resolve the API
```

### Replace with Full AI Implementation:
```csharp
// Generate the response using LlamaSharp
var result = await _context.InferAsync(prompt, _inferenceParams);
var generatedText = result.FirstOrDefault()?.ToString() ?? "";
```

## Testing the Current Implementation

### 1. Deploy the Mod
```bash
# Use the launch configuration or run manually
powershell.exe -ExecutionPolicy RemoteSigned -File "publish.ps1" -Target "Debug" -TargetPath "BuildOutput\Debug\net48" -TargetAssembly "LlamaVillagers.dll"
```

### 2. Test NPC Interactions
- Find NPCs like Haldor (merchant) in Valheim
- Press E to interact
- NPCs will respond with personality-based dialogue
- Use chat commands like `/Haldor hello` to test chat integration

### 3. Check BepInEx Logs
Look for these messages in `BepInEx/LogOutput.log`:
```
[Info] LlamaVillagers AI Dialogue System initializing...
[Info] Loading AI model from [path]...
[Info] AI model loaded successfully! Ready for dialogue generation.
[Info] LlamaVillagers AI Dialogue System ready!
```

## Next Steps for Full AI Integration

### 1. Verify LlamaSharp API
Check the correct method names in your LlamaSharp version:
```csharp
// Try these variations:
_context.Infer(prompt, _inferenceParams)
_context.InferAsync(prompt, _inferenceParams)
_context.Generate(prompt, _inferenceParams)
```

### 2. Update Inference Parameters
The current `InferenceParams` may need adjustment based on your LlamaSharp version:
```csharp
_inferenceParams = new InferenceParams
{
    MaxTokens = Instance._maxResponseLength.Value,
    AntiPrompts = new[] { "\nPlayer:", "\nHuman:", "\nUser:", "\n\n" }
    // Add other parameters as needed for your version
};
```

### 3. Test with Different Models
Try different GGUF models to find the best balance of quality and performance:
- **Phi-2**: Good quality, moderate size
- **TinyLlama**: Fast, smaller size
- **Llama-2-7B**: High quality, larger size

## Configuration

The mod creates a config file at `BepInEx/config/LlamaVillagers.cfg`:
```ini
[AI]
EnableAIDialogue = true
ModelPath = BepInEx/plugins/LlamaVillagers/models/phi-2-q4_k_m.gguf
MaxResponseLength = 100
DialogueRange = 20
```

## Performance Tips

1. **Start with a smaller model** (TinyLlama) for testing
2. **Monitor memory usage** - GGUF models can use 1-4GB RAM
3. **Adjust context size** if you experience memory issues
4. **Use CPU-only mode** for maximum compatibility

## Troubleshooting

### Model Not Loading
- Check file path in config
- Ensure model file exists and is not corrupted
- Verify model is in GGUF format

### No NPC Responses
- Check BepInEx logs for errors
- Verify NPC names match the personalities (Haldor, Hugin, Munin)
- Test with chat commands: `/Haldor hello`

### Performance Issues
- Reduce `MaxResponseLength` in config
- Try a smaller model
- Increase `ContextSize` if you have more RAM

## Current NPC Personalities

### Haldor (Merchant)
- **Background**: Traveling merchant with rare goods
- **Personality**: Wise, experienced, mysterious
- **Context**: Standing at merchant cart

### Hugin (Odin's Raven)
- **Background**: One of Odin's ravens, observer
- **Personality**: Mysterious, cryptic, speaks in riddles
- **Context**: Perched on a branch

### Munin (Hugin's Companion)
- **Background**: Hugin's companion, memory gatherer
- **Personality**: Thoughtful, observant, speaks of memories
- **Context**: Flying alongside Hugin
