namespace TacticalGo.Domain;

public enum Player : byte { One = 0, Two = 1 }

public static class PlayerExtensions
{
    public static Player Opponent(this Player p) => p == Player.One ? Player.Two : Player.One;
}

public enum PieceKind : byte { Soldier = 0, Commander = 1, Hero = 2 }

public enum HeroClass : byte { None = 0, Warrior = 1, Mage = 2, Rogue = 3 }

public enum GameStatus : byte { Ongoing = 0, Won = 1, Drawn = 2 }

public readonly record struct Point(int X, int Y)
{
    public int ManhattanTo(Point other) => Math.Abs(X - other.X) + Math.Abs(Y - other.Y);

    public override string ToString() => $"({X},{Y})";
}

public readonly record struct Piece(Player Owner, PieceKind Kind);

public readonly record struct CapturedPiece(Point At, Piece Piece);
