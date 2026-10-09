using System.Text.Json;
using TacticalGo.Domain;

if (args.Length != 2) throw new ArgumentException("Usage: <golden-directory> <transcript.json>");
var records = new List<object>();
foreach (var file in Directory.GetFiles(args[0], "*.json").OrderBy(x => x, StringComparer.Ordinal))
{
    using var document = JsonDocument.Parse(File.ReadAllText(file));
    var root = document.RootElement;
    var config = new RuleConfig();
    foreach (var c in root.GetProperty("config").EnumerateObject()) config = c.Name switch
    {
        "mageSkill" => config with { MageSkill = Enum.Parse<MageSkill>(c.Value.GetString()!) },
        "magicHandRange" => config with { MagicHandRange = c.Value.GetInt32() },
        "boardSize" => config with { BoardSize = c.Value.GetInt32() },
        "apPerTurn" => config with { ApPerTurn = c.Value.GetInt32() },
        "firstTurnAp" => config with { FirstTurnAp = c.Value.ValueKind == JsonValueKind.Null ? null : c.Value.GetInt32() },
        "maxPlies" => config with { MaxPlies = c.Value.GetInt32() },
        "manaCap" => config with { ManaCap = c.Value.GetInt32() },
        "allowResummon" => config with { AllowResummon = c.Value.GetBoolean() },
        _ => throw new ArgumentException($"Unknown config {c.Name}")
    };
    var setup = root.GetProperty("setup");
    var classes = setup.GetProperty("classes").EnumerateArray().Select(x => Enum.Parse<HeroClass>(x.GetString()!)).ToArray();
    GameState state;
    if (setup.TryGetProperty("newGame", out var newGame) && newGame.GetBoolean()) state = GameSetup.NewGame(config, classes[0], classes[1]);
    else
    {
        var rows = setup.GetProperty("diagram").EnumerateArray().Select(x => new string(x.GetString()!.Where(c => !char.IsWhiteSpace(c)).ToArray())).ToList();
        while (rows.Count < config.BoardSize) rows.Add("");
        var mana = setup.GetProperty("mana").EnumerateArray().Select(x => x.GetInt32()).ToArray();
        var summoned = setup.GetProperty("heroSummoned").EnumerateArray().Select(x => x.GetBoolean()).ToArray();
        state = GameSetup.FromDiagram(config, string.Join('\n', rows.Select(x => x.PadRight(config.BoardSize, '.'))), classes[0], classes[1],
            Enum.Parse<Player>(setup.GetProperty("current").GetString()!), mana[0], mana[1], setup.GetProperty("ap").GetInt32(), 1, summoned[0], summoned[1]);
    }
    var name = Path.GetFileName(file);
    records.Add(Snapshot(name, 0, state, null));
    int step = 0;
    foreach (var item in root.GetProperty("steps").EnumerateArray())
    {
        var a = item.GetProperty("action");
        Point At(string key) => PointOf(a.GetProperty(key));
        GameAction action = a.GetProperty("type").GetString() switch
        {
            "PlaceSoldier" => new PlaceSoldier(At("at")), "SummonHero" => new SummonHero(At("at")),
            "CastBastion" => new CastBastion(At("first"), At("second")), "CastSeal" => new CastSeal(At("at")),
            "CastMagicHand" => new CastMagicHand(At("target"), Enum.Parse<PushDirection>(a.GetProperty("direction").GetString()!)),
            "CastSwap" => new CastSwap(At("target")), "EndTurn" => new EndTurn(), _ => throw new ArgumentException("Unknown action")
        };
        var outcome = GameEngine.Apply(state, action); state = outcome.State;
        records.Add(Snapshot(name, ++step, state, outcome));
    }
}
File.WriteAllText(args[1], JsonSerializer.Serialize(records, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine($"Exported {records.Count} reference snapshots (initial + each step).");

static Point PointOf(JsonElement e) => new(e[0].GetInt32(), e[1].GetInt32());
static int[] XY(Point p) => [p.X, p.Y];
static object Snapshot(string fixture, int step, GameState s, ActionOutcome? o) => new
{
    fixture, step, ok = o?.Success ?? true, reason = o?.Validation.Reason.ToString() ?? "None",
    diagram = s.Board.ToString(), current = s.Current.ToString(), ply = s.Ply, ap = s.ApRemaining,
    mana = new[] { s.ManaOf(Player.One), s.ManaOf(Player.Two) },
    classes = new[] { s.HeroClassOf(Player.One).ToString(), s.HeroClassOf(Player.Two).ToString() },
    summoned = new[] { s.HasSummonedHero(Player.One), s.HasSummonedHero(Player.Two) }, skill = s.SkillUsedThisTurn,
    status = s.Status.ToString(), winner = s.Winner?.ToString(),
    seals = s.Seals.Select(x => new { at = XY(x.At), caster = x.Caster.ToString(), blocked = x.BlockedPlayer.ToString() }),
    events = o?.Events.Select(Event) ?? []
};
static object Event(ActionEvent e) => e switch
{
    ResourcesSpent x => new { type = "ResourcesSpent", player = x.Player.ToString(), ap = x.Ap, mana = x.Mana },
    PiecePlaced x => new { type = "PiecePlaced", player = x.Player.ToString(), at = XY(x.At), kind = (int)x.Kind },
    PiecesSwapped x => new { type = "PiecesSwapped", player = x.Player.ToString(), a = XY(x.A), b = XY(x.B) },
    PiecePushed x => new { type = "PiecePushed", caster = x.Caster.ToString(), from = XY(x.From), to = XY(x.To), owner = x.Piece.Owner.ToString(), kind = (int)x.Piece.Kind },
    SealPlaced x => new { type = "SealPlaced", caster = x.Caster.ToString(), blocked = x.BlockedPlayer.ToString(), at = XY(x.At) },
    SealExpired x => new { type = "SealExpired", at = XY(x.At) },
    PiecesCaptured x => new { type = "PiecesCaptured", player = x.Capturer.ToString(), pieces = x.Pieces.Select(p => new { at = XY(p.At), owner = p.Piece.Owner.ToString(), kind = (int)p.Piece.Kind }) },
    TurnEnded x => new { type = "TurnEnded", player = x.Player.ToString(), ply = x.Ply },
    TurnStarted x => new { type = "TurnStarted", player = x.Player.ToString(), ply = x.Ply, ap = x.Ap, mana = x.Mana },
    GameWon x => new { type = "GameWon", winner = x.Winner.ToString() },
    GameDrawn x => new { type = "GameDrawn", reason = x.Reason },
    _ => throw new ArgumentException("Unknown event")
};
