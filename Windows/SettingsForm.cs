using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace PCNoShitaNoChikaramochi;

public class SettingsForm : Form
{
    private readonly AppearanceStore _store;
    private readonly MemoryMonitor _monitor;
    private readonly CharacterAnimator _animator;

    private readonly PictureBox _preview = new();
    private readonly Label _stateLabel = new();
    private readonly Label _memLabel = new();
    private readonly System.Windows.Forms.Timer _renderTimer = new();

    private readonly List<RadioButton> _genderRadios = new();
    private readonly List<SwatchButton> _skinSwatches = new();
    private readonly List<SwatchButton> _shirtSwatches = new();

    public SettingsForm(AppearanceStore store, MemoryMonitor monitor, CharacterAnimator animator)
    {
        _store = store;
        _monitor = monitor;
        _animator = animator;

        Text = "PCの下の力持ち の設定";
        ClientSize = new Size(620, 380);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font(SystemFonts.MessageBoxFont!.FontFamily, 9.5f);

        BuildLayout();
        Refresh();

        _renderTimer.Interval = 66;
        _renderTimer.Tick += (_, _) => RefreshPreview();
        _renderTimer.Start();

        FormClosed += (_, _) =>
        {
            _renderTimer.Stop();
            _renderTimer.Dispose();
            var prev = _preview.Image;
            _preview.Image = null;
            prev?.Dispose();
        };
    }

    private void BuildLayout()
    {
        // --- Preview (left) ---
        var previewPanel = new Panel
        {
            Location = new Point(16, 16),
            Size = new Size(180, 220),
            BorderStyle = BorderStyle.FixedSingle,
            BackColor = Color.White
        };
        _preview.Dock = DockStyle.Fill;
        _preview.SizeMode = PictureBoxSizeMode.Zoom;
        previewPanel.Controls.Add(_preview);
        Controls.Add(previewPanel);

        _stateLabel.Location = new Point(16, 240);
        _stateLabel.AutoSize = true;
        _stateLabel.ForeColor = SystemColors.GrayText;
        Controls.Add(_stateLabel);

        _memLabel.Location = new Point(16, 258);
        _memLabel.AutoSize = true;
        _memLabel.ForeColor = SystemColors.GrayText;
        Controls.Add(_memLabel);

        // --- Right column ---
        int rx = 216;
        int ry = 16;

        AddHeader("性別", rx, ry);
        ry += 24;

        var genderPanel = new FlowLayoutPanel
        {
            Location = new Point(rx, ry),
            Size = new Size(380, 28),
            FlowDirection = FlowDirection.LeftToRight,
            WrapContents = false
        };
        foreach (Gender g in Enum.GetValues<Gender>())
        {
            var rb = new RadioButton
            {
                Text = AppearanceColors.LabelOf(g),
                AutoSize = true,
                Checked = _store.Gender == g,
                Tag = g,
                Margin = new Padding(0, 4, 18, 0)
            };
            rb.CheckedChanged += (_, _) =>
            {
                if (rb.Checked)
                {
                    _store.Apply(s => s.Gender = (Gender)rb.Tag!);
                }
            };
            _genderRadios.Add(rb);
            genderPanel.Controls.Add(rb);
        }
        Controls.Add(genderPanel);
        ry += 36;

        AddHeader("肌の色", rx, ry);
        ry += 24;

        var skinPanel = new FlowLayoutPanel
        {
            Location = new Point(rx, ry),
            Size = new Size(380, 44),
            FlowDirection = FlowDirection.LeftToRight,
            WrapContents = false
        };
        foreach (SkinTone t in Enum.GetValues<SkinTone>())
        {
            var swatch = new SwatchButton(AppearanceColors.Skin(t), AppearanceColors.LabelOf(t))
            {
                Tag = t,
                Selected = _store.SkinTone == t,
                Margin = new Padding(0, 0, 10, 0)
            };
            swatch.Clicked += (_, _) => _store.Apply(s => s.SkinTone = (SkinTone)swatch.Tag!);
            _skinSwatches.Add(swatch);
            skinPanel.Controls.Add(swatch);
        }
        Controls.Add(skinPanel);
        ry += 56;

        AddHeader("シャツの色", rx, ry);
        ry += 24;

        var shirtPanel = new FlowLayoutPanel
        {
            Location = new Point(rx, ry),
            Size = new Size(380, 90),
            FlowDirection = FlowDirection.LeftToRight,
            WrapContents = true
        };
        foreach (ShirtColor c in Enum.GetValues<ShirtColor>())
        {
            var swatch = new SwatchButton(AppearanceColors.Shirt(c), AppearanceColors.LabelOf(c))
            {
                Tag = c,
                Selected = _store.ShirtColor == c,
                Margin = new Padding(0, 0, 10, 10)
            };
            swatch.Clicked += (_, _) => _store.Apply(s => s.ShirtColor = (ShirtColor)swatch.Tag!);
            _shirtSwatches.Add(swatch);
            shirtPanel.Controls.Add(swatch);
        }
        Controls.Add(shirtPanel);

        // --- Bottom hint ---
        var hint = new Label
        {
            Text = "変更は即座にタスクバーへ反映されます。",
            Location = new Point(16, 350),
            AutoSize = true,
            ForeColor = SystemColors.GrayText,
            Font = new Font(Font.FontFamily, 8.5f)
        };
        Controls.Add(hint);

        _store.Changed += (_, _) => SyncSelections();
    }

    private void AddHeader(string text, int x, int y)
    {
        var lbl = new Label
        {
            Text = text,
            Location = new Point(x, y),
            AutoSize = true,
            Font = new Font(Font.FontFamily, 10f, FontStyle.Bold)
        };
        Controls.Add(lbl);
    }

    private void SyncSelections()
    {
        foreach (var rb in _genderRadios)
        {
            var matches = (Gender)rb.Tag! == _store.Gender;
            if (rb.Checked != matches) rb.Checked = matches;
        }
        foreach (var sw in _skinSwatches)
        {
            sw.Selected = (SkinTone)sw.Tag! == _store.SkinTone;
        }
        foreach (var sw in _shirtSwatches)
        {
            sw.Selected = (ShirtColor)sw.Tag! == _store.ShirtColor;
        }
    }

    private void RefreshPreview()
    {
        var bmp = CharacterRenderer.Render(_animator.State, _animator.Phase, _store.Snapshot(), 200);
        var old = _preview.Image;
        _preview.Image = bmp;
        old?.Dispose();

        _stateLabel.Text = $"状態: {_animator.State.Label()}";
        _memLabel.Text = $"メモリ: {_monitor.UsagePercent:F1}%";
    }
}

/// <summary>カラー swatch ボタン (Panel で自作)。</summary>
public class SwatchButton : Control
{
    private readonly Color _color;
    private bool _selected;
    private bool _hover;

    public event EventHandler? Clicked;
    public string ToolTipText { get; }

    public bool Selected
    {
        get => _selected;
        set { if (_selected != value) { _selected = value; Invalidate(); } }
    }

    public SwatchButton(Color color, string toolTipText)
    {
        _color = color;
        ToolTipText = toolTipText;
        Size = new Size(36, 36);
        SetStyle(ControlStyles.AllPaintingInWmPaint
               | ControlStyles.UserPaint
               | ControlStyles.ResizeRedraw
               | ControlStyles.OptimizedDoubleBuffer
               | ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
        Cursor = Cursors.Hand;
        var tip = new ToolTip();
        tip.SetToolTip(this, toolTipText);
    }

    protected override void OnMouseEnter(EventArgs e) { _hover = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { _hover = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnClick(EventArgs e) { Clicked?.Invoke(this, EventArgs.Empty); base.OnClick(e); }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        var inset = _selected ? 2 : 1;
        var rect = new Rectangle(inset, inset, Width - inset * 2 - 1, Height - inset * 2 - 1);

        using (var brush = new SolidBrush(_color)) g.FillEllipse(brush, rect);

        var borderColor = _selected ? SystemColors.Highlight : (_hover ? Color.Gray : Color.LightGray);
        using (var pen = new Pen(borderColor, _selected ? 3f : 1f)) g.DrawEllipse(pen, rect);

        if (_selected)
        {
            // チェックマーク
            using var pen = new Pen(Color.White, 2.4f) { StartCap = System.Drawing.Drawing2D.LineCap.Round, EndCap = System.Drawing.Drawing2D.LineCap.Round };
            float cx = Width / 2f;
            float cy = Height / 2f;
            g.DrawLines(pen, new[] {
                new PointF(cx - 6, cy),
                new PointF(cx - 1, cy + 5),
                new PointF(cx + 7, cy - 5)
            });
        }
    }
}
