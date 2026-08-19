using System.IO;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using CodexGlass.AppServer;
using CodexGlass.Configuration;
using CodexGlass.Control;
using CodexGlass.Desktop;
using CodexGlass.Quota;
using CodexGlass.ViewModels;

namespace CodexGlass;

public partial class App : Application
{
    private Mutex? _mutex;
    private SettingsStore? _settingsStore;
    private GlassSettings _settings = GlassSettings.Default;
    private MainWindow? _window;
    private ControlWindow? _controlWindow;
    private ControlSignal? _controlSignal;
    private CancellationTokenSource? _controlListenerCancellation;
    private MainViewModel? _viewModel;
    private CodexDesktopWatcher? _watcher;
    private DispatcherTimer? _timer;
    private AppServerProcess? _server;
    private QuotaSnapshot? _snapshot;
    private DateTimeOffset _lastRefresh = DateTimeOffset.MinValue;
    private DateTimeOffset _nextRetry = DateTimeOffset.MinValue;
    private bool _checking;
    private string _quotaStatus = "正在读取 Codex 额度";

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

        var shouldOpenController = e.Args.Contains("--control", StringComparer.OrdinalIgnoreCase);
        if (shouldOpenController && ControlSignal.TrySignalOpenController())
        {
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
        _settingsStore = new SettingsStore(settingsPath);
        _settings = _settingsStore.Load();
        _viewModel = new MainViewModel();
        _watcher = new CodexDesktopWatcher();
        _window = new MainWindow(_viewModel, _settingsStore);
        _controlSignal = new ControlSignal();
        _controlListenerCancellation = new CancellationTokenSource();
        StartControlListener(_controlListenerCancellation.Token);

        _timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2) };
        _timer.Tick += async (_, _) => await CheckAsync();
        _timer.Start();
        Dispatcher.BeginInvoke(async () => await CheckAsync());
        if (shouldOpenController)
        {
            Dispatcher.BeginInvoke(ShowControlWindow);
        }
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
            if (!_settings.IsOverlayEnabled)
            {
                _window.Hide();
                await StopServerAsync();
                return;
            }

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
                _quotaStatus = "额度已更新";
            }
            catch
            {
                if (_snapshot is null)
                {
                    _viewModel.MarkUnavailable();
                }
                else
                {
                    _viewModel.MarkStale();
                }

                _quotaStatus = "无法读取额度：请打开 Codex 桌面端并确认已登录";
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

    private void StartControlListener(CancellationToken cancellationToken)
    {
        _ = Task.Run(() =>
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    if (_controlSignal?.Wait(TimeSpan.FromMilliseconds(250)) == true)
                    {
                        Dispatcher.BeginInvoke(ShowControlWindow);
                    }
                }
                catch (ObjectDisposedException)
                {
                    return;
                }
            }
        }, cancellationToken);
    }

    private void ShowControlWindow()
    {
        if (_controlWindow is null)
        {
            _controlWindow = new ControlWindow(_settings.IsOverlayEnabled, StartupRegistration.IsEnabled());
            _controlWindow.OverlayEnabledChanged += SetOverlayEnabled;
            _controlWindow.StartupEnabledChanged += SetStartupEnabled;
            _controlWindow.Closed += (_, _) => _controlWindow = null;
            _controlWindow.SetStatus(_quotaStatus);
            _controlWindow.Show();
            return;
        }

        _controlWindow.SetStates(_settings.IsOverlayEnabled, StartupRegistration.IsEnabled());
        _controlWindow.SetStatus(_quotaStatus);
        _controlWindow.Show();
        _controlWindow.Activate();
    }

    private void SetOverlayEnabled(bool isEnabled)
    {
        _settings = (_settingsStore?.Load() ?? _settings) with { IsOverlayEnabled = isEnabled };
        _settingsStore?.Save(_settings);
        _controlWindow?.SetStatus(isEnabled ? "悬浮条已开启" : "悬浮条已关闭");

        if (isEnabled)
        {
            _ = CheckAsync();
        }
        else
        {
            _window?.Hide();
            _ = StopServerAsync();
        }
    }

    private void SetStartupEnabled(bool isEnabled)
    {
        try
        {
            if (isEnabled)
            {
                StartupRegistration.Ensure(Environment.ProcessPath!);
            }
            else
            {
                StartupRegistration.Disable();
            }

            _controlWindow?.SetStatus(isEnabled ? "开机自启已开启" : "开机自启已关闭");
        }
        catch
        {
            _controlWindow?.SetStates(_settings.IsOverlayEnabled, StartupRegistration.IsEnabled());
            _controlWindow?.SetStatus("无法修改开机自启设置");
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _timer?.Stop();
        _controlListenerCancellation?.Cancel();
        _controlSignal?.Dispose();
        if (_server is not null)
        {
            _server.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }

        _mutex?.ReleaseMutex();
        _mutex?.Dispose();
        base.OnExit(e);
    }
}
