using BepInEx.Configuration;

namespace OmnivoreConfig {

  public interface IConfigEntry {
    object? GetValue();
  }

  public class ConfigEntryWrapper<T> : IConfigEntry {
    private readonly ConfigEntry<T> _entry;
    public ConfigEntryWrapper(ConfigEntry<T> entry) {
      _entry = entry;
    }
    public object? GetValue() => _entry.Value;
  }

  public interface IOmnivoreConfigEntry {
    public ConfigDefinition Definition { get; set; }
    public ConfigDescription Description { get; set; }
    public object? DefaultValue { get; set; }
  }

  public class OmnivoreConfigEntry<T> : IOmnivoreConfigEntry {
    public OmnivoreConfigEntry(ConfigDefinition definition, ConfigDescription description, object defaultValue) {
      Definition = definition;
      Description = description;
      DefaultValue = defaultValue;
    }

    public ConfigDefinition Definition { get; set; }
    public ConfigDescription Description { get; set; }
    public object? DefaultValue { get; set; }
  }

  /**
   * Extends the OmnivoreConfigEntry class to handle integer values specifically supporting min and max.
   */
  public class IntConfig : OmnivoreConfigEntry<int> {
    public IntConfig(ConfigDefinition definition, ConfigDescription description, object defaultValue, int? max = null, int? min = null) 
      : base(
          definition, 
          description,  
          max != null && (int)defaultValue > max 
            ? max 
            : 
            min != null && (int)defaultValue < min 
              ? min 
              : defaultValue
       ) {}
  }

  public static class ConfigDictionaryExtensions {
    public static T? GetConfigValue<T>(this Dictionary<Enum, IConfigEntry> dictionary, Enum key) {
      if (dictionary.TryGetValue(key, out var entry) && entry is ConfigEntry<T> typedEntry) {
        return typedEntry.Value;
      }
      throw new InvalidCastException($"Configuration entry for '{key}' is not of type {typeof(T).Name}");
    }

    public static OmnivoreConfigEntry<T>? GetEntry<T>(this Dictionary<Enum, IOmnivoreConfigEntry> dictionary, Enum key) {
      if (dictionary.TryGetValue(key, out var entry) && entry.DefaultValue is OmnivoreConfigEntry<T> typedEntry) {
        return typedEntry;
      }
      throw new InvalidCastException($"Configuration definition for '{key}' is not of type {typeof(T).Name}");
    }
  }

  public static class Cfg {
    public static Dictionary<Enum, IConfigEntry> Init(this Dictionary<Enum, IOmnivoreConfigEntry> configurationOptions, ConfigFile Config) {
      
      Dictionary<Enum, IConfigEntry> cfg = new() { };

      foreach (var entry in configurationOptions) {
        var key = entry.Key;
        var omnivoreEntry = entry.Value;

        // Using reflection to bind the config entry with the correct generic type
        var bindMethod = typeof(ConfigFile).GetMethod("Bind", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

        if (bindMethod == null) {
          throw new InvalidOperationException("Could not find the bindConfigEntry method.");
        }

        // Get the type parameter from the entry (OmnivoreConfigEntry<int> -> int)
        var genericType = omnivoreEntry.GetType().GenericTypeArguments[0];

        // Create a generic method for the specific type
        var genericBindMethod = bindMethod.MakeGenericMethod(genericType);

        // Invoke the method and get the ConfigEntry
        var configEntry = genericBindMethod.Invoke(null, new object[] { omnivoreEntry });

        if (configEntry is IConfigEntry wrappedEntry) {
          // Add to the dictionary with our wrapper
          cfg[key] = wrappedEntry;
        } else {
          throw new InvalidCastException($"Failed to cast the configuration entry for '{key}' to IConfigEntry.");
        }
      }
      return cfg;
    }
  }
}