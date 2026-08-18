using System.ComponentModel;
using System.Runtime.CompilerServices;
using CodexGlass.Quota;

namespace CodexGlass.ViewModels;

public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _fiveHourPercent = "—";
    private string _weeklyPercent = "—";
    private string _fiveHourReset = "—";
    private string _weeklyReset = "—";
    private bool _isStale;

    public event PropertyChangedEventHandler? PropertyChanged;

    public string FiveHourPercent { get => _fiveHourPercent; private set => Set(ref _fiveHourPercent, value); }
    public string WeeklyPercent { get => _weeklyPercent; private set => Set(ref _weeklyPercent, value); }
    public string FiveHourReset { get => _fiveHourReset; private set => Set(ref _fiveHourReset, value); }
    public string WeeklyReset { get => _weeklyReset; private set => Set(ref _weeklyReset, value); }
    public bool IsStale { get => _isStale; private set => Set(ref _isStale, value); }

    public void Apply(QuotaSnapshot snapshot, DateTimeOffset now)
    {
        FiveHourPercent = $"{snapshot.FiveHour.RemainingPercent}%";
        WeeklyPercent = $"{snapshot.Weekly.RemainingPercent}%";
        FiveHourReset = CountdownFormatter.Format(snapshot.FiveHour.ResetsAt, now);
        WeeklyReset = CountdownFormatter.Format(snapshot.Weekly.ResetsAt, now);
        IsStale = false;
    }

    public void MarkStale() => IsStale = true;

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
