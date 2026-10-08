using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>Logic that the 3c interface wiring relies on (mode switch, highlighted targets, labels, level flow, undo in a level).</summary>
public class Slice3cTests
{
    private static Point P(int x, int y) => new(x, y);

    private static LevelSession Start(LevelDefinition level, int stage = 0)
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, level);
        if (stage > 0) session.StartStage(stage);
        return session;
    }

    private static void Place(LevelSession s, int x, int y)
    {
        s.Play.ClickPoint(P(x, y));
        s.Play.Confirm();
    }

    [Fact]
    public void Skill_targets_are_the_engines_legal_swap_points_and_only_in_skill_mode()
    {
        var play = Start(LevelCatalog.Level2()).Play;
        Assert.Empty(play.SkillTargets);                       // place mode: nothing highlighted

        play.BeginSkill();
        Assert.Equal([P(3, 2)], play.SkillTargets.ToArray());   // the one enemy soldier next to the Rogue

        play.UsePlaceMode();
        Assert.Empty(play.SkillTargets);
        Assert.Equal(PlayMode.Place, play.Mode);
    }

    [Fact]
    public void Switching_back_to_place_mode_drops_a_previewed_target_and_spends_nothing()
    {
        var play = Start(LevelCatalog.Level2()).Play;
        var before = play.State.Fingerprint();
        play.BeginSkill();
        play.ClickPoint(P(3, 2));
        Assert.True(play.CanConfirm);

        play.UsePlaceMode();
        Assert.False(play.CanConfirm);
        Assert.Null(play.Selected);
        Assert.Equal(before, play.State.Fingerprint());
    }

    [Fact]
    public void Confirm_label_and_action_bar_text_follow_the_mode_and_selection()
    {
        var play = Start(LevelCatalog.Level2()).Play;
        Assert.Equal("✔ 放這裡", play.ConfirmLabel);
        Assert.Contains("放這裡", play.ActionBarInfo);

        play.BeginSkill();
        Assert.Equal("✔ 確定換位", play.ConfirmLabel);
        Assert.Contains("亮起的目標", play.ActionBarInfo);

        play.ClickPoint(P(3, 2));
        Assert.Contains("預覽換位", play.ActionBarInfo);
        Assert.Contains("還沒施放", play.ActionBarInfo);

        play.ClickPoint(P(0, 0));
        Assert.Contains("不能換位", play.ActionBarInfo);
    }

    [Fact]
    public void Swap_preview_comes_from_the_engines_result_and_the_official_state_stays_put()
    {
        var play = Start(LevelCatalog.Level2()).Play;
        var before = play.State.Fingerprint();
        play.BeginSkill();
        play.ClickPoint(P(3, 2));

        Assert.NotNull(play.Preview);
        Assert.Equal(before, play.State.Fingerprint());
        var hero = play.State.Board.FindHero(Player.One)!.Value;
        Assert.Equal(P(3, 3), hero);                                              // still where it was
        Assert.Equal(P(3, 2), play.Preview!.State.Board.FindHero(Player.One));    // the preview has it swapped
        Assert.Contains(play.Preview.Events, e => e is PiecesCaptured);
    }

    [Fact]
    public void Finishing_level_one_offers_level_two_and_loading_it_starts_a_rogue_stage_without_mana_numbers()
    {
        var s = Start(LevelCatalog.Level1());
        Place(s, 3, 4); s.NextStage();
        Place(s, 4, 2); Place(s, 3, 3); s.NextStage();
        Assert.False(s.HasNextLevel);                          // not finished yet
        Place(s, 3, 1); Place(s, 3, 3);
        Assert.True(s.LevelComplete);
        Assert.True(s.HasNextLevel);
        Assert.Contains("2", s.NextLevelLabel);

        s.NextLevel();
        Assert.Equal(2, s.Level.Number);
        Assert.Equal(0, s.StageIndex);
        Assert.False(s.StageComplete);
        Assert.False(s.Play.Locked);
        Assert.Equal(HeroClass.Rogue, s.Play.State.HeroClassOf(Player.One));
        Assert.False(s.Play.ShowMana);
        Assert.True(s.Play.Skill.CanUse);
    }

    [Fact]
    public void The_last_level_has_no_next_level_and_loading_any_level_works()
    {
        var s = Start(LevelCatalog.Level2(), 1);
        s.Play.BeginSkill(); s.Play.ClickPoint(P(3, 2)); s.Play.Confirm();   // swap alone: the swap is illegal here (suicide) unless the stone is first
        Assert.False(s.StageComplete);

        var t = Start(LevelCatalog.Level2(), 1);
        Place(t, 4, 1);
        t.Play.BeginSkill(); t.Play.ClickPoint(P(3, 2)); t.Play.Confirm();
        Assert.True(t.LevelComplete);
        Assert.False(t.HasNextLevel);
        Assert.Equal("", t.NextLevelLabel);

        t.LoadLevel(LevelCatalog.Level1());
        Assert.Equal(1, t.Level.Number);
        Assert.Equal(HeroClass.None, t.Play.State.HeroClassOf(Player.One));
    }

    [Fact]
    public void Undo_in_a_level_takes_back_a_swap_including_the_passive_opponents_pass()
    {
        var s = Start(LevelCatalog.Level2(), 1);               // two actions per turn; swap first is refused, so place first
        var start = s.Play.State.Fingerprint();
        Place(s, 4, 1);
        s.Play.BeginSkill();
        s.Play.ClickPoint(P(3, 2));
        s.Play.Confirm();
        Assert.True(s.StageComplete);

        s.Play.Locked = false;                                  // the UI only offers undo while the stage is not locked; simulate the mid-stage case
        s.Play.Undo();
        Assert.Equal(PlayMode.Place, s.Play.Mode);
        Assert.NotEqual(start, s.Play.State.Fingerprint());     // one step back: the stone is still placed
        s.Play.Undo();
        Assert.Equal(start, s.Play.State.Fingerprint());
    }

    [Fact]
    public void Undo_mid_stage_after_a_skill_restores_state_mode_and_availability()
    {
        var s = Start(LevelCatalog.Level2(), 0);                // one action per turn: the swap wins at once, so test via a free controller too
        var free = new PlayController(LevelCatalog.Level2().Stages[1].CreateState(), "測試");
        var before = free.State.Fingerprint();
        free.ClickPoint(P(4, 1)); free.Confirm();
        free.BeginSkill(); free.ClickPoint(P(3, 2));
        Assert.True(free.CanConfirm);
        free.Confirm();
        Assert.Equal(SkillState.None, free.Skill.State);        // game over: no skill status shown

        free.Undo();
        Assert.Equal(PlayMode.Place, free.Mode);
        Assert.Equal(SkillState.Available, free.Skill.State);   // skill is available again after undoing the cast
        free.Undo();
        Assert.Equal(before, free.State.Fingerprint());
        Assert.NotNull(s);
    }
}
