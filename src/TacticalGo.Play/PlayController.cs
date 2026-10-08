using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public enum LibertyDisplay { Off, Danger, All }

/// <summary>What the player is looking at after tapping one of the pieces.</summary>
public sealed record InspectInfo(IReadOnlyList<Point> Group, IReadOnlyCollection<Point> Liberties, Player Owner);

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
    public IReadOnlyList<Point> LastPlaced { get; private set; } = [];

    public string Message { get; private set; } = "";
    public bool MessageIsError { get; private set; }
    public bool CanUndo => _undo.Count > 0;
    public bool CanConfirm => Preview is not null;
    public bool GameOver => State.Status != GameStatus.Ongoing;
    public string RuleSummary { get; private set; } = "";

    public event Action? Changed;

    public PlayController(RuleConfig config, HeroClass classOne = HeroClass.None, HeroClass classTwo = HeroClass.None)
    {
        State = GameSetup.NewGame(config, classOne, classTwo);
        StartLog(config);
    }

    public void NewGame(RuleConfig config, HeroClass classOne = HeroClass.None, HeroClass classTwo = HeroClass.None)
    {
        State = GameSetup.NewGame(config, classOne, classTwo);
        _undo.Clear();
        _log.Clear();
        LastPlaced = [];
        ClearSelection();
        StartLog(config);
        Raise();
    }

    private void StartLog(RuleConfig config)
    {
        RuleSummary = config.FirstTurnAp is { } first && first != config.ApPerTurn
            ? $"每回合 {config.ApPerTurn} AP；先手首回合 {first} AP"
            : $"每回合 {config.ApPerTurn} AP（先手首回合不減）";
        Message = "點空點選取落子位置；點棋子查看棋串與氣。";
        MessageIsError = false;
        _log.Add($"— 新局：{RuleSummary}");
        _log.Add($"— {EventText.Name(State.Current)} 回合開始（第 {State.Ply} 手）AP {State.ApRemaining}，Mana {State.ManaOf(State.Current)}");
    }

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
        Selected = null; SelectionResult = null; Preview = null;
        var group = BoardRuleEngine.GetGroup(State.Board, p);
        var libs = BoardRuleEngine.GetLiberties(State.Board, group);
        var owner = State.Board[p]!.Value.Owner;
        Inspect = new InspectInfo(group, libs, owner);
        var kinds = group.Select(q => State.Board[q]!.Value.Kind).ToList();
        var extra = kinds.Contains(PieceKind.Commander) ? "（含主將）" : kinds.Contains(PieceKind.Hero) ? "（含英雄）" : "";
        Message = $"{EventText.Name(owner)}棋串{extra}：{group.Count} 子，{libs.Count} 氣。";
        MessageIsError = libs.Count == 1;
        if (libs.Count == 1) Message += "（打吃！）";
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
            Message = $"{EventText.At(p)} 不能放：{SelectionResult.Message}";
            MessageIsError = true;
            return;
        }

        Preview = GameEngine.Apply(State, action);
        var captured = Preview.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).ToList();
        Message = captured.Count == 0
            ? $"落子 {EventText.At(p)}：再點一次或按「確認」。"
            : $"落子 {EventText.At(p)} 會提掉 {captured.Count} 子"
              + (captured.Any(c => c.Piece.Kind == PieceKind.Commander) ? "，包含敵方主將，這手會獲勝！" : "。")
              + "再點一次或按「確認」。";
        MessageIsError = false;
    }

    public void Confirm()
    {
        if (Preview is null || Selected is null || GameOver) return;
        Commit(new PlaceSoldier(Selected.Value));
    }

    public void EndTurn()
    {
        if (GameOver) return;
        Commit(new EndTurn());
    }

    private void Commit(GameAction action)
    {
        var snapshot = new Snapshot(State, _log.Count, LastPlaced);
        var outcome = GameEngine.Apply(State, action);
        if (!outcome.Success)
        {
            // The selection was validated earlier, so this only happens if state changed underneath us.
            Message = outcome.Validation.Message;
            MessageIsError = true;
            Raise();
            return;
        }

        _undo.Push(snapshot);
        State = outcome.State;
        _log.AddRange(EventText.Describe(outcome.Events));
        LastPlaced = outcome.Events.OfType<PiecePlaced>().Select(e => e.At).ToList();
        ClearSelection();
        Message = GameOver
            ? _log[^1]
            : $"{EventText.Name(State.Current)}行動：剩 {State.ApRemaining} AP。";
        MessageIsError = false;
        Raise();
    }

    public void Cancel()
    {
        ClearSelection();
        Message = "已取消選取。";
        MessageIsError = false;
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
        Message = "已復原上一個行動。";
        MessageIsError = false;
        Raise();
    }

    private void ClearSelection()
    {
        Selected = null;
        SelectionResult = null;
        Preview = null;
        Inspect = null;
    }

    private void Raise() => Changed?.Invoke();
}
