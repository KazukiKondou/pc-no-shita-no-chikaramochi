using System;
using System.IO;
using System.Text.Json;

namespace PCNoShitaNoChikaramochi;

/// <summary>
/// %APPDATA%/PCNoShitaNoChikaramochi/appearance.json に設定を永続化する。
/// </summary>
public class AppearanceStore
{
    public Gender Gender { get; set; } = Gender.Male;
    public SkinTone SkinTone { get; set; } = SkinTone.Light;
    public ShirtColor ShirtColor { get; set; } = ShirtColor.Red;

    // 設定変更通知 (JSON シリアライズ対象ではない)
    public event EventHandler? Changed;

    public AppearanceSnapshot Snapshot() => new(Gender, SkinTone, ShirtColor);

    public void Apply(Action<AppearanceStore> mutate)
    {
        mutate(this);
        Save();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public static AppearanceStore Load() => Load(SettingsPath());

    /// <summary>指定パスから読み込む。読めない/壊れている場合はデフォルトを返す。</summary>
    public static AppearanceStore Load(string path)
    {
        try
        {
            if (File.Exists(path))
            {
                var json = File.ReadAllText(path);
                var loaded = JsonSerializer.Deserialize<AppearanceStore>(json);
                if (loaded != null) return loaded;
            }
        }
        catch
        {
            // 壊れていたらデフォルトに戻す
        }
        return new AppearanceStore();
    }

    public void Save() => Save(SettingsPath());

    /// <summary>指定パスへ保存する。失敗してもアプリは続行する。</summary>
    public void Save(string path)
    {
        try
        {
            var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(path, json);
        }
        catch
        {
            // 書き込み失敗してもアプリは続行
        }
    }

    private static string SettingsPath()
    {
        var dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "PCNoShitaNoChikaramochi");
        Directory.CreateDirectory(dir);
        return Path.Combine(dir, "appearance.json");
    }
}
