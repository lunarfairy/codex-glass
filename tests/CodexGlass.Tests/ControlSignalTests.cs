using CodexGlass.Control;

namespace CodexGlass.Tests;

public sealed class ControlSignalTests
{
    [Fact]
    public void TrySignalOpenController_SignalsTheHostEvent()
    {
        var eventName = $"Local\\CodexGlass.Tests.{Guid.NewGuid():N}";
        using var signal = new ControlSignal(eventName);

        Assert.True(ControlSignal.TrySignalOpenController(eventName));
        Assert.True(signal.Wait(TimeSpan.FromSeconds(1)));
    }
}
