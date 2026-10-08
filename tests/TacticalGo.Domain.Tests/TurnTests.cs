using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class TurnTests
{
    private static GameState Fresh(RuleConfig? config = null, HeroClass one = HeroClass.None, HeroClass two = HeroClass.None) =>
        GameSetup.NewGame(config ?? RuleConfig.TwoApBaseline, one, two);

    [Fact]
    public void Turn_passes_automatically_after_two_actions_and_ap_resets()
    {
        var g = Fresh();
        g = Play(g, new PlaceSoldier(P(0, 8)));
        Assert.Equal(Player.One, g.Current);
        Assert.Equal(1, g.ApRemaining);
        g = Play(g, new PlaceSoldier(P(1, 8)));
        Assert.Equal(Player.Two, g.Current);
        Assert.Equal(2, g.ApRemaining);
        Assert.Equal(2, g.Ply);
    }

    [Fact]
    public void End_turn_forfeits_remaining_ap()
    {
        var g = Fresh();
        g = Play(g, new EndTurn());
        Assert.Equal(Player.Two, g.Current);
        Assert.Equal(2, g.ApRemaining);
    }

    [Fact]
    public void Mana_grows_by_one_per_own_turn_and_is_capped()
    {
        var config = new RuleConfig { ManaCap = 5 };
        var g = Fresh(config);                       // P1 4
        Assert.Equal(4, g.ManaOf(Player.One));
        g = Play(g, new EndTurn());                   // P2 3 -> 4
        Assert.Equal(4, g.ManaOf(Player.Two));
        g = Play(g, new EndTurn());                   // P1 4 -> 5
        Assert.Equal(5, g.ManaOf(Player.One));
        g = Play(g, new EndTurn(), new EndTurn());    // P2 5, P1 capped at 5
        Assert.Equal(5, g.ManaOf(Player.One));
        Assert.Equal(5, g.ManaOf(Player.Two));
    }

    [Fact]
    public void Draft_default_gives_player_one_a_one_ap_first_turn_and_two_afterwards()
    {
        var g = GameSetup.NewGame(new RuleConfig(), HeroClass.None, HeroClass.None);
        Assert.Equal(1, g.ApRemaining);
        g = Play(g, new PlaceSoldier(P(0, 8)));
        Assert.Equal(Player.Two, g.Current);
        Assert.Equal(2, g.ApRemaining);
        g = Play(g, new EndTurn());
        Assert.Equal(2, g.ApRemaining); // player one's second turn is back to full AP
    }

    [Fact]
    public void Two_ap_baseline_keeps_full_ap_on_the_first_turn()
    {
        Assert.Equal(2, GameSetup.NewGame(RuleConfig.TwoApBaseline, HeroClass.None, HeroClass.None).ApRemaining);
    }

    [Fact]
    public void First_turn_ap_override_only_affects_the_first_turn()
    {
        var g = Fresh(new RuleConfig { FirstTurnAp = 1 });
        Assert.Equal(1, g.ApRemaining);
        g = Play(g, new PlaceSoldier(P(0, 8)));
        Assert.Equal(Player.Two, g.Current);
        Assert.Equal(2, g.ApRemaining);
    }

    [Fact]
    public void Turn_limit_ends_in_a_draw_and_blocks_further_actions()
    {
        var g = Fresh(new RuleConfig { MaxPlies = 2 });
        g = Play(g, new EndTurn());
        Assert.Equal(GameStatus.Ongoing, g.Status);
        var outcome = GameEngine.Apply(g, new EndTurn());
        Assert.True(outcome.Success);
        Assert.Equal(GameStatus.Drawn, outcome.State.Status);
        Assert.Null(outcome.State.Winner);
        Assert.Contains(outcome.Events, e => e is GameDrawn);
        AssertRejected(outcome.State, new PlaceSoldier(P(0, 8)), IllegalReason.GameOver);
    }

    [Fact]
    public void Rejected_action_never_changes_the_state_or_emits_events()
    {
        var g = Fresh();
        var before = g.Fingerprint();
        var outcome = GameEngine.Apply(g, new PlaceSoldier(P(4, 7))); // own commander's point
        Assert.False(outcome.Success);
        Assert.Same(g, outcome.State);
        Assert.Empty(outcome.Events);
        Assert.Equal(before, g.Fingerprint());
    }

    [Fact]
    public void Applying_an_action_never_mutates_the_input_state()
    {
        var g = Fresh();
        var before = g.Fingerprint();
        var outcome = GameEngine.Apply(g, new PlaceSoldier(P(0, 8)));
        Assert.True(outcome.Success);
        Assert.Equal(before, g.Fingerprint());
        Assert.NotSame(g, outcome.State);
    }

    [Fact]
    public void Legal_action_list_always_contains_end_turn_and_only_legal_actions()
    {
        var g = Fresh(one: HeroClass.Warrior);
        var legal = ActionValidator.GetLegalActions(g);
        Assert.IsType<EndTurn>(legal[^1]);
        foreach (var action in legal)
            Assert.True(GameEngine.Apply(g, action).Success, action.ToString());
        Assert.DoesNotContain(legal, a => a is PlaceSoldier { At: { X: 4, Y: 7 } });
    }

    [Fact]
    public void Same_actions_replay_to_the_identical_state()
    {
        var config = new RuleConfig { MaxPlies = 60 };
        var rng = new Random(12345);
        var live = new GameSession(GameSetup.NewGame(config, HeroClass.Warrior, HeroClass.Rogue));
        for (var i = 0; i < 300 && live.State.Status == GameStatus.Ongoing; i++)
        {
            var legal = ActionValidator.GetLegalActions(live.State);
            var pick = legal[rng.Next(legal.Count)];
            Assert.True(live.Apply(pick).Success);
        }

        var replayed = GameSession.Replay(config, HeroClass.Warrior, HeroClass.Rogue, live.Log);
        Assert.Equal(live.State.Fingerprint(), replayed.State.Fingerprint());
        Assert.True(live.Log.Count > 20);
    }
}
