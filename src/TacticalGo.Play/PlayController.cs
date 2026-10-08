using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public enum LibertyDisplay { Off, Danger, All }

/// <summary>How the feedback line should look.</summary>
public enum FeedbackKind { None, Info, Success, Warning, Error }

/// <summary>What a tap on the board means right now.</summary>
public enum PlayMode { Place, Skill }

public enum SkillState { None, Available, NoTargets, UsedThisTurn, NotEnoughMana, NoHero, Unsupported }

/// <summary>Whether the current player's hero skill can be started, and a plain-language line saying why/why not.</summary>
public sealed record SkillStatus(SkillState State, string Text)
{
    /// <summary>A legal skill action exists right now.</summary>
    public bool CanUse => State == SkillState.Available;

    /// <summary>
    /// The player may enter skill mode: either a legal target exists, or none does but they can still tap candidates
    /// and be told WHY (e.g. the swap would leave the Rogue without spaces).
    /// </summary>
    public bool CanBegin => State is SkillState.Available or SkillState.NoTargets;
}

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
///
/// Placing is two separate steps: tapping an empty point only selects it (a preview, no action is spent);
/// <see cref="Confirm"/> ("✔ 放這裡") is the only thing that places a stone.
/// </summary>
public sealed class PlayController
{
    private sealed record Snapshot(GameState State, int LogCount, IReadOnlyList<Point> LastPlaced, IReadOnlyList<Point> LastCaptured);

    private readonly Stack<Snapshot> _undo = new();
    private readonly List<string> _log = [];
    private GameAction? _pending;

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
    /// <summary>Points emptied by the last confirmed action, so the player can see what was just taken.</summary>
    public IReadOnlyList<Point> LastCaptured { get; private set; } = [];

    /// <summary>What just happened / why the last click was refused.</summary>
    public string Feedback { get; private set; } = "";
    public FeedbackKind FeedbackKind { get; private set; }

    /// <summary>
    /// Optional scripted opponent for tutorials: whenever it is Player Two's turn this chooses their action. The result is
    /// applied through the normal engine and is part of the same undo step as the player's action.
    /// </summary>
    public Func<GameState, GameAction>? OpponentPolicy { get; set; }

    /// <summary>When true, placing, ending the turn and undo are ignored (inspecting pieces still works).</summary>
    public bool Locked { get; set; }

    /// <summary>Place = taps select stones / inspect pieces. Skill = taps choose the target of the hero skill.</summary>
    public PlayMode Mode { get; private set; } = PlayMode.Place;

    /// <summary>Tutorials hide Mana numbers (they show <see cref="Skill"/> availability instead).</summary>
    public bool HideMana { get; set; }

    /// <summary>The two board points a previewed skill would affect (display only), e.g. both ends of a swap.</summary>
    public IReadOnlyList<Point> SkillPreviewPoints { get; private set; } = [];

    public bool CanUndo => _undo.Count > 0 && !Locked;
    public bool CanConfirm => Preview is not null && !GameOver && !Locked;
    public bool GameOver => State.Status != GameStatus.Ongoing;
    public string RuleSummary { get; private set; } = "";

    public event Action? Changed;

    public PlayController(RuleConfig config, HeroClass classOne = HeroClass.None, HeroClass classTwo = HeroClass.None)
        : this(GameSetup.NewGame(config, classOne, classTwo), "新局") { }

    /// <summary>Start from any position (tutorial stages, help diagrams, fixed tactical positions later).</summary>
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
        LastCaptured = [];
        Locked = false;
        Mode = PlayMode.Place;
        ClearSelection();
        StartLog(startLabel);
        Raise();
    }

    private void StartLog(string startLabel)
    {
        var c = State.Config;
        RuleSummary = c.FirstTurnAp is { } first && first != c.ApPerTurn
            ? $"每回合可行動 {c.ApPerTurn} 次；先手第一回合 {first} 次"
            : $"每回合可行動 {c.ApPerTurn} 次";
        Feedback = "";
        FeedbackKind = FeedbackKind.None;
        _log.Add($"— {startLabel}：{RuleSummary}");
        _log.Add($"— 第 {EventText.Round(State.Ply)} 輪・{EventText.Name(State.Current)}回合開始（ply {State.Ply}）可行動 {State.ApRemaining} 次");
    }

    // ---- derived display data (all computed from the engine state) ----

    /// <summary>Mana only matters once someone has a class (skills arrive later); hide it otherwise.</summary>
    public bool ShowMana => !HideMana && (State.HeroClassOf(Player.One) != HeroClass.None || State.HeroClassOf(Player.Two) != HeroClass.None);

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

    /// <summary>
    /// Availability of the current player's hero skill. Derived from the engine: a probe action with an impossible target is
    /// rejected for class/hero/once-per-turn/Mana reasons BEFORE the target is looked at, so those reasons surface first;
    /// if none apply, the legal action list says whether any target exists.
    /// </summary>
    public SkillStatus Skill
    {
        get
        {
            var me = State.Current;
            var heroClass = State.HeroClassOf(me);
            if (GameOver || heroClass == HeroClass.None) return new SkillStatus(SkillState.None, "");
            if (heroClass != HeroClass.Rogue)
                return new SkillStatus(SkillState.Unsupported, $"技能：{EventText.ClassName(heroClass)}的技能介面還沒做");

            switch (ActionValidator.Validate(State, new CastSwap(new Point(-1, -1))).Reason)
            {
                case IllegalReason.NoHeroOnBoard: return new SkillStatus(SkillState.NoHero, "技能：英雄不在場上");
                case IllegalReason.SkillAlreadyUsed: return new SkillStatus(SkillState.UsedThisTurn, "技能：本回合已經用過了");
                case IllegalReason.NotEnoughMana: return new SkillStatus(SkillState.NotEnoughMana, "技能：能量不足");
                case IllegalReason.NoActionPoints: return new SkillStatus(SkillState.None, "");
            }
            return ActionValidator.GetLegalActions(State).Any(a => a is CastSwap)
                ? new SkillStatus(SkillState.Available, "技能：換位（可用）")
                : new SkillStatus(SkillState.NoTargets, "技能：目前沒有合法的換位目標（點相鄰的敵方士兵可以看原因）");
        }
    }

    private GameState? _targetsFor;
    private IReadOnlyList<Point> _targets = [];

    /// <summary>
    /// Points the player may tap right now in skill mode (taken from the engine's legal action list), so the board can
    /// highlight them. Empty outside skill mode.
    /// </summary>
    public IReadOnlyList<Point> SkillTargets
    {
        get
        {
            if (Mode != PlayMode.Skill) return [];
            if (!ReferenceEquals(_targetsFor, State))
            {
                _targets = ActionValidator.GetLegalActions(State).OfType<CastSwap>().Select(a => a.Target).ToList();
                _targetsFor = State;
            }
            return _targets;
        }
    }

    /// <summary>Back to placing stones (leaves skill mode and drops any selected target).</summary>
    public void UsePlaceMode()
    {
        if (Mode == PlayMode.Place) return;
        Mode = PlayMode.Place;
        ClearSelection();
        Feedback = "回到放士兵：點棋盤上的空格預覽。";
        FeedbackKind = FeedbackKind.Info;
        Raise();
    }

    /// <summary>Label of the confirm button: it names what is about to happen.</summary>
    public string ConfirmLabel => Mode == PlayMode.Skill ? "✔ 確定換位" : "✔ 放這裡";

    /// <summary>One line for the fixed action area: what to do next / what is currently previewed.</summary>
    public string ActionBarInfo
    {
        get
        {
            if (Locked) return "這一段完成了";
            var skill = Mode == PlayMode.Skill;
            if (Selected is { } sel)
                return CanConfirm
                    ? (skill ? $"預覽換位 {EventText.At(sel)}：還沒施放" : $"預覽 {EventText.At(sel)}：還沒落子")
                    : $"{EventText.At(sel)} 不能{(skill ? "換位" : "下")}，請換一個點";
            return skill
                ? "① 點亮起的目標　② 看預覽　③ 按「✔ 確定換位」"
                : "① 點棋盤上的空格　② 看預覽　③ 按「✔ 放這裡」";
        }
    }

    private const string SwapHelp = "換位：選一顆與盜賊上下左右相鄰的敵方士兵（不能是主將或英雄）。";

    /// <summary>The single most useful sentence for "what can I do right now?".</summary>
    public string Hint
    {
        get
        {
            if (GameOver) return "對局結束。按「新局…」再玩一次，或「復原」回到上一步。";
            if (Locked) return "這一段完成了。";
            if (Mode == PlayMode.Skill)
                return Selected is null ? SwapHelp
                    : Preview is not null ? "這樣換位可以。按「✔ 放這裡」施放；或點別的目標；或按「取消」。"
                    : "這個目標不能換位：請改選別的敵方士兵。";
            if (Selected is not null)
                return Preview is not null
                    ? "這裡可以下。按「✔ 放這裡」落子；或點別的空格換位置；或按「取消」。"
                    : "這個點不能下：請改點別的空交叉點。";
            return $"輪到{EventText.Name(State.Current)}（還能行動 {State.ApRemaining} 次）：點一個空交叉點，先預覽。點棋子可以看它的生存空格。";
        }
    }

    /// <summary>Short text drawn on the board next to the selected point (no hover needed). Never contains a button.</summary>
    public string? Callout
    {
        get
        {
            if (Selected is null || SelectionResult is null) return null;
            if (!SelectionResult.IsLegal) return "✕ " + (Mode == PlayMode.Skill ? SkillShortReason(SelectionResult) : EventText.ShortReason(SelectionResult));
            var n = Preview!.Events.OfType<PiecesCaptured>().Sum(c => c.Pieces.Count);
            var what = Mode == PlayMode.Skill ? "換位" : "落子";
            return n > 0 ? $"預覽：{what}會提 {n} 子" : $"預覽（還沒{(Mode == PlayMode.Skill ? "施放" : "落子")}）";
        }
    }

    // ---- input ----

    /// <summary>Tap on a board point. Empty point = select it for a preview (spends nothing); piece = inspect its group.</summary>
    public void ClickPoint(Point p)
    {
        if (GameOver || !State.Board.InBounds(p)) return;

        if (Mode == PlayMode.Skill)
        {
            if (Locked) return;
            SelectSwapTarget(p);
        }
        else if (State.Board[p] is not null)
        {
            InspectGroup(p);
        }
        else
        {
            if (Locked) return;
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
        _pending = null;
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
        _pending = action;
        Preview = GameEngine.Apply(State, action);
        var captured = Preview.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).ToList();
        var takesCommander = captured.Any(c => c.Piece.Kind == PieceKind.Commander);
        Feedback = $"預覽 {EventText.At(p)}：還沒落子，不會用掉行動。"
            + (captured.Count == 0 ? "" : $" 落子會提掉 {captured.Count} 子（虛線圈）" + (takesCommander ? "，包含敵方主將，這手會獲勝！" : "。"));
        FeedbackKind = takesCommander ? FeedbackKind.Warning : FeedbackKind.Info;
    }

    /// <summary>"✔ 放這裡": the only way a stone is placed or a skill is cast.</summary>
    public void Confirm()
    {
        if (!CanConfirm || _pending is null) return;
        Commit(_pending);
    }

    // ---- hero skill (Rogue swap for now; other classes report "not supported yet") ----

    /// <summary>Enter skill mode if the skill can be used; otherwise explain why not (and stay in place mode).</summary>
    public bool BeginSkill()
    {
        if (GameOver || Locked) return false;
        var status = Skill;
        if (!status.CanBegin)
        {
            Feedback = status.State == SkillState.None ? "你沒有可用的英雄技能。" : status.Text.Replace("技能：", "還不能用技能：");
            FeedbackKind = FeedbackKind.Error;
            Raise();
            return false;
        }

        ClearSelection();
        Mode = PlayMode.Skill;
        Feedback = status.CanUse ? SwapHelp : SwapHelp + " 目前沒有合法的目標；點相鄰的敵方士兵可以看為什麼不行。";
        FeedbackKind = status.CanUse ? FeedbackKind.Info : FeedbackKind.Warning;
        Raise();
        return true;
    }

    private void SelectSwapTarget(Point p)
    {
        Inspect = null;
        Selected = p;
        var hero = State.Board.FindHero(State.Current);
        var action = new CastSwap(p);
        _pending = null;
        SkillPreviewPoints = [];
        SelectionResult = ActionValidator.Validate(State, action);
        if (!SelectionResult.IsLegal)
        {
            Preview = null;
            RelatedPoints = hero is { } h ? [h] : [];
            Feedback = $"{EventText.At(p)} 不能換位：{SkillReason(SelectionResult)}";
            FeedbackKind = FeedbackKind.Error;
            return;
        }

        RelatedPoints = [];
        _pending = action;
        Preview = GameEngine.Apply(State, action);
        SkillPreviewPoints = hero is { } from ? [from, p] : [p];
        var captured = Preview.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).ToList();
        var takesCommander = captured.Any(c => c.Piece.Kind == PieceKind.Commander);
        Feedback = $"換位預覽 {(hero is { } a ? EventText.At(a) : "")} ⇄ {EventText.At(p)}：還沒施放。"
            + (captured.Count == 0 ? "" : $" 會提掉 {captured.Count} 子" + (takesCommander ? "，含敵方主將，這手會獲勝！" : "。"));
        FeedbackKind = takesCommander ? FeedbackKind.Warning : FeedbackKind.Info;
    }

    private static string SkillReason(ValidationResult r) => r.Reason switch
    {
        IllegalReason.InvalidTarget or IllegalReason.OutOfRange => "目標要是和盜賊上下左右相鄰的敵方士兵（不能是空格、己方棋子、主將或英雄）。",
        IllegalReason.Suicide => "換位後盜賊自己會沒有生存空格（自殺），而且提不掉對方的子。",
        IllegalReason.Ko => "打劫：換位會讓盤面回到之前出現過的樣子。",
        _ => EventText.Reason(r),
    };

    private static string SkillShortReason(ValidationResult r) => r.Reason switch
    {
        IllegalReason.InvalidTarget or IllegalReason.OutOfRange => "要選相鄰的敵方士兵",
        IllegalReason.Suicide => "換位後會自殺",
        IllegalReason.Ko => "打劫：不能重複盤面",
        _ => "不能換位",
    };

    public void EndTurn()
    {
        if (GameOver || Locked) return;
        Commit(new EndTurn());
    }

    private void Commit(GameAction action)
    {
        var mover = State.Current;
        var snapshot = new Snapshot(State, _log.Count, LastPlaced, LastCaptured);
        var wasSkill = Mode == PlayMode.Skill;
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
        LastPlaced = outcome.Events.OfType<PiecePlaced>().Select(e => e.At)
            .Concat(outcome.Events.OfType<PiecesSwapped>().SelectMany(e => new[] { e.A, e.B })).ToList();
        var captured = outcome.Events.OfType<PiecesCaptured>().SelectMany(c => c.Pieces).ToList();
        LastCaptured = captured.Select(c => c.At).ToList();
        Mode = PlayMode.Place;
        ClearSelection();

        var opponentActed = RunOpponent();

        var done = action switch
        {
            TacticalGo.Domain.EndTurn => $"✔ {EventText.Name(mover)}結束回合。",
            CastSwap when wasSkill => $"✔ {EventText.Name(mover)}用盜賊換位" + (captured.Count > 0 ? $"，提掉 {captured.Count} 子！" : "。"),
            _ => $"✔ {EventText.Name(mover)}已在 {EventText.At(LastPlaced.FirstOrDefault())} 落子" + (captured.Count > 0 ? $"，提掉 {captured.Count} 子！" : "。"),
        };
        if (GameOver)
        {
            Feedback = ResultText;
        }
        else
        {
            Feedback = done
                + (opponentActed ? $" {EventText.Name(mover.Opponent())}沒有動作。" : "")
                + (State.Current == mover ? $" 還能行動 {State.ApRemaining} 次。" : $" 換{EventText.Name(State.Current)}。");
        }
        FeedbackKind = FeedbackKind.Success;
        Raise();
    }

    /// <summary>Plays the scripted opponent's turn(s), if any. Returns true if it acted.</summary>
    private bool RunOpponent()
    {
        var acted = false;
        for (var guard = 0; guard < 8 && OpponentPolicy is not null && !GameOver && State.Current == Player.Two; guard++)
        {
            var outcome = GameEngine.Apply(State, OpponentPolicy(State));
            if (!outcome.Success) break;
            State = outcome.State;
            _log.AddRange(EventText.Describe(outcome.Events));
            acted = true;
        }
        return acted;
    }

    public void Cancel()
    {
        var leaveSkill = Mode == PlayMode.Skill && Selected is null;
        if (leaveSkill) Mode = PlayMode.Place;
        ClearSelection();
        Feedback = leaveSkill ? "已離開技能，回到放士兵。" : "已取消，沒有任何改變。";
        FeedbackKind = FeedbackKind.Info;
        Raise();
    }

    /// <summary>Restores the exact earlier game state (board, AP, Mana, turn, seals, ko history) and its log.</summary>
    public void Undo()
    {
        if (!CanUndo) return;
        var s = _undo.Pop();
        State = s.State;
        LastPlaced = s.LastPlaced;
        LastCaptured = s.LastCaptured;
        _log.RemoveRange(s.LogCount, _log.Count - s.LogCount);
        Mode = PlayMode.Place;
        ClearSelection();
        Feedback = "已復原上一個行動。";
        FeedbackKind = FeedbackKind.Info;
        Raise();
    }

    private void ClearSelection()
    {
        _pending = null;
        SkillPreviewPoints = [];
        Selected = null;
        SelectionResult = null;
        Preview = null;
        Inspect = null;
        RelatedPoints = [];
    }

    private void Raise() => Changed?.Invoke();
}
