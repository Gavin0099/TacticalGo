using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

public class SummonControllerTests
{
    [Theory]
    [InlineData(HeroClass.Warrior, 2)]
    [InlineData(HeroClass.Mage, 3)]
    [InlineData(HeroClass.Rogue, 2)]
    public void Summon_preview_confirmation_and_undo_use_selected_class_and_exact_resources(HeroClass hero, int cost)
    {
        var play = new PlayController(new RuleConfig { FirstTurnAp = null }, hero, HeroClass.Mage);
        Assert.Null(play.State.Board.FindHero(Player.One));
        Assert.Null(play.State.Board.FindHero(Player.Two));
        Assert.Equal(4, play.State.ManaOf(Player.One));
        Assert.Equal(3, play.State.ManaOf(Player.Two));
        var before = play.State.Fingerprint();
        Assert.True(play.BeginSummon());
        play.ClickPoint(new Point(3, 7));
        Assert.Equal(before, play.State.Fingerprint());
        Assert.True(play.CanConfirm);
        Assert.Equal(PieceKind.Hero, play.Preview!.State.Board[new Point(3, 7)]!.Value.Kind);
        Assert.Equal("✔ 確定召喚", play.ConfirmLabel);
        play.Confirm();
        Assert.Equal(1, play.State.ApRemaining);
        Assert.Equal(4 - cost, play.State.ManaOf(Player.One));
        Assert.Equal(new Point(3, 7), play.State.Board.FindHero(Player.One));
        Assert.Equal(hero, play.State.HeroClassOf(Player.One));
        Assert.False(play.BeginSummon());
        Assert.Contains("已經", play.Feedback);
        play.Undo();
        Assert.Equal(before, play.State.Fingerprint());
        Assert.Equal(PlayMode.Place, play.Mode);
        Assert.True(play.BeginSummon());
    }

    [Fact]
    public void Occupied_or_non_adjacent_summons_cannot_be_confirmed_and_cancel_spends_nothing()
    {
        var play = new PlayController(new RuleConfig(), HeroClass.Rogue, HeroClass.Warrior);
        var before = play.State.Fingerprint();
        play.BeginSummon();
        foreach (var p in new[] { new Point(4, 7), new Point(0, 0) })
        {
            play.ClickPoint(p);
            Assert.False(play.CanConfirm);
            Assert.NotNull(play.SelectionResult);
            Assert.Contains("不能召喚", play.Feedback);
            play.Confirm();
            Assert.Equal(before, play.State.Fingerprint());
        }
        play.Cancel();
        Assert.Equal(PlayMode.Summon, play.Mode);
        play.Cancel();
        Assert.Equal(PlayMode.Place, play.Mode);
        Assert.Equal(before, play.State.Fingerprint());
    }

    [Fact]
    public void Insufficient_mana_is_refused_by_engine_and_explained_in_chinese()
    {
        var play = new PlayController(new RuleConfig { InitialMana = 0, ManaGainPerTurn = 0 }, HeroClass.Mage);
        var before = play.State.Fingerprint();
        Assert.False(play.BeginSummon());
        Assert.Contains("Mana 不夠", play.Feedback);
        Assert.Equal(before, play.State.Fingerprint());
    }

    [Fact]
    public void New_game_clears_old_preview_and_undo_and_keeps_both_public_class_choices()
    {
        var play = new PlayController(new RuleConfig(), HeroClass.Rogue, HeroClass.Mage);
        play.BeginSummon(); play.ClickPoint(new Point(3, 7)); play.Confirm();
        play.NewGame(new RuleConfig(), HeroClass.Mage, HeroClass.Warrior);
        Assert.Equal(HeroClass.Mage, play.State.HeroClassOf(Player.One));
        Assert.Equal(HeroClass.Warrior, play.State.HeroClassOf(Player.Two));
        Assert.False(play.CanUndo);
        Assert.Null(play.Selected);
        Assert.Equal(PlayMode.Place, play.Mode);
        Assert.Contains("尚未召喚", play.HeroSummary(Player.One));
    }
}
