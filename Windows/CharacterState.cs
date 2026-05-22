using System;

namespace PCNoShitaNoChikaramochi;

public enum CharacterState
{
    VeryEasy,    // <20%
    Easy,        // 20-40%
    Normal,      // 40-60%
    Heavy,       // 60-80%
    Struggling,  // 80-90%
    Crushed      // 90%+
}

public enum LiftKind
{
    Dumbbell,
    Barbell
}

public static class CharacterStateExtensions
{
    public static CharacterState From(double usagePercent) => usagePercent switch
    {
        < 20 => CharacterState.VeryEasy,
        < 40 => CharacterState.Easy,
        < 60 => CharacterState.Normal,
        < 80 => CharacterState.Heavy,
        < 90 => CharacterState.Struggling,
        _    => CharacterState.Crushed
    };

    /// <summary>1サイクル (上げて下ろす) にかける秒数。null なら静止。</summary>
    public static double? CycleDuration(this CharacterState s) => s switch
    {
        CharacterState.VeryEasy => 0.4,
        CharacterState.Easy => 0.9,
        CharacterState.Normal => 1.6,
        CharacterState.Heavy => 3.2,
        _ => null
    };

    public static LiftKind Lift(this CharacterState s) => s switch
    {
        CharacterState.VeryEasy or CharacterState.Easy or CharacterState.Normal => LiftKind.Dumbbell,
        _ => LiftKind.Barbell
    };

    public static string Label(this CharacterState s) => s switch
    {
        CharacterState.VeryEasy => "余裕！",
        CharacterState.Easy => "軽い軽い",
        CharacterState.Normal => "ふつう",
        CharacterState.Heavy => "ぐぬぬ…",
        CharacterState.Struggling => "上がらん！！",
        CharacterState.Crushed => "ぺしゃんこ…",
        _ => "?"
    };
}

public class CharacterAnimator
{
    public CharacterState State { get; private set; } = CharacterState.Normal;

    /// <summary>0.0 = 下げきった、1.0 = 上げきった</summary>
    public double Phase { get; private set; }

    private DateTime _stateStart = DateTime.UtcNow;

    public void Update(double usagePercent)
    {
        var next = CharacterStateExtensions.From(usagePercent);
        if (next != State)
        {
            State = next;
            _stateStart = DateTime.UtcNow;
        }
    }

    public void Tick()
    {
        var duration = State.CycleDuration();
        if (!duration.HasValue)
        {
            Phase = 0;
            return;
        }
        var elapsed = (DateTime.UtcNow - _stateStart).TotalSeconds;
        var t = (elapsed % duration.Value) / duration.Value;
        Phase = t < 0.5 ? t * 2 : 2 - t * 2;
    }
}
