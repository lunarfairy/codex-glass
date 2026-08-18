using System.IO;
using System.Text.Json;

namespace CodexGlass.Configuration;

public sealed class SettingsStore(string path)
{
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    public GlassSettings Load()
    {
        if (!File.Exists(path))
        {
            return GlassSettings.Default;
        }

        return JsonSerializer.Deserialize<GlassSettings>(File.ReadAllText(path)) ?? GlassSettings.Default;
    }

    public void Save(GlassSettings settings)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path, JsonSerializer.Serialize(settings, JsonOptions));
    }
}
