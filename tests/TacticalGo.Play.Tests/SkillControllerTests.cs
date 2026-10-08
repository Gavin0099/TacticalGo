using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Logic of the hero-skill input mode (Rogue swap). No drawing is involved. These tests show the controller drives the engine
/// correctly; they do not show a player would find the flow clear.
/// </summary>
public class SkillControllerTests
{
    private static Point P(int x, int y) => new(x, y);

    /// <summary>Level 2, stage 1 position (1 action per turn) driven through a normal controller.</summary>
    private static LevelSession Stage(int index = 0)
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, LevelCatalog.Level2());
        if (index > 0) session.StartStage(index);
        return session;
    }

    private static PlayController Custom(string[] rows, HeroClass heroClass = HeroClass.Rogue, int mana = 3, int ap = 2)
    {
        var state = GameSetup.FromDiagram(new RuleConfig { BoardSize = 7, ApPerTurn = ap, FirstTurnAp = null },
            string.Join(Environment.NewLine, rows), heroClass, HeroClass.None, Player.One, manaOne: mana, ap: ap);
        return new PlayController(state, "測試");
    }

    private static readonly string[] SwapBoard =
    [
        "...x...",
        "..xOx..",
        "..ooo..",
        "...H...",
        ".......",
        ".......",
        "...X...",
    ];

    [Fact]
    public void Skill_is_available_when_hero_mana_and_a_target_exist()
    {
        var play = Stage().Play;
        Assert.Equal(SkillState.Available, play.Skill.State);
        Assert.True(play.Skill.CanUse);
        Assert.Contains("換位", play.Skill.Text);
        Assert.False(play.ShowMana);                           // tutorial shows availability, not Mana numbers
    }

    [Fact]
    public void Skill_status_reports_why_it_cannot_be_used()
    {
        Assert.Equal(SkillState.NotEnoughMana, Custom(SwapBoard, mana: 1).Skill.State);
        Assert.Equal(SkillState.None, new PlayController(new RuleConfig()).Skill.State);                // no class
        Assert.Equal(SkillState.Unsupported, Custom(SwapBoard, HeroClass.Mage).Skill.State);            // not built yet

        var noHero = Custom(["...x...", "..xOx..", "..ooo..", ".......", ".......", ".......", "...X..."]);
        Assert.Equal(SkillState.NoHero, noHero.Skill.State);

        var noTarget = Custom(["...x...", "..xOx..", "..ooo..", ".......", ".......", "H......", "...X..."]);
        Assert.Equal(SkillState.NoTargets, noTarget.Skill.State);
    }

    [Fact]
    public void BeginSkill_explains_instead_of_entering_when_unavailable()
    {
        var play = Custom(SwapBoard, mana: 1);
        Assert.False(play.BeginSkill());
        Assert.Equal(PlayMode.Place, play.Mode);
        Assert.Equal(FeedbackKind.Error, play.FeedbackKind);
        Assert.Contains("能量不足", play.Feedback);
    }

    [Fact]
    public void Previewing_a_swap_spends_nothing_and_shows_what_it_would_do()
    {
        var play = Stage().Play;
        var before = play.State.Fingerprint();
        Assert.True(play.BeginSkill());
        Assert.Equal(PlayMode.Skill, play.Mode);
        Assert.Contains("選一顆與盜賊", play.Hint);

        play.ClickPoint(P(3, 2));                              // the soldier right above the Rogue

        Assert.Equal(before, play.State.Fingerprint());        // the official state is untouched
        Assert.NotNull(play.Preview);
        Assert.True(play.CanConfirm);
        Assert.Equal([P(3, 3), P(3, 2)], play.SkillPreviewPoints.ToArray());
        Assert.Contains("包含敵方主將", play.Feedback);          // the engine's preview says this swap takes the commander
        Assert.Contains("會提 1 子", play.Callout);
        Assert.Contains("✔ 放這裡", play.Hint);
    }

    [Fact]
    public void Confirming_the_swap_casts_it_once_and_returns_to_place_mode()
    {
        var s = Stage();
        s.Play.BeginSkill();
        s.Play.ClickPoint(P(3, 2));
        s.Play.Confirm();

        Assert.Equal(PlayMode.Place, s.Play.Mode);
        Assert.True(s.StageComplete);                          // this position is won by the swap
        Assert.Equal(GameStatus.Won, s.Play.State.Status);
        Assert.Equal(1, s.Play.State.ManaOf(Player.One));      // 3 - 2
        Assert.Contains("提掉", s.Play.Feedback);
        Assert.Contains(P(3, 2), s.Play.LastPlaced);
    }

    [Fact]
    public void An_invalid_target_is_explained_and_cannot_be_confirmed()
    {
        var play = Stage().Play;
        play.BeginSkill();
        var before = play.State.Fingerprint();

        foreach (var bad in new[] { P(0, 0), P(3, 6), P(2, 2), P(3, 1) })   // empty, own commander, a non-adjacent enemy soldier, enemy commander
        {
            play.ClickPoint(bad);
            Assert.Null(play.Preview);
            Assert.False(play.CanConfirm);
            Assert.Equal(FeedbackKind.Error, play.FeedbackKind);
            Assert.StartsWith("✕", play.Callout);
            Assert.Equal(before, play.State.Fingerprint());
            play.Confirm();                                    // no-op
            Assert.Equal(before, play.State.Fingerprint());
        }
        Assert.Contains("相鄰", play.Feedback);
    }

    [Fact]
    public void Cancel_first_clears_the_target_then_leaves_skill_mode()
    {
        var play = Stage().Play;
        play.BeginSkill();
        play.ClickPoint(P(3, 2));
        play.Cancel();
        Assert.Equal(PlayMode.Skill, play.Mode);               // still choosing a target
        Assert.Null(play.Selected);
        play.Cancel();
        Assert.Equal(PlayMode.Place, play.Mode);               // second cancel leaves the skill
    }

    [Fact]
    public void Skill_then_stone_and_stone_then_skill_both_work_in_one_two_action_turn()
    {
        foreach (var skillFirst in new[] { true, false })
        {
            var s = Stage(1);                                  // stage 2: two actions per turn, swap alone does not win
            Assert.Equal(2, s.Play.State.ApRemaining);

            void Swap() { Assert.True(s.Play.BeginSkill()); s.Play.ClickPoint(P(3, 2)); s.Play.Confirm(); }
            void Stone() { s.Play.ClickPoint(P(4, 1)); s.Play.Confirm(); }

            if (skillFirst) Swap(); else Stone();
            Assert.False(s.StageComplete);
            Assert.Equal(1, s.Play.State.ApRemaining);
            Assert.Equal(Player.One, s.Play.State.Current);
            Assert.Contains("還能行動 1 次", s.Play.Feedback);

            if (skillFirst) Stone(); else Swap();
            Assert.True(s.StageComplete);
            Assert.Equal(1, s.Play.State.Ply);                 // both actions inside the first turn
            Assert.Contains("同一回合", s.Learned);
        }
    }

    [Fact]
    public void After_casting_the_skill_is_marked_used_this_turn()
    {
        var s = Stage(1);
        s.Play.BeginSkill();
        s.Play.ClickPoint(P(3, 2));
        s.Play.Confirm();
        Assert.Equal(SkillState.UsedThisTurn, s.Play.Skill.State);
        Assert.False(s.Play.BeginSkill());
        Assert.Contains("本回合已經用過", s.Play.Feedback);
    }

    [Fact]
    public void Undo_after_a_swap_restores_the_exact_state_and_place_mode()
    {
        var play = Custom(SwapBoard);                          // free controller (no level lock), 2 actions
        var before = play.State.Fingerprint();
        play.BeginSkill();
        play.ClickPoint(P(3, 2));
        play.Confirm();
        Assert.NotEqual(before, play.State.Fingerprint());

        play.Undo();
        Assert.Equal(before, play.State.Fingerprint());
        Assert.Equal(PlayMode.Place, play.Mode);
        Assert.Null(play.Selected);
    }

    [Fact]
    public void A_swap_that_would_leave_the_hero_without_spaces_is_refused_with_a_clear_reason()
    {
        // The Rogue stands in a pocket; swapping with the soldier would put it where it has no liberty and takes nothing.
        var play = Custom(["Hoo....", ".o.....", ".......", ".......", ".......", ".......", "...X..."], ap: 1);
        play.BeginSkill();
        play.ClickPoint(P(1, 0));
        Assert.Null(play.Preview);
        Assert.Equal(IllegalReason.Suicide, play.SelectionResult!.Reason);
        Assert.Contains("自殺", play.Feedback);
    }

    [Fact]
    public void Leaving_the_tutorial_shows_mana_again()
    {
        var s = Stage();
        Assert.True(s.Play.HideMana);
        s.Active = false;
        Assert.False(s.Play.HideMana);
        Assert.True(s.Play.ShowMana);                          // a class exists, so Mana is shown in free play
    }
}
