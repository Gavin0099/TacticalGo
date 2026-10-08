using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

/// <summary>One short stage of a tutorial level. Positions are text diagrams loaded through the real engine.</summary>
public sealed record LevelStage(
    string Title,
    string Goal,
    string Instruction,
    string[] Diagram,
    int ActionsPerTurn,
    Func<GameState, bool> IsComplete,
    Func<GameState, string> Learned,
    HeroClass PlayerClass = HeroClass.None,
    int Mana = 3)
{
    public GameState CreateState()
    {
        var config = new RuleConfig { BoardSize = Diagram.Length, ApPerTurn = ActionsPerTurn, FirstTurnAp = null, MaxPlies = 60 };
        return GameSetup.FromDiagram(config, string.Join(Environment.NewLine, Diagram),
            PlayerClass, HeroClass.None, Player.One, manaOne: Mana, ap: ActionsPerTurn);
    }
}

public sealed record LevelDefinition(int Number, string Title, IReadOnlyList<LevelStage> Stages, string AfterLastStage);

/// <summary>
/// Runs a tutorial level on top of a <see cref="PlayController"/>: loads each stage's position, plays the scripted
/// (passive) opponent, detects completion from the engine state, and locks the board when a stage is done.
/// Create it BEFORE the UI subscribes to the controller so completion is already known when the UI refreshes.
/// </summary>
public sealed class LevelSession
{
    private readonly LevelDefinition _level;

    public PlayController Play { get; }
    public int StageIndex { get; private set; }
    public bool StageComplete { get; private set; }
    public string Learned { get; private set; } = "";

    private bool _active = true;

    /// <summary>
    /// False while the player is in free play: the session then ignores the controller entirely (and Mana numbers are shown
    /// again). While active, Mana numbers are hidden; skills are presented as available / not available instead.
    /// </summary>
    public bool Active
    {
        get => _active;
        set
        {
            _active = value;
            Play.HideMana = value;
        }
    }

    public LevelSession(PlayController play, LevelDefinition level)
    {
        Play = play;
        _level = level;
        play.Changed += OnPlayChanged;
        StartStage(0);
    }

    public LevelDefinition Level => _level;
    public LevelStage Stage => _level.Stages[StageIndex];
    public bool IsLastStage => StageIndex == _level.Stages.Count - 1;
    public bool LevelComplete => StageComplete && IsLastStage;
    public string Progress => $"第 {_level.Number} 關・{StageIndex + 1}／{_level.Stages.Count}　{Stage.Title}";

    public void StartStage(int index)
    {
        Active = true;
        StageIndex = Math.Clamp(index, 0, _level.Stages.Count - 1);
        StageComplete = false;
        Learned = "";
        Play.OpponentPolicy = _ => new EndTurn();   // tutorial opponent does nothing
        Play.Restart(Stage.CreateState(), $"第 {_level.Number} 關・{Stage.Title}");
    }

    public void RestartStage() => StartStage(StageIndex);

    public void NextStage()
    {
        if (StageComplete && !IsLastStage) StartStage(StageIndex + 1);
    }

    private void OnPlayChanged()
    {
        if (!Active || StageComplete || !Stage.IsComplete(Play.State)) return;
        StageComplete = true;
        Learned = Stage.Learned(Play.State);
        Play.Locked = true;
    }
}

public static class LevelCatalog
{
    private static bool Won(GameState s) => s.Status == GameStatus.Won && s.Winner == Player.One;

    /// <summary>
    /// Level 1 teaches only: placing, capturing, shared spaces of connected pieces, and two actions in one turn.
    /// The opponent never moves, so this level does NOT teach attack-versus-defence trade-offs.
    /// </summary>
    public static LevelDefinition Level1() => new(
        Number: 1,
        Title: "包圍",
        Stages:
        [
            new LevelStage(
                Title: "提掉被圍住的子",
                Goal: "目標：提掉被圍住的白子",
                Instruction: "白子只剩 1 個生存空格（紅色的 1）。點它旁邊的空格預覽，再按「✔ 放這裡」。",
                Diagram:
                [
                    "...O...",
                    ".......",
                    "...x...",
                    "..xox..",
                    ".......",
                    ".......",
                    "...X...",
                ],
                ActionsPerTurn: 1,
                IsComplete: s => s.Board[new Point(3, 3)] is null,
                Learned: _ => "✔ 生存空格被填滿，棋子就被提走了！"),

            new LevelStage(
                Title: "圍住相連的整串",
                Goal: "目標：包圍並提吃白色的「主」",
                Instruction: "白主將旁邊看起來被圍住了，但它和白兵相連，共用生存空格。點白棋看看，再把整串圍住。",
                Diagram:
                [
                    "...x...",
                    "..xOx..",
                    "..xo...",
                    ".......",
                    ".......",
                    ".......",
                    "...X...",
                ],
                ActionsPerTurn: 1,
                IsComplete: Won,
                Learned: _ => "✔ 相連的棋共用生存空格，要把整串都圍住才會被提。"),

            new LevelStage(
                Title: "同一回合行動兩次",
                Goal: "目標：這回合連下兩子，包圍白主將",
                Instruction: "這一段每回合可以行動 2 次。先放第 1 子，再放第 2 子。",
                Diagram:
                [
                    ".......",
                    ".......",
                    "..xOx..",
                    ".......",
                    ".......",
                    ".......",
                    "...X...",
                ],
                ActionsPerTurn: 2,
                IsComplete: Won,
                Learned: s => s.Ply == 1
                    ? "✔ 一回合連下兩子，一次圍死！"
                    : "✔ 完成！下次可以一回合就連下兩子。"),
        ],
        AfterLastStage: "第 1 關完成！下一關：盜賊換位（尚未製作）。可以按「重來本段」再玩，或到「新局…」自由對局。");

    /// <summary>
    /// Level 2 (logic and data only for now; the UI is not wired to it yet): the hero is already on the board, the player has
    /// the Rogue's swap. Either route wins; the swap is simply faster. The opponent never moves, so this does NOT teach
    /// attack-versus-defence, and "faster" is only a property of the positions (see LevelSearchTests), not proof of fun.
    /// </summary>
    public static LevelDefinition Level2() => new(
        Number: 2,
        Title: "換位",
        Stages:
        [
            new LevelStage(
                Title: "盜賊換位破陣",
                Goal: "目標：包圍並提吃白色的「主」（用技能更快）",
                Instruction: "白主將被三顆白兵擋在後面，普通圍法要放很多子。試試「技能：換位」：和相鄰的白兵交換位置。",
                Diagram:
                [
                    "...x...",
                    "..xOx..",
                    "..ooo..",
                    "...H...",
                    ".......",
                    ".......",
                    "...X...",
                ],
                ActionsPerTurn: 1,
                IsComplete: Won,
                Learned: s => s.Ply == 1
                    ? "✔ 換位！盜賊和白兵交換位置，一步就破了陣。"
                    : "✔ 完成！其實用「換位」一步就能破陣，下次試試。",
                PlayerClass: HeroClass.Rogue),

            new LevelStage(
                Title: "技能加落子",
                Goal: "目標：這回合用技能再放一子，包圍白主將",
                Instruction: "這一段每回合可以行動 2 次。技能和放子各算 1 次，這個局面兩種順序都行得通。",
                Diagram:
                [
                    "...x...",
                    "..xO...",
                    "..oo...",
                    "...H...",
                    ".......",
                    ".......",
                    "...X...",
                ],
                ActionsPerTurn: 2,
                IsComplete: Won,
                Learned: s => s.Ply == 1
                    ? "✔ 換位＋放子，同一回合完成！"
                    : "✔ 完成！其實一回合就能用技能再放一子，下次試試。",
                PlayerClass: HeroClass.Rogue),
        ],
        AfterLastStage: "第 2 關完成！（職業自由挑戰尚未製作）");
}
