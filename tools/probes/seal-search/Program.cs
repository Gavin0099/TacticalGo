using System.Collections.Concurrent;
using System.Diagnostics;
using TacticalGo.Domain;

// Small, bounded search (NOT a general solver): is there a 7x7, 2 AP, responsive-opponent position in which "stone + seal"
// beats every plain alternative? Black has a Mage (seal), white has no class and answers with any 2-action turn.
//
// Two questions, both over random mid-game positions near the commanders:
//   ATTACK  : can black force a win within two black turns (black, white replies, black)?  with seal vs without seal
//   SURVIVE : when white would otherwise kill black next turn, can black survive one white turn? with seal vs without seal

const int Size = 7;
var budget = TimeSpan.FromSeconds(args.Length > 0 ? int.Parse(args[0]) : 120);
var rngSeed = args.Length > 1 ? int.Parse(args[1]) : 1;

string Key(GameState s) =>
    $"{s.Board.ComputeHash()}|{s.ManaOf(Player.One)}|{s.ApRemaining}|{s.SkillUsedThisTurn}|{s.Current}|{string.Join(',', s.Seals.Select(x => x.At))}";

HashSet<Point> Relevant(GameState s)
{
    var set = new HashSet<Point>();
    foreach (var owner in new[] { Player.One, Player.Two })
    {
        if (s.Board.FindCommander(owner) is not { } c) continue;
        var libs = BoardRuleEngine.GetLiberties(s.Board, BoardRuleEngine.GetGroup(s.Board, c));
        foreach (var l in libs)
        {
            set.Add(l);
            foreach (var n in s.Board.Neighbors(l)) if (s.Board.IsEmpty(n)) set.Add(n);
        }
    }
    return set;
}

IEnumerable<GameAction> Candidates(GameState s, bool allowSeal)
{
    var rel = Relevant(s);
    foreach (var p in rel.OrderBy(p => p.Y).ThenBy(p => p.X)) yield return new PlaceSoldier(p);
    if (allowSeal && s.Current == Player.One && s.Board.FindHero(Player.One) is { } hero)
        foreach (var p in rel.OrderBy(p => p.Y).ThenBy(p => p.X))
            if (p.ManhattanTo(hero) is >= 1 and <= 2) yield return new CastSeal(p);
}

// every state reachable by the current player's turn (stopping when the turn passes or the game ends)
void TurnEnds(GameState s, bool allowSeal, HashSet<string> seen, List<(GameState State, List<GameAction> Line)> outList, List<GameAction> line)
{
    var me = s.Current;
    IEnumerable<GameAction> actions = Candidates(s, allowSeal);
    if (s.ApRemaining < s.Config.ApPerTurn) actions = actions.Append(new EndTurn());
    foreach (var a in actions)
    {
        var o = GameEngine.Apply(s, a);
        if (!o.Success) continue;
        var n = o.State;
        var path = new List<GameAction>(line) { a };
        if (n.Status != GameStatus.Ongoing || n.Current != me) outList.Add((n, path));
        else if (seen.Add(Key(n))) TurnEnds(n, allowSeal, seen, outList, path);
    }
}

List<(GameState State, List<GameAction> Line)> Ends(GameState s, bool allowSeal)
{
    var list = new List<(GameState, List<GameAction>)>();
    TurnEnds(s, allowSeal, [], list, []);
    return list;
}

bool BlackWins(GameState s) => s.Status == GameStatus.Won && s.Winner == Player.One;
bool WhiteWins(GameState s) => s.Status == GameStatus.Won && s.Winner == Player.Two;

bool CanWinThisTurn(GameState s, bool allowSeal) => Ends(s, allowSeal).Any(e => BlackWins(e.State));

// black forces a win within two black turns
List<GameAction>? ForcedWin2(GameState s0, bool allowSeal)
{
    foreach (var (end1, line1) in Ends(s0, allowSeal))
    {
        if (BlackWins(end1)) return line1;
        if (end1.Status != GameStatus.Ongoing) continue;
        var ok = true;
        foreach (var (end2, _) in Ends(end1, false))            // white: plain actions only
        {
            if (WhiteWins(end2)) { ok = false; break; }
            if (end2.Status == GameStatus.Ongoing && !CanWinThisTurn(end2, allowSeal)) { ok = false; break; }
            if (end2.Status != GameStatus.Ongoing) { ok = false; break; }   // draw/other
        }
        if (ok) return line1;
    }
    return null;
}

// white can kill black within one white turn if black does nothing special (used to select SURVIVE positions)
bool WhiteThreatens(GameState s) => Ends(PassTurn(s), false).Any(e => WhiteWins(e.State));
GameState PassTurn(GameState s) => GameEngine.Apply(s, new EndTurn()).State;

List<GameAction>? Survives(GameState s0, bool allowSeal)
{
    foreach (var (end1, line1) in Ends(s0, allowSeal))
    {
        if (BlackWins(end1)) return line1;
        if (end1.Status != GameStatus.Ongoing) continue;
        if (!Ends(end1, false).Any(e => WhiteWins(e.State))) return line1;
    }
    return null;
}

GameState? RandomPosition(Random rng)
{
    var rows = Enumerable.Range(0, Size).Select(_ => new char[Size]).ToArray();
    foreach (var r in rows) Array.Fill(r, '.');
    bool Free(int x, int y) => x >= 0 && y >= 0 && x < Size && y < Size && rows[y][x] == '.';
    void Put(char c, int cx, int cy, int spread, int count)
    {
        for (var i = 0; i < count; i++)
        {
            for (var t = 0; t < 12; t++)
            {
                var x = cx + rng.Next(-spread, spread + 1);
                var y = cy + rng.Next(-spread, spread + 1);
                if (Free(x, y)) { rows[y][x] = c; break; }
            }
        }
    }

    var wx = rng.Next(2, 5); var wy = rng.Next(0, 3);
    var bx = rng.Next(2, 5); var by = rng.Next(4, 7);
    rows[wy][wx] = 'O';
    rows[by][bx] = 'X';
    Put('x', wx, wy, 2, rng.Next(2, 5));   // black attackers near the white commander
    Put('o', wx, wy, 2, rng.Next(1, 4));   // white defenders
    Put('o', bx, by, 2, rng.Next(2, 5));   // white attackers near the black commander
    Put('x', bx, by, 2, rng.Next(1, 4));   // black defenders
    // black Mage somewhere in the middle band, within seal range of the action
    for (var t = 0; t < 20; t++)
    {
        var hx = rng.Next(1, 6); var hy = rng.Next(1, 6);
        if (Free(hx, hy)) { rows[hy][hx] = 'H'; break; }
    }
    var diagram = string.Join("\n", rows.Select(r => new string(r)));
    try
    {
        var s = GameSetup.FromDiagram(new RuleConfig { BoardSize = Size, ApPerTurn = 2, FirstTurnAp = null, MaxPlies = 40 },
            diagram, HeroClass.Mage, HeroClass.None, Player.One, manaOne: 6, manaTwo: 3, ap: 2);
        // reject positions that are already over or contain a group with no liberties
        foreach (var p in s.Board.AllPoints())
            if (s.Board[p] is not null && BoardRuleEngine.CountLiberties(s.Board, p) == 0) return null;
        if (s.Board.FindHero(Player.One) is not { } hero) return null;

        // focus: positions where a seal could plausibly matter
        var white = s.Board.FindCommander(Player.Two)!.Value;
        var black = s.Board.FindCommander(Player.One)!.Value;
        var whiteLibs = BoardRuleEngine.GetLiberties(s.Board, BoardRuleEngine.GetGroup(s.Board, white));
        if (whiteLibs.Count < 2 || whiteLibs.Count > 4) return null;                       // an attack is in progress but not trivial
        if (BoardRuleEngine.CountLiberties(s.Board, black) < 3) return null;               // black is not already dying
        if (!whiteLibs.Any(l => hero.ManhattanTo(l) <= 3)) return null;                    // the Mage can reach the action
        if (CanWinThisTurn(s, false)) return null;                                         // skip one-turn wins
        return s;
    }
    catch { return null; }
}

var sw = Stopwatch.StartNew();
long tried = 0, attackBoth = 0, attackOnlySeal = 0, attackNeither = 0, attackWinNow = 0;
long survBoth = 0, survOnlySeal = 0, survNeither = 0, threatened = 0;
var examples = new ConcurrentBag<string>();
var rngMaster = new Random(rngSeed);
var seeds = Enumerable.Range(0, 1_000_000).Select(_ => rngMaster.Next()).ToArray();

Parallel.ForEach(seeds, new ParallelOptions { MaxDegreeOfParallelism = Math.Max(1, Environment.ProcessorCount - 1) }, (seed, loop) =>
{
    if (sw.Elapsed > budget) { loop.Stop(); return; }
    var rng = new Random(seed);
    var s = RandomPosition(rng);
    if (s is null) return;
    Interlocked.Increment(ref tried);

    // ATTACK
    var plainA = ForcedWin2(s, false);
    var sealA = plainA is not null ? plainA : ForcedWin2(s, true);
    if (plainA is not null) Interlocked.Increment(ref attackBoth);
    else if (sealA is not null)
    {
        Interlocked.Increment(ref attackOnlySeal);
        if (examples.Count < 4)
        {
            var line = string.Join(" -> ", sealA.Select(a => a.ToString()));
            examples.Add($"ATTACK-only-with-seal seed={seed}\n{BoardText.Render(s.Board)}\nwinning first turn: {line}");
        }
    }
    else Interlocked.Increment(ref attackNeither);

    // SURVIVE (only meaningful when white actually threatens a kill)
    if (WhiteThreatens(s))
    {
        Interlocked.Increment(ref threatened);
        var plainS = Survives(s, false);
        if (plainS is not null) Interlocked.Increment(ref survBoth);
        else
        {
            var sealS = Survives(s, true);
            if (sealS is not null)
            {
                Interlocked.Increment(ref survOnlySeal);
                if (examples.Count < 4)
                {
                    var line = string.Join(" -> ", sealS.Select(a => a.ToString()));
                    examples.Add($"SURVIVE-only-with-seal seed={seed}\n{BoardText.Render(s.Board)}\nsurviving first turn: {line}");
                }
            }
            else Interlocked.Increment(ref survNeither);
        }
    }
});

Console.WriteLine($"budget {budget.TotalSeconds:F0}s, elapsed {sw.Elapsed.TotalSeconds:F0}s, positions tried: {tried}");
Console.WriteLine($"ATTACK (force a win within 2 black turns, white answers with any 2-action turn):");
Console.WriteLine($"  winnable without seal : {attackBoth}");
Console.WriteLine($"  winnable ONLY with seal: {attackOnlySeal}");
Console.WriteLine($"  not winnable           : {attackNeither}");
Console.WriteLine($"SURVIVE (positions where white would kill black next turn): {threatened}");
Console.WriteLine($"  survivable without seal: {survBoth}");
Console.WriteLine($"  survivable ONLY with seal: {survOnlySeal}");
Console.WriteLine($"  not survivable          : {survNeither}");
foreach (var e in examples) Console.WriteLine("\n" + e);
