using TacticalGo.Domain;
using TacticalGo.Sim;

var mode = args.Length > 0 ? args[0] : "help";
var games = args.Length > 1 && int.TryParse(args[1], out var g) ? g : 200;

switch (mode)
{
    case "ap": ApCompare(games); break;
    case "classes": ClassMatrix(games); break;
    case "show": Show(args.Length > 1 && int.TryParse(args[1], out var seed) ? seed : 1); break;
    default:
        Console.WriteLine("usage: Sim <ap|classes|show> [games|seed]");
        break;
}

static void ApCompare(int games)
{
    Console.WriteLine($"S0 AP comparison — heuristic vs heuristic, no hero classes, 9x9, {games} games each\n");
    var configs = new (string Label, RuleConfig Config)[]
    {
        ("1 AP", RuleConfig.TwoApBaseline with { ApPerTurn = 1, MaxPlies = 200 }),
        ("2 AP baseline", RuleConfig.TwoApBaseline),
        ("2 AP, first turn 1 AP (default)", new RuleConfig()),
    };
    foreach (var (label, config) in configs)
    {
        var results = Runner.Batch(games, i =>
            Runner.PlayOne(config, HeroClass.None, HeroClass.None, new HeuristicBot(i * 2 + 1), new HeuristicBot(i * 2 + 2)));
        Console.WriteLine(Runner.Summarize(label, results));
    }
}

static void ClassMatrix(int games)
{
    Console.WriteLine($"S1 class matrix — heuristic vs heuristic, Draft default rules (first turn 1 AP, no resummon), {games} games per cell (P1 row vs P2 column)\n");
    var classes = new[] { HeroClass.None, HeroClass.Warrior, HeroClass.Mage, HeroClass.Rogue };
    var config = new RuleConfig();
    foreach (var c1 in classes)
        foreach (var c2 in classes)
        {
            var results = Runner.Batch(games, i =>
                Runner.PlayOne(config, c1, c2, new HeuristicBot(i * 2 + 1), new HeuristicBot(i * 2 + 2)));
            var skills = results.Average(r => r.SkillsCast);
            Console.WriteLine($"{Runner.Summarize($"{c1} vs {c2}", results)}  skills/game {skills:F1}");
        }
}

static void Show(int seed)
{
    var config = new RuleConfig();
    var session = new GameSession(GameSetup.NewGame(config, HeroClass.Warrior, HeroClass.Rogue));
    var bots = new IBot[] { new HeuristicBot(seed * 2 + 1), new HeuristicBot(seed * 2 + 2) };
    while (session.State.Status == GameStatus.Ongoing)
    {
        var s = session.State;
        var action = bots[(int)s.Current].Choose(s);
        Console.WriteLine($"ply {s.Ply} {s.Current} ap={s.ApRemaining} mana={s.ManaOf(s.Current)}: {action}");
        session.Apply(action);
    }
    Console.WriteLine(session.State.Board);
    Console.WriteLine($"{session.State.Status} winner={session.State.Winner} ply={session.State.Ply}");
}
