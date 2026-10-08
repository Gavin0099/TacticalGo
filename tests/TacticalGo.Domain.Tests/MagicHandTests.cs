using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class MagicHandTests
{
    private static readonly RuleConfig Hand = new() { MageSkill = MageSkill.MagicHand };

    private static GameState Mage(string diagram = "....O\n.....\n.Ho..\n.....\nX....",
        int mana = 3, int ap = 2, HeroClass one = HeroClass.Mage, RuleConfig? config = null) =>
        GameSetup.FromDiagram(config ?? Hand, diagram, one, HeroClass.None, manaOne: mana, ap: ap);

    [Fact]
    public void Push_then_place_captures_on_the_second_action_and_preserves_the_caster()
    {
        var s = Mage(".oH..\nx....\n.....\n.....\nX...O");
        var original = s.Fingerprint();
        var pushed = GameEngine.Apply(s, new CastMagicHand(P(1, 0), PushDirection.Left));
        Assert.True(pushed.Success, pushed.Validation.Message);
        Assert.Equal(original, s.Fingerprint());
        Assert.Null(pushed.State.Board[P(1, 0)]);
        Assert.Equal(new Piece(Player.Two, PieceKind.Soldier), pushed.State.Board[P(0, 0)]);
        Assert.Equal(new[] { P(1, 0) }, BoardRuleEngine.GetLiberties(pushed.State.Board, [P(0, 0)]));
        Assert.Equal(P(2, 0), pushed.State.Board.FindHero(Player.One));
        Assert.Equal(1, pushed.State.ApRemaining);
        Assert.Equal(1, pushed.State.ManaOf(Player.One));
        Assert.True(pushed.State.SkillUsedThisTurn);
        Assert.Collection(pushed.Events,
            e => Assert.Equal(new ResourcesSpent(Player.One, 1, 2), e),
            e => Assert.Equal(new PiecePushed(Player.One, P(1, 0), P(0, 0),
                new Piece(Player.Two, PieceKind.Soldier)), e));

        var placed = GameEngine.Apply(pushed.State, new PlaceSoldier(P(1, 0)));
        Assert.True(placed.Success, placed.Validation.Message);
        Assert.Null(placed.State.Board[P(0, 0)]);
        Assert.Equal('x', BoardText.ToChar(placed.State.Board[P(1, 0)]));
        var captured = Assert.Single(placed.Events.OfType<PiecesCaptured>());
        Assert.Equal(new[] { new CapturedPiece(P(0, 0), new Piece(Player.Two, PieceKind.Soldier)) }, captured.Pieces);
        Assert.Equal(new[] { "ResourcesSpent", "PiecePlaced", "PiecesCaptured", "TurnEnded", "TurnStarted" },
            placed.Events.Select(e => e.GetType().Name));
    }

    [Theory]
    [InlineData(PushDirection.Up, 2, 1)]
    [InlineData(PushDirection.Right, 3, 2)]
    [InlineData(PushDirection.Down, 2, 3)]
    [InlineData(PushDirection.Left, 1, 2)]
    public void All_four_directions_move_exactly_one_enemy_soldier(PushDirection direction, int x, int y)
    {
        var s = Mage("....O\n.H...\n..o..\n.....\nX...."); // Manhattan range boundary = 2.
        var outcome = GameEngine.Apply(s, new CastMagicHand(P(2, 2), direction));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Null(outcome.State.Board[P(2, 2)]);
        Assert.Equal(new Piece(Player.Two, PieceKind.Soldier), outcome.State.Board[P(x, y)]);
        Assert.Contains(P(2, 2), BoardRuleEngine.GetLiberties(outcome.State.Board,
            BoardRuleEngine.GetGroup(outcome.State.Board, P(x, y))));
        Assert.Equal(1, outcome.State.Board.AllPoints().Count(p => outcome.State.Board[p]?.Owner == Player.Two &&
            outcome.State.Board[p]?.Kind == PieceKind.Soldier));
        Assert.Empty(outcome.Events.OfType<PiecesCaptured>());
    }

    [Fact]
    public void Range_applies_to_the_target_and_the_destination_may_be_farther_away()
    {
        var s = Mage("....O\n.H.o.\n.....\n.....\nX....");
        var outcome = GameEngine.Apply(s, new CastMagicHand(P(3, 1), PushDirection.Right));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Equal('o', BoardText.ToChar(outcome.State.Board[P(4, 1)]));
        AssertRejected(Mage("....O\nH..o.\n.....\n.....\nX...."),
            new CastMagicHand(P(3, 1), PushDirection.Right), IllegalReason.OutOfRange);
    }

    [Fact]
    public void Pushing_a_connector_rebuilds_three_separate_groups()
    {
        var s = Mage("..H.O\n.....\n.ooo.\n.....\nX....");
        Assert.Equal(3, BoardRuleEngine.GetGroup(s.Board, P(2, 2)).Count);
        Assert.Equal(8, BoardRuleEngine.CountLiberties(s.Board, P(2, 2)));
        var outcome = GameEngine.Apply(s, new CastMagicHand(P(2, 2), PushDirection.Down));
        Assert.True(outcome.Success, outcome.Validation.Message);
        foreach (var p in new[] { P(1, 2), P(3, 2), P(2, 3) })
        {
            Assert.Equal(new[] { p }, BoardRuleEngine.GetGroup(outcome.State.Board, p));
            Assert.Equal(4, BoardRuleEngine.CountLiberties(outcome.State.Board, p));
        }
        Assert.Empty(outcome.Events.OfType<PiecesCaptured>());
    }

    [Fact]
    public void Moving_an_enemy_away_can_add_a_commanders_liberty()
    {
        var s = Mage("Xo...\n.H...\n.....\n.....\n....O");
        Assert.Equal(1, BoardRuleEngine.CountLiberties(s.Board, P(0, 0)));
        var outcome = GameEngine.Apply(s, new CastMagicHand(P(1, 0), PushDirection.Right));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Equal(new[] { P(1, 0), P(0, 1) }, BoardRuleEngine.GetLiberties(outcome.State.Board, [P(0, 0)]));
        Assert.Equal(2, BoardRuleEngine.CountLiberties(outcome.State.Board, P(0, 0)));
    }

    [Fact]
    public void Filling_our_commanders_last_liberty_is_suicide_and_rolls_back_everything()
    {
        var s = Mage("X...O\noo...\n.....\n.H...\n.....");
        Assert.Equal(1, BoardRuleEngine.CountLiberties(s.Board, P(0, 0)));
        AssertRejected(s, new CastMagicHand(P(1, 1), PushDirection.Up), IllegalReason.Suicide);
        // A rejected trial must not contaminate later legality or the input's shared history.
        Assert.True(GameEngine.Apply(s, new CastMagicHand(P(1, 1), PushDirection.Right)).Success);
    }

    [Fact]
    public void Repeating_an_older_board_is_superko_and_rolls_back_resources_skill_and_events()
    {
        var s = Mage("....O\n..o..\n..H..\n.....\nX....");
        s = Play(s, new CastMagicHand(P(2, 1), PushDirection.Right), new EndTurn(), new EndTurn());
        AssertRejected(s, new CastMagicHand(P(3, 1), PushDirection.Left), IllegalReason.Ko);
        Assert.True(GameEngine.Apply(s, new CastMagicHand(P(3, 1), PushDirection.Down)).Success);
    }

    [Theory]
    [InlineData('O')]
    [InlineData('Q')]
    [InlineData('x')]
    [InlineData('X')]
    [InlineData('H')]
    [InlineData('.')]
    public void Only_an_enemy_ordinary_soldier_is_a_target(char target)
    {
        // Own Hero is tested at range 0, otherwise the existing caster remains at (1,2).
        var s = target == 'H' ? Mage() : Mage($"....O\n.....\n.H{target}..\n.....\nX....");
        var at = target == 'H' ? P(1, 2) : P(2, 2);
        AssertRejected(s, new CastMagicHand(at, PushDirection.Down), IllegalReason.InvalidTarget);
    }

    [Theory]
    [InlineData('x')]
    [InlineData('o')]
    [InlineData('X')]
    [InlineData('O')]
    [InlineData('Q')]
    public void Any_occupied_destination_is_rejected_without_chain_push(char occupant)
    {
        var s = Mage($"....O\n.....\n.Ho{occupant}.\n.....\nX....");
        AssertRejected(s, new CastMagicHand(P(2, 2), PushDirection.Right), IllegalReason.Occupied);
    }

    [Fact]
    public void Board_and_direction_boundaries_are_rejected_without_mutation()
    {
        AssertRejected(Mage(), new CastMagicHand(P(-1, 2), PushDirection.Right), IllegalReason.OutOfBounds);
        AssertRejected(Mage(), new CastMagicHand(P(5, 2), PushDirection.Left), IllegalReason.OutOfBounds);
        AssertRejected(Mage("Ho..O\n.....\n.....\n.....\nX...."),
            new CastMagicHand(P(1, 0), PushDirection.Up), IllegalReason.OutOfBounds);
        AssertRejected(Mage(), new CastMagicHand(P(2, 2), (PushDirection)255), IllegalReason.InvalidDirection);
    }

    [Fact]
    public void Skill_gates_cover_mana_ap_class_and_absent_caster()
    {
        var action = new CastMagicHand(P(2, 2), PushDirection.Right);
        AssertRejected(Mage(mana: 1), action, IllegalReason.NotEnoughMana);
        Assert.True(GameEngine.Apply(Mage(mana: 2), action).Success);
        AssertRejected(Mage(ap: 0), action, IllegalReason.NoActionPoints);
        AssertRejected(Mage(one: HeroClass.Rogue), action, IllegalReason.WrongClass);
        AssertRejected(Mage("....O\n.....\n..o..\n.....\nX...."), action, IllegalReason.NoHeroOnBoard);
        var once = Play(Mage(mana: 6), action);
        AssertRejected(once, new CastMagicHand(P(3, 2), PushDirection.Left), IllegalReason.SkillAlreadyUsed);
    }

    [Fact]
    public void One_ap_push_emits_resource_then_movement_then_turn_events()
    {
        var outcome = GameEngine.Apply(Mage(ap: 1), new CastMagicHand(P(2, 2), PushDirection.Right));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Collection(outcome.Events,
            e => Assert.Equal(new ResourcesSpent(Player.One, 1, 2), e),
            e => Assert.IsType<PiecePushed>(e),
            e => Assert.Equal(new TurnEnded(Player.One, 1), e),
            e => Assert.Equal(new TurnStarted(Player.Two, 2, 2, 4), e));
        Assert.Equal(Player.Two, outcome.State.Current);
        Assert.False(outcome.State.SkillUsedThisTurn);
    }

    [Fact]
    public void Default_remains_seal_and_the_comparison_switch_selects_exactly_one_mage_skill()
    {
        var plain = Mage(config: new RuleConfig());
        Assert.Equal(MageSkill.Seal, plain.Config.MageSkill);
        AssertRejected(plain, new CastMagicHand(P(2, 2), PushDirection.Right), IllegalReason.SkillNotSelected);
        Assert.True(GameEngine.Apply(plain, new CastSeal(P(1, 1))).Success);
        AssertRejected(Mage(), new CastSeal(P(1, 1)), IllegalReason.SkillNotSelected);
        Assert.Empty(ActionValidator.GetLegalActions(plain).OfType<CastMagicHand>());
        Assert.NotEmpty(ActionValidator.GetLegalActions(plain).OfType<CastSeal>());
    }

    [Fact]
    public void Legal_action_list_and_apply_agree_for_every_target_and_direction()
    {
        var s = Mage(".oH..\nx....\n.....\n.....\nX...O");
        var before = s.Fingerprint();
        var list = ActionValidator.GetLegalActions(s);
        Assert.Empty(list.OfType<CastSeal>());
        Assert.Equal(new[] { new CastMagicHand(P(1, 0), PushDirection.Down),
                new CastMagicHand(P(1, 0), PushDirection.Left) }, list.OfType<CastMagicHand>());
        foreach (var target in s.Board.AllPoints())
            foreach (var direction in Enum.GetValues<PushDirection>())
            {
                var action = new CastMagicHand(target, direction);
                Assert.Equal(list.Contains(action), GameEngine.Apply(s, action).Success);
                Assert.Equal(list.Contains(action), ActionValidator.Validate(s, action).IsLegal);
            }
        Assert.Equal(before, s.Fingerprint());
    }

    [Fact]
    public void No_action_or_legal_target_is_available_after_game_over()
    {
        var s = Mage("x....\nOoo..\nx....\n.H...\n.x..X");
        s = Play(s, new CastMagicHand(P(1, 1), PushDirection.Down), new PlaceSoldier(P(1, 1)));
        Assert.Equal(GameStatus.Won, s.Status);
        Assert.Equal(Player.One, s.Winner);
        AssertRejected(s, new CastMagicHand(P(2, 1), PushDirection.Right), IllegalReason.GameOver);
        Assert.Empty(ActionValidator.GetLegalActions(s));
    }
}
