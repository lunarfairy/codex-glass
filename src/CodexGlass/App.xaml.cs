using System.IO;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using CodexGlass.AppServer;
using CodexGlass.Configuration;
using CodexGlass.Desktop;
using CodexGlass.Quota;
using CodexGlass.ViewModels;

namespace CodexGlass;

public partial class App : Application
{
    private Mutex? _mutex;
    private MainWindow? _window;
    private MainViewModel? _viewModel;
    private CodexDesktopWatcher? _watcher;
    private DispatcherTimer? _timer;
    private AppServerProcess? _server;
    private QuotaSnapshot? _snapshot;
    private DateTimeOffset _lastRefresh = DateTimeOffset.MinValue;
    private DateTimeOffset _nextRetry = DateTimeOffset.MinValue;
    private bool _checking;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        ShutdownMode = ShutdownMode.OnExplicitShutdown;

        if (e.Args.Contains("--register-startup", StringComparer.OrdinalIgnoreCase))
        {
            StartupRegistration.Ensure(Environment.ProcessPath!);
            Shutdown();
            return;
        }

        _mutex = new Mutex(initiallyOwned: true, "Local\\CodexGlass.SingleInstance", out var isFirstInstance);
        if (!isFirstInstance)
        {
            Shutdown();
            return;
        }

        var settingsPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "CodexGlass",
            "settings.json");
        _viewModel = new MainViewModel();
        _watcher = new CodexDesktopWatcher();
        _window = new MainWindow(_viewModel, new SettingsStore(settingsPath));

        _timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2) };
        _timer.Tick += async (_, _) => await CheckAsync();
        _timer.Start();
        Dispatcher.BeginInvoke(async () => await CheckAsync());
    }

    private async Task CheckAsync()
    {
        if (_checking || _watcher is null || _window is null || _viewModel is null)
        {
            return;
        }

        _checking = true;
        try
        {
            if (!_watcher.IsRunning())
            {
                _window.Hide();
                await StopServerAsync();
                return;
            }

            if (!_window.IsVisible)
            {
                _window.Show();
            }

            var now = DateTimeOffset.Now;
            if (_snapshot is not null)
            {
                _viewModel.Apply(_snapshot, now);
            }

            if (now - _lastRefresh < TimeSpan.FromMinutes(1) || now < _nextRetry)
            {
                return;
            }

            try
            {
                _server ??= await AppServerProcess.StartAsync(CancellationToken.None);
                _snapshot = await _server.ReadQuotaAsync(CancellationToken.None);
                _lastRefresh = now;
                _viewModel.Apply(_snapshot, now);
            }
            catch
            {
                _viewModel.MarkStale();
                _nextRetry = now.AddSeconds(15);
                await StopServerAsync();
            }
        }
        finally
        {
            _checking = false;
        }
    }

    private async Task StopServerAsync()
    {
        if (_server is null)
        {
            return;
        }

        await _server.DisposeAsync();
        _server = null;
        _lastRefresh = DateTimeOffset.MinValue;
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _timer?.Stop();
        if (_server is not null)
        {
            _server.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }

        _mutex?.ReleaseMutex();
        _mutex?.Dispose();
        base.OnExit(e);
    }
}
