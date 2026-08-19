using System.ComponentModel;
using System.Runtime.CompilerServices;
using CodexGlass.Quota;

namespace CodexGlass.ViewModels;

public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _weeklyPercent = "—";
    private string _weeklyReset = "—";
    private double _weeklyProgress;
    private bool _isStale;

    public event PropertyChangedEventHandler? PropertyChanged;

    public string WeeklyPercent { get => _weeklyPercent; private set => Set(ref _weeklyPercent, value); }
    public string WeeklyReset { get => _weeklyReset; private set => Set(ref _weeklyReset, value); }
    public double WeeklyProgress { get => _weeklyProgress; private set => Set(ref _weeklyProgress, value); }
    public bool IsStale { get => _isStale; private set => Set(ref _isStale, value); }

    public void Apply(QuotaSnapshot snapshot, DateTimeOffset now)
    {
        WeeklyPercent = $"{snapshot.Weekly.RemainingPercent}%";
        WeeklyProgress = snapshot.Weekly.RemainingPercent / 100d;
        var countdown = CountdownFormatter.Format(snapshot.Weekly.ResetsAt, now);
        WeeklyReset = countdown switch
        {
            "—" => "—",
            "即将重置" => countdown,
            _ => $"{countdown}后重置"
        };
        IsStale = false;
    }

    public void MarkStale() => IsStale = true;

    public void MarkUnavailable()
    {
        IsStale = true;
        if (WeeklyPercent == "—")
        {
            WeeklyReset = "请先登录 Codex";
        }
    }

    private void Set<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value))
        {
            return;
        }

        field = value;
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
