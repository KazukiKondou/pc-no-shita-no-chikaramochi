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

    public static AppearanceStore Load()
    {
        try
        {
            var path = SettingsPath();
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

    public void Save()
    {
        try
        {
            var path = SettingsPath();
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
