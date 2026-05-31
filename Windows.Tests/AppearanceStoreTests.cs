using PCNoShitaNoChikaramochi;
using Xunit;

namespace PCNoShitaNoChikaramochi.Tests;

public class AppearanceStoreTests : IDisposable
{
    private readonly string _tempPath =
        Path.Combine(Path.GetTempPath(), $"appearance-test-{Guid.NewGuid():N}.json");

    public void Dispose()
    {
        if (File.Exists(_tempPath)) File.Delete(_tempPath);
        GC.SuppressFinalize(this);
    }

    [Fact]
    public void Defaults_AreMaleLightRed()
    {
        var store = new AppearanceStore();
        Assert.Equal(Gender.Male, store.Gender);
        Assert.Equal(SkinTone.Light, store.SkinTone);
        Assert.Equal(ShirtColor.Red, store.ShirtColor);
    }

    [Fact]
    public void Snapshot_ReflectsCurrentValues()
    {
        var store = new AppearanceStore
        {
            Gender = Gender.Female,
            SkinTone = SkinTone.Deep,
            ShirtColor = ShirtColor.Pink
        };
        Assert.Equal(new AppearanceSnapshot(Gender.Female, SkinTone.Deep, ShirtColor.Pink), store.Snapshot());
    }

    [Fact]
    public void SaveThenLoad_RoundTrips()
    {
        var store = new AppearanceStore
        {
            Gender = Gender.Female,
            SkinTone = SkinTone.Tan,
            ShirtColor = ShirtColor.Green
        };
        store.Save(_tempPath);

        var loaded = AppearanceStore.Load(_tempPath);
        Assert.Equal(Gender.Female, loaded.Gender);
        Assert.Equal(SkinTone.Tan, loaded.SkinTone);
        Assert.Equal(ShirtColor.Green, loaded.ShirtColor);
    }

    [Fact]
    public void Load_MissingFileReturnsDefaults()
    {
        var loaded = AppearanceStore.Load(_tempPath);
        Assert.Equal(Gender.Male, loaded.Gender);
        Assert.Equal(SkinTone.Light, loaded.SkinTone);
        Assert.Equal(ShirtColor.Red, loaded.ShirtColor);
    }

    [Fact]
    public void Load_CorruptFileReturnsDefaults()
    {
        File.WriteAllText(_tempPath, "this is not json");
        var loaded = AppearanceStore.Load(_tempPath);
        Assert.Equal(ShirtColor.Red, loaded.ShirtColor);
    }

    [Fact]
    public void Apply_MutatesAndRaisesChanged()
    {
        var store = new AppearanceStore();
        var raised = false;
        store.Changed += (_, _) => raised = true;

        store.Apply(s => s.ShirtColor = ShirtColor.Blue);

        Assert.Equal(ShirtColor.Blue, store.ShirtColor);
        Assert.True(raised);
    }
}
