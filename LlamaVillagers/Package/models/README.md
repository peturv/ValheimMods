# AI Models for LlamaVillagers

This directory should contain your GGUF model files for the AI dialogue system.

## Recommended Models

### 1. Phi-2 (Recommended for most users)
- **File**: `phi-2-q4_k_m.gguf`
- **Size**: ~1.5GB
- **Memory**: ~2GB RAM
- **Quality**: Excellent for dialogue, good instruction following
- **Download**: [Hugging Face](https://huggingface.co/TheBloke/phi-2-GGUF)

### 2. TinyLlama (Lightweight option)
- **File**: `tinyllama-1.1b-chat-q4_k_m.gguf`
- **Size**: ~700MB
- **Memory**: ~1GB RAM
- **Quality**: Good for basic dialogue
- **Download**: [Hugging Face](https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF)

### 3. Llama-2-7B (High quality, requires more resources)
- **File**: `llama-2-7b-chat-q4_k_m.gguf`
- **Size**: ~4GB
- **Memory**: ~4GB RAM
- **Quality**: Excellent dialogue quality
- **Download**: [Hugging Face](https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF)

## Installation Instructions

1. **Download** your preferred model from Hugging Face
2. **Place** the `.gguf` file in this directory
3. **Rename** it to match the configuration in `BepInEx/config/LlamaVillagers.cfg`
4. **Restart** Valheim

## Configuration

The model path is configured in `BepInEx/config/LlamaVillagers.cfg`:

```ini
[AI]
ModelPath = BepInEx/plugins/LlamaVillagers/models/phi-2-q4_k_m.gguf
```

## Performance Tips

- **CPU-only**: Models run on CPU by default for compatibility
- **Memory**: Ensure you have enough RAM (2-4GB recommended)
- **Loading**: First load may take 30-60 seconds
- **Caching**: Responses are cached to improve performance

## Troubleshooting

- **Model not found**: Check the file path in configuration
- **Out of memory**: Try a smaller model (TinyLlama)
- **Slow responses**: This is normal for CPU inference
- **No dialogue**: Check BepInEx logs for errors
