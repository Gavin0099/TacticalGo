namespace TacticalGo.Domain;

/// <summary>Everything an accepted action will change, computed on copies before anything is committed.</summary>
internal sealed record PreparedAction(
    Board? NewBoard,
    IReadOnlyList<CapturedPiece> Captured,
    int ManaCost,
    bool IsSkill,
    IReadOnlyList<(Point At, PieceKind Kind)> Placed,
    (Point A, Point B)? Swapped,
    SealEffect? Seal,
    (Point From, Point To, Piece Piece)? Pushed = null);

/// <summary>Validate → Apply atomically (on copies) → Resolve captures → Emit events → Commit.</summary>
internal static class ActionResolver
{
    private static readonly IReadOnlyList<CapturedPiece> NoCaptures = [];
    private static readonly IReadOnlyList<(Point At, PieceKind Kind)> NoPlacements = [];

    public static ActionOutcome Apply(GameState state, GameAction action)
    {
        if (action is EndTurn && state.Status == GameStatus.Ongoing)
        {
            var ended = state.Clone();
            var endEvents = new List<ActionEvent>();
            TurnEngine.EndTurn(ended, endEvents);
            return new ActionOutcome(true, ValidationResult.Ok, ended, endEvents);
        }

        var (plan, validation) = Prepare(state, action);
        if (plan is null)
            return new ActionOutcome(false, validation, state, []);

        var next = state.Clone();
        var events = new List<ActionEvent>();
        var mover = state.Current;

        next.ApRemaining -= 1;
        next.SetMana(mover, next.ManaOf(mover) - plan.ManaCost);
        if (plan.IsSkill) next.SkillUsedThisTurn = true;
        events.Add(new ResourcesSpent(mover, 1, plan.ManaCost));

        if (plan.NewBoard is not null)
        {
            next.Board = plan.NewBoard;
            next.History = new PositionHistory(plan.NewBoard.ComputeHash(), next.History);
        }
        foreach (var (at, kind) in plan.Placed)
        {
            events.Add(new PiecePlaced(mover, at, kind));
            if (kind == PieceKind.Hero) next.MarkHeroSummoned(mover);
        }
        if (plan.Swapped is { } swap)
            events.Add(new PiecesSwapped(mover, swap.A, swap.B));
        if (plan.Pushed is { } push)
            events.Add(new PiecePushed(mover, push.From, push.To, push.Piece));
        if (plan.Seal is { } seal)
        {
            next.Seals = [.. next.Seals, seal];
            events.Add(new SealPlaced(seal.Caster, seal.BlockedPlayer, seal.At));
        }
        if (plan.Captured.Count > 0)
            events.Add(new PiecesCaptured(mover, plan.Captured));

        if (plan.Captured.Any(c => c.Piece.Kind == PieceKind.Commander && c.Piece.Owner != mover))
        {
            next.Status = GameStatus.Won;
            next.Winner = mover;
            events.Add(new GameWon(mover));
        }
        else if (next.ApRemaining == 0)
        {
            TurnEngine.EndTurn(next, events);
        }

        return new ActionOutcome(true, ValidationResult.Ok, next, events);
    }

    public static (PreparedAction? Plan, ValidationResult Result) Prepare(GameState s, GameAction action)
    {
        if (s.Status != GameStatus.Ongoing)
            return Fail(IllegalReason.GameOver, "The game is over.");
        if (action is EndTurn)
            return (null, ValidationResult.Ok);
        if (s.ApRemaining < 1)
            return Fail(IllegalReason.NoActionPoints, "No action points left.");

        return action switch
        {
            PlaceSoldier a => PlanPlaceSoldier(s, a),
            SummonHero a => PlanSummonHero(s, a),
            CastBastion a => PlanBastion(s, a),
            CastSeal a => PlanSeal(s, a),
            CastMagicHand a => PlanMagicHand(s, a),
            CastSwap a => PlanSwap(s, a),
            _ => Fail(IllegalReason.InvalidTarget, $"Unknown action {action.GetType().Name}."),
        };
    }

    private static (PreparedAction?, ValidationResult) PlanPlaceSoldier(GameState s, PlaceSoldier a)
    {
        if (CheckPlaceable(s, a.At) is { } error) return (null, error);
        var trial = s.Board.Clone();
        trial[a.At] = new Piece(s.Current, PieceKind.Soldier);
        return Finish(s, trial, [(a.At, PieceKind.Soldier)], null, 0, isSkill: false, seal: null);
    }

    private static (PreparedAction?, ValidationResult) PlanSummonHero(GameState s, SummonHero a)
    {
        var me = s.Current;
        var heroClass = s.HeroClassOf(me);
        if (heroClass == HeroClass.None)
            return Fail(IllegalReason.NoHeroClass, "This player has no hero class.");
        if (s.Board.FindHero(me) is not null)
            return Fail(IllegalReason.HeroAlreadyOnBoard, "Only one hero may be on the board.");
        if (s.HasSummonedHero(me) && !s.Config.AllowResummon)
            return Fail(IllegalReason.HeroAlreadySummoned, "Your hero has fallen and cannot be summoned again.");

        var cost = s.Config.SummonCost(heroClass);
        if (s.ManaOf(me) < cost)
            return Fail(IllegalReason.NotEnoughMana, $"Summoning needs {cost} Mana (have {s.ManaOf(me)}).");
        if (CheckPlaceable(s, a.At) is { } error) return (null, error);

        if (!s.Board.Neighbors(a.At).Any(n => s.Board[n] is { } friend && friend.Owner == me))
            return Fail(IllegalReason.NotAdjacentToFriend,
                "A hero must be summoned orthogonally next to one of your own pieces.");

        var trial = s.Board.Clone();
        trial[a.At] = new Piece(me, PieceKind.Hero);
        return Finish(s, trial, [(a.At, PieceKind.Hero)], null, cost, isSkill: false, seal: null);
    }

    private static (PreparedAction?, ValidationResult) PlanBastion(GameState s, CastBastion a)
    {
        var (hero, error) = RequireSkill(s, HeroClass.Warrior);
        if (error is not null) return (null, error);
        if (a.First == a.Second)
            return Fail(IllegalReason.DuplicateTarget, "Bastion needs two different points.");

        foreach (var p in new[] { a.First, a.Second })
        {
            if (!s.Board.InBounds(p)) return Fail(IllegalReason.OutOfBounds, $"{p} is off the board.");
            if (hero.ManhattanTo(p) != 1)
                return Fail(IllegalReason.OutOfRange, $"{p} is not orthogonally adjacent to the Warrior at {hero}.");
            if (CheckPlaceable(s, p) is { } placeError) return (null, placeError);
        }

        var trial = s.Board.Clone();
        var soldier = new Piece(s.Current, PieceKind.Soldier);
        trial[a.First] = soldier;
        trial[a.Second] = soldier;
        return Finish(s, trial, [(a.First, PieceKind.Soldier), (a.Second, PieceKind.Soldier)], null,
            s.Config.SkillManaCost, isSkill: true, seal: null);
    }

    private static (PreparedAction?, ValidationResult) PlanSeal(GameState s, CastSeal a)
    {
        var (hero, error) = RequireSkill(s, HeroClass.Mage);
        if (error is not null) return (null, error);
        if (s.Config.MageSkill != MageSkill.Seal)
            return Fail(IllegalReason.SkillNotSelected, "Seal is not the selected Mage skill.");
        if (!s.Board.InBounds(a.At)) return Fail(IllegalReason.OutOfBounds, $"{a.At} is off the board.");

        var distance = hero.ManhattanTo(a.At);
        if (distance < 1 || distance > s.Config.SealRange)
            return Fail(IllegalReason.OutOfRange, $"{a.At} is not within {s.Config.SealRange} of the Mage at {hero}.");
        if (!s.Board.IsEmpty(a.At))
            return Fail(IllegalReason.Occupied, $"{a.At} is occupied; only empty points can be sealed.");

        var opponent = s.Current.Opponent();
        if (s.IsSealedFor(a.At, opponent))
            return Fail(IllegalReason.InvalidTarget, $"{a.At} is already sealed.");

        var plan = new PreparedAction(null, NoCaptures, s.Config.SkillManaCost, true, NoPlacements, null,
            new SealEffect(a.At, s.Current, opponent));
        return (plan, ValidationResult.Ok);
    }

    private static (PreparedAction?, ValidationResult) PlanSwap(GameState s, CastSwap a)
    {
        var (hero, error) = RequireSkill(s, HeroClass.Rogue);
        if (error is not null) return (null, error);
        if (!s.Board.InBounds(a.Target)) return Fail(IllegalReason.OutOfBounds, $"{a.Target} is off the board.");
        if (hero.ManhattanTo(a.Target) != 1)
            return Fail(IllegalReason.OutOfRange, $"{a.Target} is not orthogonally adjacent to the Rogue at {hero}.");

        var me = s.Current;
        if (s.Board[a.Target] is not { Kind: PieceKind.Soldier } victim || victim.Owner == me)
            return Fail(IllegalReason.InvalidTarget, "Swap target must be an enemy soldier (not a commander or hero).");

        var trial = s.Board.Clone();
        trial[hero] = victim;
        trial[a.Target] = new Piece(me, PieceKind.Hero);
        return Finish(s, trial, NoPlacements, (hero, a.Target), s.Config.SkillManaCost, isSkill: true, seal: null);
    }

    private static (PreparedAction?, ValidationResult) PlanMagicHand(GameState s, CastMagicHand a)
    {
        var (hero, error) = RequireSkill(s, HeroClass.Mage);
        if (error is not null) return (null, error);
        if (s.Config.MageSkill != MageSkill.MagicHand)
            return Fail(IllegalReason.SkillNotSelected, "Magic Hand is not the selected Mage skill.");
        if (!s.Board.InBounds(a.Target))
            return Fail(IllegalReason.OutOfBounds, $"{a.Target} is off the board.");
        if (hero.ManhattanTo(a.Target) > s.Config.MagicHandRange)
            return Fail(IllegalReason.OutOfRange, $"{a.Target} is not within {s.Config.MagicHandRange} of the Mage at {hero}.");
        if (s.Board[a.Target] is not { Kind: PieceKind.Soldier } victim)
            return Fail(IllegalReason.InvalidTarget, "Magic Hand target must be an ordinary soldier of either player (not a commander or hero).");
        if (!Enum.IsDefined(a.Direction))
            return Fail(IllegalReason.InvalidDirection, "Choose Up, Right, Down or Left.");

        var destination = a.Direction switch
        {
            PushDirection.Up => new Point(a.Target.X, a.Target.Y - 1),
            PushDirection.Right => new Point(a.Target.X + 1, a.Target.Y),
            PushDirection.Down => new Point(a.Target.X, a.Target.Y + 1),
            PushDirection.Left => new Point(a.Target.X - 1, a.Target.Y),
            _ => throw new InvalidOperationException("Direction was validated above."),
        };
        if (!s.Board.InBounds(destination))
            return Fail(IllegalReason.OutOfBounds, $"{destination} is off the board.");
        if (!s.Board.IsEmpty(destination))
            return Fail(IllegalReason.Occupied, $"{destination} is occupied; Magic Hand does not chain-push.");

        // This is movement, not placement: a seal continues to block placement only.
        var trial = s.Board.Clone();
        trial[a.Target] = null;
        trial[destination] = victim;
        // The empty source is necessarily a liberty of the moved soldier. Other groups may change.
        return Finish(s, trial, NoPlacements, null, s.Config.SkillManaCost, isSkill: true, seal: null,
            pushed: (a.Target, destination, victim));
    }

    /// <summary>Common skill gate. Returns the caster hero's position, or the reason the skill cannot be used.</summary>
    private static (Point Hero, ValidationResult? Error) RequireSkill(GameState s, HeroClass required)
    {
        var me = s.Current;
        if (s.HeroClassOf(me) != required)
            return (default, ValidationResult.Fail(IllegalReason.WrongClass, $"This skill belongs to the {required}."));
        if (s.Board.FindHero(me) is not { } hero)
            return (default, ValidationResult.Fail(IllegalReason.NoHeroOnBoard, "Your hero is not on the board."));
        if (s.SkillUsedThisTurn)
            return (default, ValidationResult.Fail(IllegalReason.SkillAlreadyUsed, "Only one skill per turn."));
        if (s.ManaOf(me) < s.Config.SkillManaCost)
            return (default, ValidationResult.Fail(IllegalReason.NotEnoughMana,
                $"A skill needs {s.Config.SkillManaCost} Mana (have {s.ManaOf(me)})."));
        return (hero, null);
    }

    private static ValidationResult? CheckPlaceable(GameState s, Point at)
    {
        if (!s.Board.InBounds(at))
            return ValidationResult.Fail(IllegalReason.OutOfBounds, $"{at} is off the board.");
        if (!s.Board.IsEmpty(at))
            return ValidationResult.Fail(IllegalReason.Occupied, $"{at} is occupied.");
        if (s.IsSealedFor(at, s.Current))
            return ValidationResult.Fail(IllegalReason.Sealed, $"{at} is sealed this turn.");
        return null;
    }

    private static (PreparedAction?, ValidationResult) Finish(
        GameState s,
        Board trial,
        IReadOnlyList<(Point At, PieceKind Kind)> placed,
        (Point A, Point B)? swapped,
        int manaCost,
        bool isSkill,
        SealEffect? seal,
        (Point From, Point To, Piece Piece)? pushed = null)
    {
        var resolution = BoardRuleEngine.ResolveCaptures(trial, s.Current);
        if (resolution.MoverHasDeadGroup)
            return Fail(IllegalReason.Suicide, "That would leave your own group without liberties.");
        if (s.History.Contains(trial.ComputeHash()))
            return Fail(IllegalReason.Ko, "That would repeat an earlier board position (ko).");

        return (new PreparedAction(trial, resolution.Captured, manaCost, isSkill, placed, swapped, seal, pushed),
            ValidationResult.Ok);
    }

    private static (PreparedAction?, ValidationResult) Fail(IllegalReason reason, string message) =>
        (null, ValidationResult.Fail(reason, message));
}
