using System.Drawing.Drawing2D;
using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

/// <summary>Draws the board for a <see cref="PlayController"/> and reports taps. Contains no rules.</summary>
public sealed class BoardView : Control
{
    private static readonly Color Wood = Color.FromArgb(0xE3, 0xC5, 0x8E);
    private static readonly Color Grid = Color.FromArgb(0x7A, 0x5C, 0x2A);
    private static readonly Color Black = Color.FromArgb(0x1C, 0x1C, 0x1C);
    private static readonly Color White = Color.FromArgb(0xF7, 0xF7, 0xF2);
    private static readonly Color Danger = Color.FromArgb(0xC0, 0x39, 0x2B);
    private static readonly Color Accent = Color.FromArgb(0x25, 0x63, 0xEB);
    private static readonly Color Good = Color.FromArgb(0x2F, 0x9E, 0x5B);
    private static readonly Color SealColor = Color.FromArgb(0x6D, 0x4A, 0xA8);

    private readonly PlayController _play;

    public event Action<Point>? PointTapped;

    /// <summary>False for the non-clickable diagrams in the help window.</summary>
    [System.ComponentModel.Browsable(false)]
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public bool Interactive { get; set; } = true;

    public BoardView(PlayController play)
    {
        _play = play;
        DoubleBuffered = true;
        ResizeRedraw = true;
        MinimumSize = new Size(420, 420);
    }

    private int N => _play.State.Board.Size;

    private float Cell => Math.Min(Width, Height) / (float)(N + 1);

    private PointF Origin => new((Width - Cell * (N + 1)) / 2f + Cell, (Height - Cell * (N + 1)) / 2f + Cell);

    private PointF Center(Point p) => new(Origin.X + p.X * Cell, Origin.Y + p.Y * Cell);

    /// <summary>Board point under a pixel, or null if the tap is not near any intersection.</summary>
    public Point? HitTest(System.Drawing.Point pixel)
    {
        var x = (int)Math.Round((pixel.X - Origin.X) / Cell);
        var y = (int)Math.Round((pixel.Y - Origin.Y) / Cell);
        var p = new Point(x, y);
        return _play.State.Board.InBounds(p) ? p : null;
    }

    protected override void OnMouseClick(MouseEventArgs e)
    {
        base.OnMouseClick(e);
        if (Interactive && e.Button == MouseButtons.Left && HitTest(e.Location) is { } p) PointTapped?.Invoke(p);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
        g.Clear(Wood);

        var state = _play.State;
        var board = state.Board;
        var cell = Cell;
        var stone = cell * 0.44f;

        using var gridPen = new Pen(Grid, Math.Max(1f, cell / 40f));
        using var labelFont = new Font("Segoe UI", Math.Max(7f, cell / 6f));
        using var labelBrush = new SolidBrush(Grid);
        for (var i = 0; i < N; i++)
        {
            var a = Center(new Point(0, i));
            var b = Center(new Point(N - 1, i));
            g.DrawLine(gridPen, a, b);
            var c = Center(new Point(i, 0));
            var d = Center(new Point(i, N - 1));
            g.DrawLine(gridPen, c, d);
            g.DrawString(i.ToString(), labelFont, labelBrush, c.X - 5, c.Y - cell * 0.8f);
            g.DrawString(i.ToString(), labelFont, labelBrush, a.X - cell * 0.8f, a.Y - 8);
        }
        if (N == 9)
        {
            foreach (var (sx, sy) in new[] { (2, 2), (6, 2), (2, 6), (6, 6), (4, 4) })
            {
                var c = Center(new Point(sx, sy));
                g.FillEllipse(labelBrush, c.X - 3, c.Y - 3, 6, 6);
            }
        }

        DrawSeals(g, state, cell);
        DrawInspectLiberties(g, cell);

        foreach (var p in board.AllPoints())
        {
            if (board[p] is { } piece) DrawPiece(g, p, piece, state, stone);
        }

        DrawLastPlaced(g, stone);
        DrawCommanderDanger(g, cell);
        DrawLibertyNumbers(g, state, cell);
        DrawRelated(g, stone);
        DrawSelection(g, state, stone);
        if (_play.GameOver) DrawGameOver(g, state);
    }

    private void DrawSeals(Graphics g, GameState state, float cell)
    {
        using var fill = new SolidBrush(Color.FromArgb(70, SealColor));
        using var pen = new Pen(SealColor, 2.5f) { DashStyle = DashStyle.Dash };
        using var font = new Font("Microsoft JhengHei UI", cell * 0.32f, FontStyle.Bold);
        using var brush = new SolidBrush(SealColor);
        foreach (var seal in state.Seals)
        {
            var c = Center(seal.At);
            var r = new RectangleF(c.X - cell * 0.4f, c.Y - cell * 0.4f, cell * 0.8f, cell * 0.8f);
            g.FillRectangle(fill, r);
            g.DrawRectangle(pen, r.X, r.Y, r.Width, r.Height);
            DrawCentered(g, "封", font, brush, c);
        }
    }

    private void DrawInspectLiberties(Graphics g, float cell)
    {
        if (_play.Inspect is not { } inspect) return;
        using var ring = new Pen(Accent, 3f);
        foreach (var p in inspect.Group)
        {
            var c = Center(p);
            g.DrawEllipse(ring, c.X - cell * 0.5f, c.Y - cell * 0.5f, cell, cell);
        }
        using var dot = new SolidBrush(Accent);
        foreach (var p in inspect.Liberties)
        {
            var c = Center(p);
            g.FillEllipse(dot, c.X - cell * 0.13f, c.Y - cell * 0.13f, cell * 0.26f, cell * 0.26f);
        }
    }

    private void DrawPiece(Graphics g, Point p, Piece piece, GameState state, float r)
    {
        var c = Center(p);
        var fill = piece.Owner == Player.One ? Black : White;
        var ink = piece.Owner == Player.One ? White : Black;
        using var fillBrush = new SolidBrush(fill);
        using var inkBrush = new SolidBrush(ink);
        using var edge = new Pen(Color.FromArgb(0x1D, 0x1B, 0x16), piece.Kind == PieceKind.Commander ? r / 6f : r / 14f);
        using var font = new Font("Microsoft JhengHei UI", r * 1.0f, FontStyle.Bold, GraphicsUnit.Pixel);

        if (piece.Kind == PieceKind.Hero)
        {
            var d = r * 1.15f;
            PointF[] diamond = [new(c.X, c.Y - d), new(c.X + d, c.Y), new(c.X, c.Y + d), new(c.X - d, c.Y)];
            g.FillPolygon(fillBrush, diamond);
            g.DrawPolygon(edge, diamond);
            DrawCentered(g, EventText.ClassGlyph(state.HeroClassOf(piece.Owner)).ToString(), font, inkBrush, c);
            return;
        }

        g.FillEllipse(fillBrush, c.X - r, c.Y - r, r * 2, r * 2);
        g.DrawEllipse(edge, c.X - r, c.Y - r, r * 2, r * 2);
        if (piece.Kind == PieceKind.Commander)
        {
            using var inner = new Pen(ink, r / 14f);
            g.DrawEllipse(inner, c.X - r * 0.72f, c.Y - r * 0.72f, r * 1.44f, r * 1.44f);
            DrawCentered(g, "主", font, inkBrush, c);
        }
    }

    private void DrawLastPlaced(Graphics g, float r)
    {
        using var pen = new Pen(Danger, 2.5f);
        foreach (var p in _play.LastPlaced)
        {
            if (_play.State.Board[p] is null) continue;
            var c = Center(p);
            g.DrawEllipse(pen, c.X - r * 0.28f, c.Y - r * 0.28f, r * 0.56f, r * 0.56f);
        }
    }

    private void DrawLibertyNumbers(Graphics g, GameState state, float cell)
    {
        if (_play.Liberties == LibertyDisplay.Off) return;
        var board = state.Board;
        var seen = new HashSet<Point>();
        using var font = new Font("Segoe UI", Math.Max(8f, cell * 0.24f), FontStyle.Bold);
        foreach (var p in board.AllPoints())
        {
            if (board[p] is not { } piece || seen.Contains(p)) continue;
            var group = BoardRuleEngine.GetGroup(board, p);
            foreach (var q in group) seen.Add(q);
            var libs = BoardRuleEngine.GetLiberties(board, group).Count;
            var hasCommander = group.Any(q => board[q]!.Value.Kind == PieceKind.Commander);
            var show = _play.Liberties == LibertyDisplay.All || libs <= 2 || hasCommander;
            if (!show) continue;

            // badge on the group's top-left-most stone
            var anchor = group.OrderBy(q => q.Y).ThenBy(q => q.X).First();
            var c = Center(anchor);
            var badge = new RectangleF(c.X + cell * 0.14f, c.Y - cell * 0.56f, cell * 0.36f, cell * 0.36f);
            var bad = libs == 1;
            var warn = libs == 2;
            using var back = new SolidBrush(Color.FromArgb(0xFF, 0xFF, 0xFF, 0xFF));
            using var pen = new Pen(bad ? Danger : warn ? Color.FromArgb(0xC2, 0x7A, 0x00) : Color.FromArgb(0x1D, 0x1B, 0x16), 1.8f);
            using var text = new SolidBrush(bad ? Danger : warn ? Color.FromArgb(0xC2, 0x7A, 0x00) : Color.FromArgb(0x1D, 0x1B, 0x16));
            g.FillEllipse(back, badge);
            g.DrawEllipse(pen, badge);
            DrawCentered(g, libs.ToString(), font, text, new PointF(badge.X + badge.Width / 2, badge.Y + badge.Height / 2));
        }
    }

    private void DrawSelection(Graphics g, GameState state, float r)
    {
        if (_play.Selected is not { } p) return;
        var c = Center(p);
        var legal = _play.Preview is not null;
        var color = legal ? Accent : Danger;

        if (legal)
        {
            var fill = state.Current == Player.One ? Black : White;
            using var ghost = new SolidBrush(Color.FromArgb(190, fill));
            g.FillEllipse(ghost, c.X - r, c.Y - r, r * 2, r * 2);

            // pieces this move would capture (taken from the previewed outcome, not recomputed here)
            using var dash = new Pen(Danger, 3f) { DashStyle = DashStyle.Dash };
            foreach (var captured in _play.Preview!.Events.OfType<PiecesCaptured>().SelectMany(x => x.Pieces))
            {
                var cc = Center(captured.At);
                g.DrawEllipse(dash, cc.X - r * 1.25f, cc.Y - r * 1.25f, r * 2.5f, r * 2.5f);
            }
        }

        using var pen = new Pen(color, 3f);
        g.DrawEllipse(pen, c.X - r * 1.1f, c.Y - r * 1.1f, r * 2.2f, r * 2.2f);
        if (!legal)
        {
            var k = r * 0.6f;
            g.DrawLine(pen, c.X - k, c.Y - k, c.X + k, c.Y + k);
            g.DrawLine(pen, c.X - k, c.Y + k, c.X + k, c.Y - k);
        }

        DrawCallout(g, c, r, color);
    }

    /// <summary>Text bubble next to the selected point, so the result of a click is visible without hovering.</summary>
    private void DrawCallout(Graphics g, PointF at, float r, Color color)
    {
        if (_play.Callout is not { } text) return;
        using var font = new Font("Microsoft JhengHei UI", Math.Max(13f, Cell * 0.27f), FontStyle.Bold, GraphicsUnit.Pixel);
        var size = g.MeasureString(text, font);
        var w = size.Width + 16;
        var h = size.Height + 8;
        var x = Math.Clamp(at.X - w / 2, 4, Math.Max(4, Width - w - 4));
        var y = PickCalloutY(at, r, x, w, h);
        var box = new RectangleF(x, y, w, h);
        using var path = RoundedRect(box, 8);
        using var back = new SolidBrush(color);
        using var fore = new SolidBrush(Color.White);
        g.FillPath(back, path);
        g.DrawString(text, font, fore, x + 8, y + 4);
    }

    /// <summary>First vertical placement for the bubble that stays on the board and does not cover any stone.</summary>
    private float PickCalloutY(PointF at, float r, float x, float w, float h)
    {
        float[] candidates = [at.Y - r * 1.6f - h, at.Y + r * 1.6f, at.Y - Cell * 1.7f - h, at.Y + Cell * 1.7f];
        foreach (var y in candidates)
        {
            if (y < 4 || y + h > Height - 4) continue;
            var box = new RectangleF(x, y, w, h);
            var covers = _play.State.Board.AllPoints().Any(p =>
                _play.State.Board[p] is not null &&
                box.IntersectsWith(new RectangleF(Center(p).X - r, Center(p).Y - r, r * 2, r * 2)));
            if (!covers) return y;
        }
        return candidates[0] >= 4 ? candidates[0] : candidates[1];
    }

    private static GraphicsPath RoundedRect(RectangleF r, float radius)
    {
        var d = radius * 2;
        var path = new GraphicsPath();
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    /// <summary>Circles the stones that explain a refused placement (e.g. the enemy stones that leave no liberty).</summary>
    private void DrawRelated(Graphics g, float r)
    {
        using var pen = new Pen(Danger, 3f) { DashStyle = DashStyle.Dash };
        foreach (var p in _play.RelatedPoints)
        {
            var c = Center(p);
            g.DrawEllipse(pen, c.X - r * 1.25f, c.Y - r * 1.25f, r * 2.5f, r * 2.5f);
        }
    }

    /// <summary>A commander with a single liberty is one move from capture: ring it and mark that last liberty.</summary>
    private void DrawCommanderDanger(Graphics g, float cell)
    {
        using var ring = new Pen(Danger, 4f);
        using var dot = new SolidBrush(Danger);
        using var font = new Font("Segoe UI", Math.Max(10f, cell * 0.3f), FontStyle.Bold, GraphicsUnit.Pixel);
        using var white = new SolidBrush(Color.White);
        foreach (var owner in new[] { Player.One, Player.Two })
        {
            var info = _play.Commander(owner);
            if (!info.InDanger) continue;
            foreach (var p in info.Group)
            {
                var c = Center(p);
                g.DrawEllipse(ring, c.X - cell * 0.5f, c.Y - cell * 0.5f, cell, cell);
            }
            foreach (var lib in info.LibertyPoints)
            {
                var c = Center(lib);
                g.FillEllipse(dot, c.X - cell * 0.2f, c.Y - cell * 0.2f, cell * 0.4f, cell * 0.4f);
                DrawCentered(g, "!", font, white, c);
            }
        }
    }

    private void DrawGameOver(Graphics g, GameState state)
    {
        using var shade = new SolidBrush(Color.FromArgb(150, 0, 0, 0));
        g.FillRectangle(shade, ClientRectangle);
        var text = state.Status == GameStatus.Won ? $"{EventText.Name(state.Winner!.Value)}獲勝" : "和局";
        using var font = new Font("Microsoft JhengHei UI", Math.Max(20f, Cell * 0.9f), FontStyle.Bold);
        using var brush = new SolidBrush(Color.White);
        DrawCentered(g, text, font, brush, new PointF(Width / 2f, Height / 2f));
    }

    private static void DrawCentered(Graphics g, string text, Font font, Brush brush, PointF center)
    {
        using var fmt = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(text, font, brush, center, fmt);
    }
}
