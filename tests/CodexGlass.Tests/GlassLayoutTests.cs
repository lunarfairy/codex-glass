using CodexGlass.Presentation;

namespace CodexGlass.Tests;

public sealed class GlassLayoutTests
{
    [Fact]
    public void UsesLightAppleCapsuleDimensions()
    {
        Assert.Equal(184, GlassLayout.Width);
        Assert.Equal(56, GlassLayout.CollapsedHeight);
        Assert.Equal(88, GlassLayout.ExpandedHeight);
    }
}
