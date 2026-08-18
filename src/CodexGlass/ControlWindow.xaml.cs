using System.Windows;

namespace CodexGlass;

public partial class ControlWindow : Window
{
    private bool _isLoading;

    public event Action<bool>? OverlayEnabledChanged;
    public event Action<bool>? StartupEnabledChanged;

    public ControlWindow(bool isOverlayEnabled, bool isStartupEnabled)
    {
        InitializeComponent();
        SetStates(isOverlayEnabled, isStartupEnabled);
    }

    public void SetStates(bool isOverlayEnabled, bool isStartupEnabled)
    {
        _isLoading = true;
        OverlayToggle.IsChecked = isOverlayEnabled;
        StartupToggle.IsChecked = isStartupEnabled;
        _isLoading = false;
    }

    public void SetStatus(string status) => StatusText.Text = status;

    private void OnOverlayToggleChanged(object sender, RoutedEventArgs e)
    {
        if (!_isLoading)
        {
            OverlayEnabledChanged?.Invoke(OverlayToggle.IsChecked == true);
        }
    }

    private void OnStartupToggleChanged(object sender, RoutedEventArgs e)
    {
        if (!_isLoading)
        {
            StartupEnabledChanged?.Invoke(StartupToggle.IsChecked == true);
        }
    }

    private void OnCloseClick(object sender, RoutedEventArgs e) => Close();
}
