using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class SummonTests
{
    [Fact]
    public void Summon_costs_class_mana_and_ap_and_places_a_hero_next_to_a_friendly_piece()
    {
        var g = GameSetup.NewGame(RuleConfig.TwoApBaseline, HeroClass.Mage, HeroClass.None); // P1 has 4 mana, mage costs 3
        var outcome = GameEngine.Apply(g, new SummonHero(P(4, 6)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Equal(P(4, 6), outcome.State.Board.FindHero(Player.One));
        Assert.Equal(1, outcome.State.ManaOf(Player.One));
        Assert.Equal(1, outcome.State.ApRemaining);
        Assert.True(outcome.State.HasSummonedHero(Player.One));
    }

    [Fact]
    public void Summon_may_be_next_to_any_friendly_piece_not_only_the_commander()
    {
        var s = Scenario(["", "", "", "....x", "", "", "", "....X"], one: HeroClass.Warrior, manaOne: 6);
        Assert.True(GameEngine.Apply(s, new SummonHero(P(4, 2))).Success);   // above the forward soldier
        Assert.True(GameEngine.Apply(s, new SummonHero(P(3, 3))).Success);   // beside the forward soldier
    }

    [Fact]
    public void Summon_rejections()
    {
        var g = GameSetup.NewGame(RuleConfig.TwoApBaseline, HeroClass.Mage, HeroClass.None);
        AssertRejected(g, new SummonHero(P(0, 0)), IllegalReason.NotAdjacentToFriend);
        AssertRejected(g, new SummonHero(P(3, 6)), IllegalReason.NotAdjacentToFriend); // diagonal only
        AssertRejected(g, new SummonHero(P(4, 7)), IllegalReason.Occupied);

        var poor = Scenario(["", "", "", "", "", "", "", "....X"], one: HeroClass.Mage, manaOne: 2);
        AssertRejected(poor, new SummonHero(P(4, 6)), IllegalReason.NotEnoughMana);

        var none = GameSetup.NewGame(RuleConfig.TwoApBaseline, HeroClass.None, HeroClass.None);
        AssertRejected(none, new SummonHero(P(4, 6)), IllegalReason.NoHeroClass);
    }

    [Fact]
    public void Enemy_adjacent_pieces_do_not_count_as_a_friendly_anchor()
    {
        var s = Scenario(["", "", "", "....o", "", "", "", "....X"], one: HeroClass.Warrior, manaOne: 6);
        AssertRejected(s, new SummonHero(P(4, 2)), IllegalReason.NotAdjacentToFriend);
    }

    [Fact]
    public void Only_one_hero_on_board()
    {
        var g = Scenario(["", "", "", "", "", "", "", "....XH"], one: HeroClass.Warrior, manaOne: 6);
        AssertRejected(g, new SummonHero(P(3, 7)), IllegalReason.HeroAlreadyOnBoard);
    }

    [Fact]
    public void A_fallen_hero_cannot_be_summoned_again_by_default()
    {
        var s = Scenario(["", "", "", "", "", "", "", "....X"], one: HeroClass.Warrior, manaOne: 6);
        s = Play(s, new SummonHero(P(3, 7)), new EndTurn());       // summon, pass
        // hero is captured: P2 surrounds (3,7)'s group? use a direct scenario instead of a long fight:
        var fallen = GameSetup.FromDiagram(new RuleConfig(), Pad(9, "", "", "", "", "", "", "", "....X"),
            HeroClass.Warrior, HeroClass.None, Player.One, manaOne: 6, heroSummonedOne: true);
        AssertRejected(fallen, new SummonHero(P(3, 7)), IllegalReason.HeroAlreadySummoned);
    }

    [Fact]
    public void Resummon_can_be_switched_on_for_comparison()
    {
        var fallen = GameSetup.FromDiagram(new RuleConfig { AllowResummon = true }, Pad(9, "", "", "", "", "", "", "", "....X"),
            HeroClass.Warrior, HeroClass.None, Player.One, manaOne: 6, heroSummonedOne: true);
        Assert.True(GameEngine.Apply(fallen, new SummonHero(P(3, 7))).Success);
    }

    [Fact]
    public void Capturing_the_hero_marks_it_as_used_up()
    {
        // P1 hero H at (0,0) with one liberty (1,0); P2 fills it and captures. The game state then remembers it was summoned.
        var s = Scenario(["H", "o", "", "", "", "", "", "....X", ""], one: HeroClass.Warrior, two: HeroClass.None,
            current: Player.Two, manaOne: 6);
        s = Play(s, new PlaceSoldier(P(1, 0)));
        Assert.Null(s.Board.FindHero(Player.One));
        Assert.True(s.HasSummonedHero(Player.One));
    }
}

public class WarriorBastionTests
{
    private static GameState Warrior(string[] rows, int mana = 6, int? ap = null) =>
        Scenario(rows, one: HeroClass.Warrior, manaOne: mana, ap: ap);

    [Fact]
    public void Bastion_places_two_soldiers_for_one_ap_and_two_mana()
    {
        var s = Warrior(["", "", "", "", "..H"]);
        var outcome = GameEngine.Apply(s, new CastBastion(P(2, 3), P(3, 4)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.NotNull(outcome.State.Board[P(2, 3)]);
        Assert.NotNull(outcome.State.Board[P(3, 4)]);
        Assert.Equal(1, outcome.State.ApRemaining);
        Assert.Equal(4, outcome.State.ManaOf(Player.One));
        Assert.True(outcome.State.SkillUsedThisTurn);
        Assert.Equal(2, outcome.Events.OfType<PiecePlaced>().Count());
    }

    [Fact]
    public void Only_one_skill_per_turn()
    {
        var s = Warrior(["", "", "", "", "..H"]);
        s = Play(s, new CastBastion(P(2, 3), P(3, 4)));
        AssertRejected(s, new CastBastion(P(1, 4), P(2, 5)), IllegalReason.SkillAlreadyUsed);
    }

    [Fact]
    public void Bastion_rejections_do_not_change_anything()
    {
        var s = Warrior(["", "", "", "", "..H"]);
        AssertRejected(s, new CastBastion(P(2, 3), P(2, 3)), IllegalReason.DuplicateTarget);
        AssertRejected(s, new CastBastion(P(2, 3), P(0, 0)), IllegalReason.OutOfRange);
        AssertRejected(s, new CastBastion(P(2, 3), P(3, 3)), IllegalReason.OutOfRange); // diagonal
        AssertRejected(s, new CastBastion(P(2, 3), P(2, 4)), IllegalReason.OutOfRange); // hero's own point (distance 0)
        AssertRejected(Warrior(["", "", "", "", "..Hx"]), new CastBastion(P(2, 3), P(3, 4)), IllegalReason.Occupied);
        AssertRejected(Warrior(["", "", "", "", "..H"], mana: 1), new CastBastion(P(2, 3), P(3, 4)), IllegalReason.NotEnoughMana);
        AssertRejected(Warrior(["", "", "", "", "..."]), new CastBastion(P(2, 3), P(3, 4)), IllegalReason.NoHeroOnBoard);
        AssertRejected(Scenario(["", "", "", "", "..H"], one: HeroClass.Mage, manaOne: 6),
            new CastBastion(P(2, 3), P(3, 4)), IllegalReason.WrongClass);
    }

    [Fact]
    public void Bastion_is_one_atomic_action_two_stones_can_capture_together()
    {
        // o(1,1) has libs (1,0),(0,1) only. H at (0,0) is adjacent to both; bastion fills both at once and captures.
        var s = Warrior(["H . x", ". o x", ". x"]);
        var outcome = GameEngine.Apply(s, new CastBastion(P(1, 0), P(0, 1)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Null(outcome.State.Board[P(1, 1)]);
        Assert.Single(outcome.Events.OfType<PiecesCaptured>());
    }

    [Fact]
    public void Bastion_whose_pair_is_suicide_is_rejected_whole()
    {
        // H(0,0) in the corner, enemies on every outer neighbor: filling both inner points leaves the group with no liberty.
        var s = Warrior(["H . o", ". o", "o"]);
        AssertRejected(s, new CastBastion(P(1, 0), P(0, 1)), IllegalReason.Suicide);
        Assert.Null(s.Board[P(1, 0)]);
    }

    [Fact]
    public void Bastion_cannot_place_on_a_point_the_enemy_mage_sealed()
    {
        // P2 Mage Q at (5,4) seals (3,4) (distance 2); P1 Warrior H at (2,4) then tries to bastion onto it.
        var s = Scenario(["", "", "", "", "..H..Q"], one: HeroClass.Warrior, two: HeroClass.Mage,
            manaOne: 6, manaTwo: 6, current: Player.Two);
        s = Play(s, new CastSeal(P(3, 4)), new EndTurn());
        Assert.Equal(Player.One, s.Current);
        AssertRejected(s, new CastBastion(P(3, 4), P(2, 3)), IllegalReason.Sealed);
        Assert.True(GameEngine.Apply(s, new CastBastion(P(2, 3), P(1, 4))).Success); // unsealed pair is fine
    }
}

public class MageSealTests
{
    private static GameState Mage(int mana = 6) =>
        Scenario(["", "", "", "", "....H", "", "", "", "....O"], one: HeroClass.Mage, manaOne: mana);

    [Fact]
    public void Seal_blocks_the_opponent_for_one_turn_then_expires()
    {
        var s = Mage();
        s = Play(s, new CastSeal(P(4, 2)));                       // distance 2 from (4,4)
        Assert.Single(s.Seals);
        s = Play(s, new EndTurn());                               // P2's turn
        AssertRejected(s, new PlaceSoldier(P(4, 2)), IllegalReason.Sealed);
        s = Play(s, new PlaceSoldier(P(0, 0)), new EndTurn());    // P2 ends -> seal expires
        Assert.Empty(s.Seals);
        s = Play(s, new EndTurn());                               // P1 passes
        Assert.True(GameEngine.Apply(s, new PlaceSoldier(P(4, 2))).Success);
    }

    [Fact]
    public void Seal_survives_the_casters_own_turn_end_and_does_not_block_the_caster()
    {
        var s = Mage();
        s = Play(s, new CastSeal(P(3, 4)));
        Assert.True(GameEngine.Apply(s, new PlaceSoldier(P(3, 4))).Success); // caster may still use it
        s = Play(s, new EndTurn());
        Assert.Single(s.Seals);
    }

    [Fact]
    public void Sealed_point_is_still_a_liberty_so_it_prevents_capture()
    {
        // Mage H at (0,3); o at (0,0) has liberties (1,0),(0,1). Seal (0,1), then fill (1,0): o survives on the sealed liberty.
        var s = Scenario(["o", "", "", "H"], one: HeroClass.Mage, manaOne: 6, ap: 2);
        s = Play(s, new CastSeal(P(0, 1)));
        Assert.Equal(2, BoardRuleEngine.CountLiberties(s.Board, P(0, 0)));
        s = Play(s, new PlaceSoldier(P(1, 0)));
        Assert.NotNull(s.Board[P(0, 0)]);
        Assert.Equal(1, BoardRuleEngine.CountLiberties(s.Board, P(0, 0)));
    }

    [Fact]
    public void Seal_rejections()
    {
        var s = Mage();
        AssertRejected(s, new CastSeal(P(4, 1)), IllegalReason.OutOfRange);        // distance 3
        AssertRejected(s, new CastSeal(P(4, 4)), IllegalReason.OutOfRange);        // hero's own point (distance 0)
        AssertRejected(s, new CastSeal(P(4, 8)), IllegalReason.OutOfRange);
        AssertRejected(s, new CastSeal(P(9, 9)), IllegalReason.OutOfBounds);
        AssertRejected(Mage(mana: 1), new CastSeal(P(4, 3)), IllegalReason.NotEnoughMana);

        var occupied = Scenario(["", "", "", "", "...xH"], one: HeroClass.Mage, manaOne: 6);
        AssertRejected(occupied, new CastSeal(P(3, 4)), IllegalReason.Occupied);

        var twice = Play(Mage(), new CastSeal(P(4, 3)));
        AssertRejected(twice, new CastSeal(P(4, 2)), IllegalReason.SkillAlreadyUsed);
    }

    [Fact]
    public void Sealed_point_blocks_soldier_and_summon_for_the_opponent()
    {
        var s = Scenario(["", "", "", "", "....H", "", "", "....X"], one: HeroClass.Mage, two: HeroClass.Warrior,
            manaOne: 6, manaTwo: 6);
        s = Play(s, new CastSeal(P(4, 5)), new EndTurn());
        AssertRejected(s, new PlaceSoldier(P(4, 5)), IllegalReason.Sealed);
        AssertRejected(s, new SummonHero(P(4, 5)), IllegalReason.Sealed);
    }

    [Fact]
    public void Dead_mage_cannot_cast()
    {
        var s = Scenario(["", "", "", "", "....x"], one: HeroClass.Mage, manaOne: 6);
        AssertRejected(s, new CastSeal(P(4, 3)), IllegalReason.NoHeroOnBoard);
    }
}

public class RogueSwapTests
{
    private static GameState Rogue(string[] rows, int mana = 6) =>
        Scenario(rows, one: HeroClass.Rogue, manaOne: mana);

    [Fact]
    public void Swap_exchanges_positions_and_spends_resources()
    {
        var s = Rogue(["", "", "", "..Ho"]);
        var outcome = GameEngine.Apply(s, new CastSwap(P(3, 3)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Equal(P(3, 3), outcome.State.Board.FindHero(Player.One));
        Assert.Equal(PieceKind.Soldier, outcome.State.Board[P(2, 3)]!.Value.Kind);
        Assert.Equal(Player.Two, outcome.State.Board[P(2, 3)]!.Value.Owner);
        Assert.Equal(4, outcome.State.ManaOf(Player.One));
        Assert.Equal(1, outcome.State.ApRemaining);
        Assert.Single(outcome.Events.OfType<PiecesSwapped>());
    }

    [Fact]
    public void Swap_target_rejections()
    {
        AssertRejected(Rogue(["", "", "", "..HO"]), new CastSwap(P(3, 3)), IllegalReason.InvalidTarget); // commander
        AssertRejected(Rogue(["", "", "", "..HQ"]), new CastSwap(P(3, 3)), IllegalReason.InvalidTarget); // hero
        AssertRejected(Rogue(["", "", "", "..Hx"]), new CastSwap(P(3, 3)), IllegalReason.InvalidTarget); // own soldier
        AssertRejected(Rogue(["", "", "", "..H."]), new CastSwap(P(3, 3)), IllegalReason.InvalidTarget); // empty
        AssertRejected(Rogue(["", "", "", "..H", "...o"]), new CastSwap(P(3, 4)), IllegalReason.OutOfRange); // diagonal
        AssertRejected(Rogue(["", "", "", "H..o"]), new CastSwap(P(3, 3)), IllegalReason.OutOfRange);
        AssertRejected(Rogue(["", "", "", "..Ho"], mana: 1), new CastSwap(P(3, 3)), IllegalReason.NotEnoughMana);
    }

    [Fact]
    public void Swap_that_leaves_the_rogue_without_liberties_is_suicide_and_changes_nothing()
    {
        // H(0,0); o(1,0). After swap H sits on (1,0) whose other neighbors (2,0),(1,1) are enemy -> no liberty.
        var s = Rogue(["Hoo", ".o"]);
        AssertRejected(s, new CastSwap(P(1, 0)), IllegalReason.Suicide);
        Assert.Equal(P(0, 0), s.Board.FindHero(Player.One));
    }

    [Fact]
    public void Swap_can_break_a_formation_and_decapitate()
    {
        // O(0,0) is protected by o(1,0); x at (0,1). Rogue at (2,0) swaps with o(1,0): H lands on (1,0) -> O has no liberty.
        var s = Rogue(["O o H", "x"]);
        var outcome = GameEngine.Apply(s, new CastSwap(P(1, 0)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        // group {O} neighbors (1,0)=H,(0,1)=x -> captured; group {o} at (2,0) survives if it has liberties
        Assert.Equal(GameStatus.Won, outcome.State.Status);
        Assert.Equal(Player.One, outcome.State.Winner);
    }

    [Fact]
    public void Swap_is_blocked_by_ko_when_it_would_recreate_an_earlier_position()
    {
        // Swap twice in a row between the same two cells would restore the earlier board -> the second is a ko.
        var s = Rogue(["", "", "", "..Ho", "......."]);
        s = Play(s, new CastSwap(P(3, 3)));
        var back = ActionValidator.Validate(s, new CastSwap(P(2, 3)));
        Assert.False(back.IsLegal);
        // same turn: skill already used; next turn the ko rule is what stops it
        s = Play(s, new EndTurn(), new EndTurn());
        var again = ActionValidator.Validate(s, new CastSwap(P(2, 3)));
        Assert.Equal(IllegalReason.Ko, again.Reason);
    }
}

public class NoClassTests
{
    [Fact]
    public void No_class_player_has_no_skills_in_the_legal_list()
    {
        var g = GameSetup.NewGame(new RuleConfig(), HeroClass.None, HeroClass.None);
        var legal = ActionValidator.GetLegalActions(g);
        Assert.All(legal, a => Assert.True(a is PlaceSoldier or EndTurn));
        AssertRejected(g, new CastSeal(P(4, 6)), IllegalReason.WrongClass);
    }
}
