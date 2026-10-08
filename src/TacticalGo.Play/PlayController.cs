using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public enum LibertyDisplay { Off, Danger, All }

/// <summary>How the feedback line should look.</summary>
public enum FeedbackKind { None, Info, Success, Warning, Error }

/// <summary>What the player is looking at after tapping one of the pieces.</summary>
public sealed record InspectInfo(IReadOnlyList<Point> Group, IReadOnlyCollection<Point> Liberties, Player Owner);

/// <summary>Live status of one commander, computed from the engine state every time (never cached or hard-coded).</summary>
public sealed record CommanderInfo(Player Owner, Point? At, int Liberties, IReadOnlyCollection<Point> LibertyPoints, IReadOnlyList<Point> Group)
{
    public bool Captured => At is null;
    public bool InDanger => !Captured && Liberties == 1;
}

/// <summary>
/// All play-session logic that is not drawing. It owns the single official <see cref="State"/>, the undo history and the
/// pending selection. It never evaluates a rule itself: legality comes from <see cref="ActionValidator"/>, previews and results
/// from <see cref="GameEngine.Apply"/> (which returns a new state and leaves the old one untouched).
/// </summary>
public sealed class PlayController
{
    private sealed record Snapshot(GameState State, int LogCount, IReadOnlyList<Point> LastPlaced);

    private readonly Stack<Snapshot> _undo = new();
    private readonly List<string> _log = [];

    public GameState State { get; private set; }
    public IReadOnlyList<string> Log => _log;
    public LibertyDisplay Liberties { get; set; } = LibertyDisplay.Danger;

    /// <summary>Point chosen for the next action. It is only a proposal until confirmed.</summary>
    public Point? Selected { get; private set; }
    public ValidationResult? SelectionResult { get; private set; }
    /// <summary>Outcome the confirmed action would produce; null when the selection is illegal. Never the official state.</summary>
    public ActionOutcome? Preview { get; private set; }
    public InspectInfo? Inspect { get; private set; }
    /// <summary>Board points that explain an illegal selection (display only), e.g. the enemy stones that leave no liberty.</summary>
    public IReadOnlyList<Point> RelatedPoints { get; private set; } = [];
    public IReadOnlyList<Point> LastPlaced { get; private set; } = [];

    /// <summary>What just happened / why the last click was refused.</summary>
    public string Feedback { get; private set; } = "";
    public FeedbackKind FeedbackKind { get; private set; }
    public bool CanUndo => _undo.Count > 0;
    public bool CanConfirm => Preview is not null && !GameOver;
    public bool GameOver => State.Status != GameStatus.Ongoing;
    public string RuleSummary { get; private set; } = "";

    public event Action? Changed;

    public PlayController(RuleConfig config, HeroClass classOne = HeroClass.None, HeroClass classTwo = HeroClass.None)
        : this(GameSetup.NewGame(config, classOne, classTwo), "新局") { }

    /// <summary>Start from any position (help diagrams, fixed tactical positions later).</summary>
    public PlayController(GameState initial, string startLabel = "載入局面")
    {
        State = initial;
        StartLog(startLabel);
    }

    public void NewGame(RuleConfig config, HeroClass classOne = HeroClass.None, HeroClass classTwo = HeroClass.None) =>
        Restart(GameSetup.NewGame(config, classOne, classTwo), "新局");

    public void Restart(GameState initial, string startLabel)
    {
        State = initial;
        _undo.Clear();
        _log.Clear();
        LastPlaced = [];
        ClearSelection();
        StartLog(startLabel);
        Raise();
    }

    private void StartLog(string startLabel)
    {
        var c = State.Config;
        RuleSummary = c.FirstTurnAp is { } first && first != c.ApPerTurn
            ? $"每回合 {c.ApPerTurn} AP；先手首回合 {first} AP"
            : $"每回合 {c.ApPerTurn} AP";
        Feedback = "";
        FeedbackKind = FeedbackKind.None;
        _log.Add($"— {startLabel}：{RuleSummary}");
        _log.Add($"— 第 {EventText.Round(State.Ply)} 輪・{EventText.Name(State.Current)}回合開始（ply {State.Ply}）AP {State.ApRemaining}");
    }

    // ---- derived display data (all computed from the engine state) ----

    /// <summary>Mana only matters once someone has a class (skills arrive in UI-2); hide it otherwise.</summary>
    public bool ShowMana => State.HeroClassOf(Player.One) != HeroClass.None || State.HeroClassOf(Player.Two) != HeroClass.None;

    public int Round => EventText.Round(State.Ply);

    public string TurnTitle => GameOver ? "對局結束" : $"第 {Round} 輪・{EventText.Name(State.Current)}回合";

    public string ResultText => State.Status switch
    {
        GameStatus.Won => $"★ {EventText.Name(State.Winner!.Value)}獲勝：{EventText.Name(State.Winner.Value.Opponent())}主將已被提掉",
        GameStatus.Drawn => "和局：達到回合上限，沒有人被提掉主將",
        _ => "",
    };

    public CommanderInfo Commander(Player owner)
    {
        if (State.Board.FindCommander(owner) is not { } at) return new CommanderInfo(owner, null, 0, [], []);
        var group = BoardRuleEngine.GetGroup(State.Board, at);
        var libs = BoardRuleEngine.GetLiberties(State.Board, group);
        return new CommanderInfo(owner, at, libs.Count, libs, group);
    }

    /// <summary>The single most useful sentence for "what can I do right now?".</summary>
    public string Hint
    {
        get
        {
            if (GameOver) return "對局結束。按「新局…」再玩一次，或「復原」回到上一步。";
            if (Selected is not null)
                return Preview is not null
                    ? "已選取：再點一次同一個點，或按「確認落子」。不想下就按「取消選取」。"
                    : "這個點不能下：請改點別的空交叉點。";
            return $"輪到{EventText.Name(State.Current)}（剩 {State.ApRemaining} AP）：點一個空交叉點，準備落子。點棋子可以看它的生存空格。";
        }
    }

    /// <summary>Short text drawn on the board next to the selected point (no hover needed).</summary>
    public string? Callout
    {
        get
        {
            if (Selected is null || SelectionResult is null) return null;
            if (!SelectionResult.IsLegal) return "✕ " + EventText.ShortReason(SelectionResult);
            var n = Preview!.Events.OfType<PiecesCaptured>().Sum(c => c.Pieces.Count);
            return n > 0 ? $"再點一次落子（提 {n} 子）" : "再點一次落子";
        }
    }

    // ---- input ----

    /// <summary>Tap on a board point. Empty point = select a placement (second tap on it confirms); piece = inspect its group.</summary>
    public void ClickPoint(Point p)
    {
        if (GameOver || !State.Board.InBounds(p)) return;

        if (State.Board[p] is not null)
        {
            InspectGroup(p);
        }
        else if (Selected == p && Preview is not null)
        {
            Confirm();
            return;
        }
        else
        {
            SelectPlacement(p);
        }
        Raise();
    }

    private void InspectGroup(Point p)
    {
        Selected = null; SelectionResult = null; Preview = null; RelatedPoints = [];
        var group = BoardRuleEngine.GetGroup(State.Board, p);
        var libs = BoardRuleEngine.GetLiberties(State.Board, group);
        var owner = State.Board[p]!.Value.Owner;
        Inspect = new InspectInfo(group, libs, owner);
        var kinds = group.Select(q => State.Board[q]!.Value.Kind).ToList();
        var extra = kinds.Contains(PieceKind.Commander) ? "（含主將）" : kinds.Contains(PieceKind.Hero) ? "（含英雄）" : "";
        Feedback = $"{EventText.Name(owner)}棋串{extra}：{group.Count} 子相連，共用 {libs.Count} 個生存空格（藍圈 = 這一串，藍點 = 生存空格）。";
        FeedbackKind = FeedbackKind.Info;
        if (libs.Count == 1)
        {
            Feedback += " 只剩 1 個，下一手就能提掉！";
            FeedbackKind = FeedbackKind.Warning;
        }
    }

    private void SelectPlacement(Point p)
    {
        Inspect = null;
        Selected = p;
        var action = new PlaceSoldier(p);
        SelectionResult = ActionValidator.Validate(State, action);
        if (!SelectionResult.IsLegal)
        {
            Preview = null;
            RelatedPoints = SelectionResult.Reason == IllegalReason.Suicide
                ? State.Board.Neighbors(p).Where(n => State.Board[n] is { } q && q.Owner != State.Current).ToList()
                : [];
            Feedback = $"{EventText.At(p)} 不能下：{EventText.Reason(SelectionResult)}";
            FeedbackKind = FeedbackKind.Error;
            return;
        }

        RelatedPoints = [];
        Preview = GameEngine.Apply(State, action);
        var captured = Preview.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).ToList();
        Feedback = captured.Count == 0
            ? $"已選取 {EventText.At(p)}（還沒落子）。"
            : $"已選取 {EventText.At(p)}（還沒落子）：落子會提掉 {captured.Count} 子"
              + (captured.Any(c => c.Piece.Kind == PieceKind.Commander) ? "，包含敵方主將，這手會獲勝！" : "（虛線圈）。");
        FeedbackKind = captured.Any(c => c.Piece.Kind == PieceKind.Commander) ? FeedbackKind.Warning : FeedbackKind.Info;
    }

    public void Confirm()
    {
        if (!CanConfirm || Selected is null) return;
        Commit(new PlaceSoldier(Selected.Value));
    }

    public void EndTurn()
    {
        if (GameOver) return;
        Commit(new EndTurn());
    }

    private void Commit(GameAction action)
    {
        var mover = State.Current;
        var snapshot = new Snapshot(State, _log.Count, LastPlaced);
        var outcome = GameEngine.Apply(State, action);
        if (!outcome.Success)
        {
            // The selection was validated earlier, so this only happens if state changed underneath us.
            Feedback = EventText.Reason(outcome.Validation);
            FeedbackKind = FeedbackKind.Error;
            Raise();
            return;
        }

        _undo.Push(snapshot);
        State = outcome.State;
        _log.AddRange(EventText.Describe(outcome.Events));
        LastPlaced = outcome.Events.OfType<PiecePlaced>().Select(e => e.At).ToList();
        ClearSelection();

        var captured = outcome.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).Count();
        var done = action is EndTurn
            ? $"✔ {EventText.Name(mover)}結束回合。"
            : $"✔ {EventText.Name(mover)}已在 {EventText.At(LastPlaced.FirstOrDefault())} 落子" + (captured > 0 ? $"，提掉 {captured} 子。" : "。");
        Feedback = GameOver
            ? ResultText
            : done + (State.Current != mover ? $" 換{EventText.Name(State.Current)}。" : $" 還有 {State.ApRemaining} AP。");
        FeedbackKind = FeedbackKind.Success;
        Raise();
    }

    public void Cancel()
    {
        ClearSelection();
        Feedback = "已取消選取，沒有任何改變。";
        FeedbackKind = FeedbackKind.Info;
        Raise();
    }

    /// <summary>Restores the exact earlier game state (board, AP, Mana, turn, seals, ko history) and its log.</summary>
    public void Undo()
    {
        if (_undo.Count == 0) return;
        var s = _undo.Pop();
        State = s.State;
        LastPlaced = s.LastPlaced;
        _log.RemoveRange(s.LogCount, _log.Count - s.LogCount);
        ClearSelection();
        Feedback = "已復原上一個行動。";
        FeedbackKind = FeedbackKind.Info;
        Raise();
    }

    private void ClearSelection()
    {
        Selected = null;
        SelectionResult = null;
        Preview = null;
        Inspect = null;
        RelatedPoints = [];
    }

    private void Raise() => Changed?.Invoke();
}
