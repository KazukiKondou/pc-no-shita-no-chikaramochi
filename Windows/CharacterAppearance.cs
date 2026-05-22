using System.Drawing;

namespace PCNoShitaNoChikaramochi;

public enum Gender { Male, Female }
public enum SkinTone { Porcelain, Light, Medium, Tan, Deep }
public enum ShirtColor { Red, Blue, Green, Purple, Orange, Black, White, Pink }

public record struct AppearanceSnapshot(Gender Gender, SkinTone SkinTone, ShirtColor ShirtColor);

public static class AppearanceColors
{
    public static Color Skin(SkinTone t) => t switch
    {
        SkinTone.Porcelain => Color.FromArgb(255, 235, 215),
        SkinTone.Light     => Color.FromArgb(255, 214, 168),
        SkinTone.Medium    => Color.FromArgb(219, 168, 128),
        SkinTone.Tan       => Color.FromArgb(179, 128,  89),
        SkinTone.Deep      => Color.FromArgb(107,  69,  46),
        _ => Color.Beige
    };

    public static Color SkinShade(SkinTone t) => t switch
    {
        SkinTone.Porcelain => Color.FromArgb(224, 189, 158),
        SkinTone.Light     => Color.FromArgb(199, 148, 107),
        SkinTone.Medium    => Color.FromArgb(158, 107,  71),
        SkinTone.Tan       => Color.FromArgb(122,  77,  46),
        SkinTone.Deep      => Color.FromArgb( 66,  38,  20),
        _ => Color.SaddleBrown
    };

    public static Color Shirt(ShirtColor c) => c switch
    {
        ShirtColor.Red    => Color.FromArgb(214, 41, 46),
        ShirtColor.Blue   => Color.FromArgb(46, 115, 217),
        ShirtColor.Green  => Color.FromArgb(56, 153, 89),
        ShirtColor.Purple => Color.FromArgb(128, 64, 191),
        ShirtColor.Orange => Color.FromArgb(242, 140, 46),
        ShirtColor.Black  => Color.FromArgb(38, 38, 43),
        ShirtColor.White  => Color.FromArgb(242, 242, 247),
        ShirtColor.Pink   => Color.FromArgb(242, 140, 179),
        _ => Color.Red
    };

    public static Color Plate(CharacterState s) => s switch
    {
        CharacterState.VeryEasy or CharacterState.Easy => Color.FromArgb(76, 166, 242),  // 軽い: 青
        CharacterState.Normal     => Color.FromArgb(102, 191, 102),                       // 中: 緑
        CharacterState.Heavy      => Color.FromArgb(242, 140, 51),                        // 重い: 橙
        CharacterState.Struggling => Color.FromArgb(230, 64, 64),                         // 超重: 赤
        CharacterState.Crushed    => Color.FromArgb(140, 26, 26),                         // 致死量: 暗赤
        _ => Color.Gray
    };

    public static Color Hair => Color.FromArgb(46, 31, 26);
    public static Color Shorts => Color.FromArgb(46, 46, 56);
    public static Color Bar => Color.FromArgb(199, 199, 209);

    public static string LabelOf(Gender g) => g switch
    {
        Gender.Male => "男性",
        Gender.Female => "女性",
        _ => "?"
    };

    public static string LabelOf(SkinTone t) => t switch
    {
        SkinTone.Porcelain => "とても明るい",
        SkinTone.Light     => "明るい",
        SkinTone.Medium    => "中間",
        SkinTone.Tan       => "小麦",
        SkinTone.Deep      => "濃い",
        _ => "?"
    };

    public static string LabelOf(ShirtColor c) => c switch
    {
        ShirtColor.Red    => "赤",
        ShirtColor.Blue   => "青",
        ShirtColor.Green  => "緑",
        ShirtColor.Purple => "紫",
        ShirtColor.Orange => "橙",
        ShirtColor.Black  => "黒",
        ShirtColor.White  => "白",
        ShirtColor.Pink   => "桃",
        _ => "?"
    };
}
