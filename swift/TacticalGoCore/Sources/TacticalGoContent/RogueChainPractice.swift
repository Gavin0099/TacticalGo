import TacticalGoCore

/// One archived normal-game position, replayed with its full superko history.
/// Source: PR #37 2399cbc, P0 b9-Priest-Rogue turn 59 / ply 60,
/// P1R alternative #5. This demonstrates a current-turn trade, not a promised win.
public enum RogueChainPractice {
    public static let title = "盜賊 · 兩手連鎖"
    public static let instruction = "先落兵 F3，再用連鎖換位選 D3、C3。比較提子、能量與主帥的氣；也可以自由改走法。"
    public static let firstAction: GameAction = .placeSoldier(Point(5,2))
    public static let secondAction: GameAction = .castChainSwap(first:Point(3,2),second:Point(2,2))

    public static func session() throws -> GameSession {
        var session = GameSession(try GameSetup.newGame(
            config:TacticalHints.updatedConfig(size:9,advancedCost:4),classOne:.priest,classTwo:.rogue))
        for action in opening {
            guard session.apply(action).success else { throw ExpansionPracticeError.illegalOpening }
        }
        let state = session.state
        guard state.ply == 60, state.current == .two, state.apRemaining == 2,
              state.mana(of:.one) == 6, state.mana(of:.two) == 6,
              !state.skillUsedThisTurn, state.status == .ongoing,
              state.board.diagram == """
oo.oooooo
o.ooOooo.
ooxxQ.o.o
xoxooooo.
xxxxxoxoo
xx.xxx.xo
x.x.H.x.x
.x.xXx.x.
x.xxxxxxx
""" else { throw ExpansionPracticeError.illegalOpening }
        return session
    }

    private static let opening: [GameAction] = [
        .summonHero(Point(4,6)),
        .placeSoldier(Point(4,5)),
        .summonHero(Point(4,2)),
        .placeSoldier(Point(3,2)),
        .placeSoldier(Point(5,2)),
        .placeSoldier(Point(4,3)),
        .placeSoldier(Point(3,6)),
        .placeSoldier(Point(4,4)),
        .placeSoldier(Point(3,5)),
        .placeSoldier(Point(5,6)),
        .placeSoldier(Point(4,8)),
        .placeSoldier(Point(5,5)),
        .placeSoldier(Point(4,5)),
        .placeSoldier(Point(2,5)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(3,7)),
        .placeSoldier(Point(5,7)),
        .placeSoldier(Point(2,7)),
        .placeSoldier(Point(6,7)),
        .placeSoldier(Point(2,6)),
        .placeSoldier(Point(6,6)),
        .placeSoldier(Point(1,6)),
        .placeSoldier(Point(7,6)),
        .placeSoldier(Point(2,4)),
        .placeSoldier(Point(1,5)),
        .placeSoldier(Point(3,1)),
        .placeSoldier(Point(3,3)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(1,7)),
        .placeSoldier(Point(0,7)),
        .placeSoldier(Point(1,8)),
        .placeSoldier(Point(7,5)),
        .placeSoldier(Point(7,7)),
        .placeSoldier(Point(8,7)),
        .placeSoldier(Point(7,8)),
        .placeSoldier(Point(2,2)),
        .placeSoldier(Point(3,8)),
        .placeSoldier(Point(1,2)),
        .placeSoldier(Point(2,1)),
        .placeSoldier(Point(2,3)),
        .placeSoldier(Point(2,8)),
        .placeSoldier(Point(6,2)),
        .placeSoldier(Point(5,3)),
        .placeSoldier(Point(1,7)),
        .placeSoldier(Point(0,6)),
        .placeSoldier(Point(0,5)),
        .placeSoldier(Point(1,6)),
        .placeSoldier(Point(0,8)),
        .placeSoldier(Point(0,6)),
        .placeSoldier(Point(5,1)),
        .placeSoldier(Point(0,4)),
        .placeSoldier(Point(1,1)),
        .placeSoldier(Point(0,3)),
        .placeSoldier(Point(0,2)),
        .placeSoldier(Point(1,3)),
        .placeSoldier(Point(1,4)),
        .placeSoldier(Point(0,1)),
        .placeSoldier(Point(0,0)),
        .placeSoldier(Point(1,0)),
        .placeSoldier(Point(4,0)),
        .placeSoldier(Point(6,1)),
        .placeSoldier(Point(5,0)),
        .placeSoldier(Point(7,1)),
        .placeSoldier(Point(7,2)),
        .placeSoldier(Point(6,3)),
        .placeSoldier(Point(8,2)),
        .placeSoldier(Point(7,3)),
        .placeSoldier(Point(6,8)),
        .placeSoldier(Point(7,7)),
        .placeSoldier(Point(8,4)),
        .placeSoldier(Point(6,7)),
        .placeSoldier(Point(8,6)),
        .placeSoldier(Point(7,7)),
        .placeSoldier(Point(8,5)),
        .placeSoldier(Point(7,6)),
        .placeSoldier(Point(8,8)),
        .placeSoldier(Point(8,6)),
        .placeSoldier(Point(5,4)),
        .placeSoldier(Point(7,4)),
        .placeSoldier(Point(2,0)),
        .placeSoldier(Point(1,1)),
        .placeSoldier(Point(3,0)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(0,3)),
        .placeSoldier(Point(0,1)),
        .placeSoldier(Point(0,2)),
        .placeSoldier(Point(1,2)),
        .placeSoldier(Point(3,4)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(1,3)),
        .placeSoldier(Point(0,4)),
        .placeSoldier(Point(6,0)),
        .placeSoldier(Point(0,5)),
        .placeSoldier(Point(7,0)),
        .placeSoldier(Point(6,3)),
        .placeSoldier(Point(1,1)),
        .placeSoldier(Point(0,3)),
        .placeSoldier(Point(0,1)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(0,4)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(8,0)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(6,1)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(4,0)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(5,8)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(6,0)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(4,8)),
        .placeSoldier(Point(6,4)),
        .placeSoldier(Point(6,1)),
        .placeSoldier(Point(6,5)),
        .placeSoldier(Point(7,8)),
        .placeSoldier(Point(6,4)),
    ]
}
