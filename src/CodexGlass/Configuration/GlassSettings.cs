namespace CodexGlass.Configuration;

public sealed record GlassSettings(double? Left, double? Top)
{
    public static GlassSettings Default { get; } = new(null, null);
}
