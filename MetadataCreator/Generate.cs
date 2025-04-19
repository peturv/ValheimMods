using System.Reflection;
using BepInEx;
using Newtonsoft.Json;
/*
 * TODO:

  GUID normalization: BepInEx uses com.example.modname, but Thunderstore expects Author-ModName-Version. Might need to be mapped appropriately.
  Website URL: Could also use [assembly: AssemblyMetadata("Website", "https://...")].


*/
var targetAssembly = args[0];
var destinationFolder = args[1].TrimEnd('/').TrimEnd('\\');
var outputPath = $"{destinationFolder}/manifest.json";

var asm = Assembly.LoadFrom(targetAssembly);

// --- Extract main plugin info ---
var pluginType = typeof(BepInPlugin);
// var depType = typeof(BepInDependency);

var mainPlugin = asm.GetTypes()
    .Select(t => new {
      Type = t,
      Plugin = t.GetCustomAttribute<BepInPlugin>(),
      Dependencies = t.GetCustomAttributes<BepInDependency>().ToArray()
    })
    .FirstOrDefault(x => x.Plugin != null);

if (mainPlugin == null) {
  Console.Error.WriteLine("No BepInPlugin attribute found.");
  Environment.Exit(1);
}

// --- Build dependency strings (in Thunderstore format) --
/*
var deps = mainPlugin.Dependencies
  .Select(d => 
    $"{d.DependencyGUID.Replace('.', '-')}-{d.MinimumVersion?.ToString() ?? "0.0.0"}"
  ).ToList();
*/
var deps = asm.GetCustomAttributes<AssemblyMetadataAttribute>()?.Where(a => a.Key == "dependencies" && a.Value != null)
  .SelectMany(a => a?.Value?.Split(',') ?? Array.Empty<string>())
  .Select(d => d.Trim())
  .ToList();

// --- Build final JSON ---
var metadata = new {
  name = mainPlugin!.Plugin!.Name,
  version_number = mainPlugin.Plugin.Version,
  website_url = $"https://github.com/peturv/ValheimMods/{mainPlugin.Plugin.Name}",
  description = asm.GetCustomAttribute<AssemblyDescriptionAttribute>()?.Description ?? "",
  dependencies = deps
};

File.WriteAllText(outputPath, JsonConvert.SerializeObject(metadata, Formatting.Indented));