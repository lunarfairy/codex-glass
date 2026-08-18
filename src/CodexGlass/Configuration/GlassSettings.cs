namespace CodexGlass.Configuration;

public sealed record GlassSettings(double? Left, double? Top, bool IsOverlayEnabled = true)
{
    public static GlassSettings Default { get; } = new(null, null, true);
}
