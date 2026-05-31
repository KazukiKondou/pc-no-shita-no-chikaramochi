using PCNoShitaNoChikaramochi;
using Xunit;

namespace PCNoShitaNoChikaramochi.Tests;

public class CharacterStateTests
{
    [Theory]
    [InlineData(0, CharacterState.VeryEasy)]
    [InlineData(19.9, CharacterState.VeryEasy)]
    [InlineData(20, CharacterState.Easy)]
    [InlineData(39.9, CharacterState.Easy)]
    [InlineData(40, CharacterState.Normal)]
    [InlineData(59.9, CharacterState.Normal)]
    [InlineData(60, CharacterState.Heavy)]
    [InlineData(79.9, CharacterState.Heavy)]
    [InlineData(80, CharacterState.Struggling)]
    [InlineData(89.9, CharacterState.Struggling)]
    [InlineData(90, CharacterState.Crushed)]
    [InlineData(100, CharacterState.Crushed)]
    public void From_MapsUsageToState(double usage, CharacterState expected)
    {
        Assert.Equal(expected, CharacterStateExtensions.From(usage));
    }

    [Theory]
    [InlineData(-10, CharacterState.VeryEasy)]
    [InlineData(999, CharacterState.Crushed)]
    public void From_HandlesOutOfRange(double usage, CharacterState expected)
    {
        Assert.Equal(expected, CharacterStateExtensions.From(usage));
    }

    [Theory]
    [InlineData(CharacterState.VeryEasy, 0.4)]
    [InlineData(CharacterState.Easy, 0.9)]
    [InlineData(CharacterState.Normal, 1.6)]
    [InlineData(CharacterState.Heavy, 3.2)]
    public void CycleDuration_AnimatedStates(CharacterState state, double expected)
    {
        Assert.Equal(expected, state.CycleDuration());
    }

    [Theory]
    [InlineData(CharacterState.Struggling)]
    [InlineData(CharacterState.Crushed)]
    public void CycleDuration_StaticStatesAreNull(CharacterState state)
    {
        Assert.Null(state.CycleDuration());
    }

    [Theory]
    [InlineData(CharacterState.VeryEasy, LiftKind.Dumbbell)]
    [InlineData(CharacterState.Easy, LiftKind.Dumbbell)]
    [InlineData(CharacterState.Normal, LiftKind.Dumbbell)]
    [InlineData(CharacterState.Heavy, LiftKind.Barbell)]
    [InlineData(CharacterState.Struggling, LiftKind.Barbell)]
    [InlineData(CharacterState.Crushed, LiftKind.Barbell)]
    public void Lift_ChoosesEquipment(CharacterState state, LiftKind expected)
    {
        Assert.Equal(expected, state.Lift());
    }

    [Fact]
    public void Label_EveryStateHasUniqueNonEmptyLabel()
    {
        var states = Enum.GetValues<CharacterState>();
        var labels = states.Select(s => s.Label()).ToList();
        Assert.All(labels, l => Assert.False(string.IsNullOrEmpty(l)));
        Assert.Equal(labels.Count, labels.Distinct().Count());
    }
}

public class CharacterAnimatorTests
{
    [Fact]
    public void DefaultState_IsNormal()
    {
        var animator = new CharacterAnimator();
        Assert.Equal(CharacterState.Normal, animator.State);
        Assert.Equal(0.0, animator.Phase);
    }

    [Fact]
    public void Update_ChangesState()
    {
        var animator = new CharacterAnimator();
        animator.Update(95);
        Assert.Equal(CharacterState.Crushed, animator.State);
        animator.Update(10);
        Assert.Equal(CharacterState.VeryEasy, animator.State);
    }

    [Fact]
    public void Tick_StaticStateForcesPhaseToZero()
    {
        var animator = new CharacterAnimator();
        animator.Update(85); // Struggling: CycleDuration == null
        animator.Tick();
        Assert.Equal(0.0, animator.Phase);
    }

    [Fact]
    public void Tick_AnimatedStatePhaseStaysInRange()
    {
        var animator = new CharacterAnimator();
        animator.Update(10); // VeryEasy
        for (var i = 0; i < 50; i++)
        {
            animator.Tick();
            Assert.InRange(animator.Phase, 0.0, 1.0);
        }
    }
}
