using CodexGlass.Presentation;

namespace CodexGlass.Tests;

public sealed class GlassLayoutTests
{
    [Fact]
    public void UsesCompactCollapsedAndExpandedDimensions()
    {
        Assert.Equal(280, GlassLayout.Width);
        Assert.Equal(54, GlassLayout.CollapsedHeight);
        Assert.Equal(92, GlassLayout.ExpandedHeight);
    }
}
