using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media.Animation;
using CodexGlass.Configuration;
using CodexGlass.Presentation;
using CodexGlass.ViewModels;

namespace CodexGlass;

public partial class MainWindow : Window
{
    private readonly SettingsStore _settings;

    public MainWindow(MainViewModel viewModel, SettingsStore settings)
    {
        InitializeComponent();
        DataContext = viewModel;
        _settings = settings;
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        var settings = _settings.Load();
        if (settings.Left is double left && settings.Top is double top && IsOnVirtualScreen(left, top))
        {
            Left = left;
            Top = top;
            return;
        }

        var workArea = SystemParameters.WorkArea;
        Left = workArea.Right - Width - 24;
        Top = workArea.Top + 24;
    }

    private void OnSourceInitialized(object? sender, EventArgs e)
    {
        GlassBackdrop.Apply(new WindowInteropHelper(this).Handle);
    }

    private void OnMouseEnter(object sender, MouseEventArgs e) => AnimateHeight(GlassLayout.ExpandedHeight);

    private void OnMouseLeave(object sender, MouseEventArgs e) => AnimateHeight(GlassLayout.CollapsedHeight);

    private void AnimateHeight(double target)
    {
        BeginAnimation(HeightProperty, new DoubleAnimation(target, TimeSpan.FromMilliseconds(150))
        {
            EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseOut }
        });
    }

    private void OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState != MouseButtonState.Pressed)
        {
            return;
        }

        DragMove();
        _settings.Save(new GlassSettings(Left, Top));
    }

    private static bool IsOnVirtualScreen(double left, double top) =>
        left >= SystemParameters.VirtualScreenLeft - GlassLayout.Width &&
        left <= SystemParameters.VirtualScreenLeft + SystemParameters.VirtualScreenWidth &&
        top >= SystemParameters.VirtualScreenTop - GlassLayout.CollapsedHeight &&
        top <= SystemParameters.VirtualScreenTop + SystemParameters.VirtualScreenHeight;
}
