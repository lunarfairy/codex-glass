using System.Threading;

namespace CodexGlass.Control;

public sealed class ControlSignal : IDisposable
{
    public const string DefaultEventName = "Local\\CodexGlass.OpenController";

    private readonly EventWaitHandle _event;

    public ControlSignal(string eventName = DefaultEventName)
    {
        _event = new EventWaitHandle(false, EventResetMode.AutoReset, eventName);
    }

    public bool Wait(TimeSpan timeout) => _event.WaitOne(timeout);

    public static bool TrySignalOpenController(string eventName = DefaultEventName)
    {
        try
        {
            using var signal = EventWaitHandle.OpenExisting(eventName);
            return signal.Set();
        }
        catch (WaitHandleCannotBeOpenedException)
        {
            return false;
        }
    }

    public void Dispose() => _event.Dispose();
}
