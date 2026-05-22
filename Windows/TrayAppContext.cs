using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace PCNoShitaNoChikaramochi;

public class TrayAppContext : ApplicationContext
{
    private readonly NotifyIcon _trayIcon = new();
    private readonly MemoryMonitor _monitor = new();
    private readonly CharacterAnimator _animator = new();
    private readonly AppearanceStore _appearance = AppearanceStore.Load();
    private SettingsForm? _settingsForm;

    private readonly Timer _renderTimer = new() { Interval = 66 };  // ~15 fps
    private readonly Timer _sampleTimer = new() { Interval = 1000 };

    private ToolStripMenuItem? _usageItem;
    private ToolStripMenuItem? _stateItem;

    private IntPtr _lastIconHandle = IntPtr.Zero;

    public TrayAppContext()
    {
        _trayIcon.Visible = true;
        _trayIcon.Text = "PCの下の力持ち";
        BuildContextMenu();

        _sampleTimer.Tick += (_, _) => Sample();
        _sampleTimer.Start();

        _renderTimer.Tick += (_, _) => RenderFrame();
        _renderTimer.Start();

        Sample();
        RenderFrame();
    }

    private void Sample()
    {
        _monitor.Sample();
        _animator.Update(_monitor.UsagePercent);

        var totalGB = _monitor.TotalBytes / 1_073_741_824.0;
        var usedGB = _monitor.UsedBytes / 1_073_741_824.0;
        if (_usageItem != null)
            _usageItem.Text = $"メモリ: {_monitor.UsagePercent:F1}% ({usedGB:F1} / {totalGB:F1} GB)";
        if (_stateItem != null)
            _stateItem.Text = $"状態: {_animator.State.Label()}";

        _trayIcon.Text = TruncateForBalloon($"PCの下の力持ち\nメモリ {_monitor.UsagePercent:F0}% — {_animator.State.Label()}");
    }

    /// <summary>NotifyIcon.Text は 63文字までの制限がある (Win10以降は緩い場合も)。</summary>
    private static string TruncateForBalloon(string s)
    {
        return s.Length <= 63 ? s : s[..63];
    }

    private void RenderFrame()
    {
        _animator.Tick();
        using var bitmap = CharacterRenderer.Render(_animator.State, _animator.Phase, _appearance.Snapshot(), 64);

        // GetHicon() のハンドル所有権:
        //   - hIcon: bitmap が作った HICON。Icon.FromHandle はこのハンドルを所有しない
        //   - Clone() は内部で新しい HICON を作って所有する → これを NotifyIcon に渡す
        //   - 元 hIcon は不要なので DestroyIcon、前フレームの Icon は Dispose
        var hIcon = bitmap.GetHicon();
        Icon newIcon;
        try
        {
            using var wrapper = Icon.FromHandle(hIcon);
            newIcon = (Icon)wrapper.Clone();
        }
        finally
        {
            DestroyIcon(hIcon);
        }

        var old = _trayIcon.Icon;
        _trayIcon.Icon = newIcon;
        old?.Dispose();
    }

    private void BuildContextMenu()
    {
        var menu = new ContextMenuStrip();
        menu.Renderer = new ToolStripProfessionalRenderer();

        _usageItem = new ToolStripMenuItem("メモリ: --%") { Enabled = false };
        _stateItem = new ToolStripMenuItem("状態: --") { Enabled = false };
        menu.Items.Add(_usageItem);
        menu.Items.Add(_stateItem);
        menu.Items.Add(new ToolStripSeparator());

        var settings = new ToolStripMenuItem("設定...", null, (_, _) => OpenSettings())
        {
            ShortcutKeys = Keys.Control | Keys.OemComma,
            ShowShortcutKeys = true
        };
        menu.Items.Add(settings);

        var about = new ToolStripMenuItem("PCの下の力持ち について", null, (_, _) => ShowAbout());
        menu.Items.Add(about);

        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem("終了", null, (_, _) => ExitApp()));

        _trayIcon.ContextMenuStrip = menu;
        _trayIcon.MouseClick += (_, e) =>
        {
            if (e.Button == MouseButtons.Left)
            {
                OpenSettings();
            }
        };
    }

    private void OpenSettings()
    {
        if (_settingsForm == null || _settingsForm.IsDisposed)
        {
            _settingsForm = new SettingsForm(_appearance, _monitor, _animator);
        }
        if (!_settingsForm.Visible) _settingsForm.Show();
        _settingsForm.WindowState = FormWindowState.Normal;
        _settingsForm.Activate();
        _settingsForm.BringToFront();
    }

    private void ShowAbout()
    {
        MessageBox.Show(
            "PCの下の力持ち\n\nメモリの使用率に応じてキャラがダンベルやバーベルを上げ下げします。\nタスクバーで PC を支えてくれる小さな力持ちです。",
            "PCの下の力持ち について",
            MessageBoxButtons.OK,
            MessageBoxIcon.Information
        );
    }

    private void ExitApp()
    {
        _trayIcon.Visible = false;
        _sampleTimer.Stop();
        _renderTimer.Stop();
        _settingsForm?.Close();
        _trayIcon.Dispose();
        Application.Exit();
    }

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyIcon(IntPtr handle);
}
