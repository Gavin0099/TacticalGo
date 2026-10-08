namespace TacticalGo.Domain;

/// <summary>Facts emitted by the engine. UI, audio and animation are presentations of these; they never decide outcomes.</summary>
public abstract record ActionEvent;

public sealed record ResourcesSpent(Player Player, int Ap, int Mana) : ActionEvent;

public sealed record PiecePlaced(Player Player, Point At, PieceKind Kind) : ActionEvent;

public sealed record PiecesSwapped(Player Player, Point A, Point B) : ActionEvent;

public sealed record PiecePushed(Player Caster, Point From, Point To, Piece Piece) : ActionEvent;

public sealed record SealPlaced(Player Caster, Player BlockedPlayer, Point At) : ActionEvent;

public sealed record SealExpired(Point At) : ActionEvent;

public sealed record PiecesCaptured(Player Capturer, IReadOnlyList<CapturedPiece> Pieces) : ActionEvent;

public sealed record TurnEnded(Player Player, int Ply) : ActionEvent;

public sealed record TurnStarted(Player Player, int Ply, int Ap, int Mana) : ActionEvent;

public sealed record GameWon(Player Winner) : ActionEvent;

public sealed record GameDrawn(string Reason) : ActionEvent;

public sealed record ActionOutcome(
    bool Success,
    ValidationResult Validation,
    GameState State,
    IReadOnlyList<ActionEvent> Events);
