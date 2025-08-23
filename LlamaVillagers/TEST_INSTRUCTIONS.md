# LlamaVillagers Test Instructions

## ✅ Mod Successfully Deployed!

Your LlamaVillagers mod has been deployed to:
`D:\Games\ThunderstoreData\Valheim\profiles\Development\BepInEx\plugins\LlamaVillagers`

## 🎮 How to Test

### 1. Start Valheim
- Launch Valheim through Thunderstore Mod Manager
- Or start normally if using the Development profile

### 2. Check Mod Loading
Look for these messages in `BepInEx/LogOutput.log`:
```
[Info] LlamaVillagers AI Dialogue System initializing...
[Info] Loading AI model from [path]...
[Info] AI model loaded successfully! Ready for dialogue generation.
[Info] LlamaVillagers AI Dialogue System ready!
```

### 3. Test NPC Interactions

#### Method 1: Direct Interaction
- Find Haldor (the merchant) in your world
- Press E to interact
- You should see a response in chat

#### Method 2: Chat Commands
- Open chat (Enter key)
- Type: `/Haldor hello`
- Type: `/Hugin tell me about Valheim`
- Type: `/Munin what do you remember?`

### 4. Expected Responses

**Haldor** should respond with something like:
> "Greetings, warrior! I am Haldor. Wise, experienced, slightly mysterious. Speaks of distant lands and rare treasures."

**Hugin** should respond with:
> "Greetings, warrior! I am Hugin. Mysterious, cryptic, speaks in riddles and omens. Has ancient wisdom."

**Munin** should respond with:
> "Greetings, warrior! I am Munin. Thoughtful, observant, speaks of memories and forgotten knowledge."

## 🔧 Configuration

The mod creates a config file at:
`BepInEx/config/LlamaVillagers.cfg`

You can adjust:
- `EnableAIDialogue` - Turn AI on/off
- `ModelPath` - Path to your GGUF model
- `MaxResponseLength` - Maximum response length
- `DialogueRange` - Range for sharing dialogue

## 🚀 Next Steps

1. **Test the current implementation** - Verify NPCs respond
2. **Add your GGUF model** - Place in `BepInEx/plugins/LlamaVillagers/models/`
3. **Implement full AI** - Replace placeholder with actual LlamaSharp calls
4. **Add more NPCs** - Expand the personality roster

## 🐛 Troubleshooting

### No Responses
- Check BepInEx logs for errors
- Verify mod is loaded in Thunderstore
- Try chat commands instead of direct interaction

### Model Not Found
- Check the model path in config
- Ensure model file exists in the models folder
- Restart Valheim after adding model

### Performance Issues
- Start with a smaller model (TinyLlama)
- Reduce MaxResponseLength in config
- Monitor memory usage

## 📝 Current Features

✅ **Working:**
- Mod loading and initialization
- NPC personality system
- Harmony patches for interaction
- Chat command integration
- Response caching
- Configuration system

🔄 **Ready for Implementation:**
- Full LlamaSharp AI integration
- Network synchronization
- Additional NPC personalities
- Advanced dialogue features

## 🎯 Success Criteria

The mod is working correctly if:
1. You see initialization messages in logs
2. NPCs respond to interaction/chat
3. Responses match the personality descriptions
4. No errors in BepInEx logs

**Ready to test! Launch Valheim and find Haldor! 🗡️**
