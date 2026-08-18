using CodexGlass.Presentation;

namespace CodexGlass.Tests;

public sealed class GlassLayoutTests
{
    [Fact]
    public void UsesCompactWeeklyCapsuleDimensions()
    {
        Assert.Equal(176, GlassLayout.Width);
        Assert.Equal(52, GlassLayout.CollapsedHeight);
        Assert.Equal(82, GlassLayout.ExpandedHeight);
    }
}
