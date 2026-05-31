using System.Drawing;
using PCNoShitaNoChikaramochi;
using Xunit;

namespace PCNoShitaNoChikaramochi.Tests;

public class AppearanceColorsTests
{
    [Fact]
    public void Skin_AllTonesProduceOpaqueColor()
    {
        foreach (var tone in Enum.GetValues<SkinTone>())
        {
            Assert.Equal(255, AppearanceColors.Skin(tone).A);
            Assert.Equal(255, AppearanceColors.SkinShade(tone).A);
        }
    }

    [Fact]
    public void Shirt_AllColorsProduceOpaqueColor()
    {
        foreach (var c in Enum.GetValues<ShirtColor>())
        {
            Assert.Equal(255, AppearanceColors.Shirt(c).A);
        }
    }

    [Fact]
    public void Plate_AllStatesProduceColor()
    {
        foreach (var s in Enum.GetValues<CharacterState>())
        {
            Assert.NotEqual(Color.Empty, AppearanceColors.Plate(s));
        }
    }

    [Fact]
    public void LabelOf_GenderHasNonEmptyLabels()
    {
        foreach (var g in Enum.GetValues<Gender>())
        {
            Assert.False(string.IsNullOrEmpty(AppearanceColors.LabelOf(g)));
        }
    }

    [Fact]
    public void LabelOf_SkinToneAllUniqueAndNonEmpty()
    {
        var labels = Enum.GetValues<SkinTone>().Select(AppearanceColors.LabelOf).ToList();
        Assert.All(labels, l => Assert.False(string.IsNullOrEmpty(l)));
        Assert.Equal(labels.Count, labels.Distinct().Count());
    }

    [Fact]
    public void LabelOf_ShirtColorAllUniqueAndNonEmpty()
    {
        var labels = Enum.GetValues<ShirtColor>().Select(AppearanceColors.LabelOf).ToList();
        Assert.All(labels, l => Assert.False(string.IsNullOrEmpty(l)));
        Assert.Equal(labels.Count, labels.Distinct().Count());
    }
}

public class AppearanceSnapshotTests
{
    [Fact]
    public void Snapshot_RecordEqualityWorks()
    {
        var a = new AppearanceSnapshot(Gender.Female, SkinTone.Deep, ShirtColor.Pink);
        var b = new AppearanceSnapshot(Gender.Female, SkinTone.Deep, ShirtColor.Pink);
        var c = new AppearanceSnapshot(Gender.Male, SkinTone.Deep, ShirtColor.Pink);
        Assert.Equal(a, b);
        Assert.NotEqual(a, c);
    }
}
