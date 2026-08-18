using CodexGlass.Configuration;

namespace CodexGlass.Tests;

public sealed class SettingsStoreTests
{
    [Fact]
    public void SaveAndLoad_RoundTripsWindowPosition()
    {
        var directory = Path.Combine(Path.GetTempPath(), $"CodexGlassTests-{Guid.NewGuid():N}");
        var path = Path.Combine(directory, "settings.json");

        try
        {
            var store = new SettingsStore(path);
            store.Save(new GlassSettings(123.5, 48.25));

            Assert.Equal(new GlassSettings(123.5, 48.25), store.Load());
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }

    [Fact]
    public void Load_ReturnsDefaultForMissingFile()
    {
        var path = Path.Combine(Path.GetTempPath(), $"missing-{Guid.NewGuid():N}", "settings.json");

        Assert.Equal(GlassSettings.Default, new SettingsStore(path).Load());
    }
}
