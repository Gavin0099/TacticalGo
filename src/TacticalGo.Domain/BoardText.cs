using System.Text;

namespace TacticalGo.Domain;

/// <summary>
/// Text diagram used by tests, scenarios and the console simulator.
/// '.' empty | Player One: x soldier, X commander, H hero | Player Two: o soldier, O commander, Q hero
/// Rows run top (Y=0) to bottom; whitespace between cells is ignored.
/// </summary>
public static class BoardText
{
    public static char ToChar(Piece? piece) => piece switch
    {
        null => '.',
        { Owner: Player.One, Kind: PieceKind.Soldier } => 'x',
        { Owner: Player.One, Kind: PieceKind.Commander } => 'X',
        { Owner: Player.One, Kind: PieceKind.Hero } => 'H',
        { Owner: Player.Two, Kind: PieceKind.Soldier } => 'o',
        { Owner: Player.Two, Kind: PieceKind.Commander } => 'O',
        { Owner: Player.Two, Kind: PieceKind.Hero } => 'Q',
        _ => '?',
    };

    public static Piece? FromChar(char c) => c switch
    {
        '.' => null,
        'x' => new Piece(Player.One, PieceKind.Soldier),
        'X' => new Piece(Player.One, PieceKind.Commander),
        'H' => new Piece(Player.One, PieceKind.Hero),
        'o' => new Piece(Player.Two, PieceKind.Soldier),
        'O' => new Piece(Player.Two, PieceKind.Commander),
        'Q' => new Piece(Player.Two, PieceKind.Hero),
        _ => throw new FormatException($"Unknown board character '{c}'."),
    };

    public static string Render(Board board)
    {
        var sb = new StringBuilder();
        for (var y = 0; y < board.Size; y++)
        {
            for (var x = 0; x < board.Size; x++)
                sb.Append(ToChar(board[new Point(x, y)]));
            if (y < board.Size - 1) sb.Append('\n');
        }
        return sb.ToString();
    }

    public static Board Parse(string diagram)
    {
        var rows = diagram
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(r => new string(r.Where(ch => !char.IsWhiteSpace(ch)).ToArray()))
            .Where(r => r.Length > 0)
            .ToList();
        if (rows.Count == 0 || rows.Any(r => r.Length != rows.Count))
            throw new FormatException("Board diagram must be a non-empty square.");

        var board = new Board(rows.Count);
        for (var y = 0; y < rows.Count; y++)
            for (var x = 0; x < rows.Count; x++)
                board[new Point(x, y)] = FromChar(rows[y][x]);
        return board;
    }
}
