# R2 固定局面

符號：x 黑士兵，X 黑主將，H 黑英雄；o 白士兵，O 白主將；. 空點。均為黑方行動、2 AP、4 Mana；職業與目的見每列。棋串採正交連通。候選 B／D 的所有戰士目標取自施放前棋串。

## warrior-rear-frontier

英雄四鄰已滿，但原棋串連到前線。職業：Warrior；焦點：B3、D3。

```text
  ABCDEFG
1 ooO.oo.
2 o...oo.
3 ..x..o.
4 .xxx...
5 .xHx...
6 .xxx...
7 ..X....
```

焦點結果：A OutOfRange；B None；C OutOfRange；D None。

## warrior-disconnected

遠方己方棋群沒有連到英雄。職業：Warrior；焦點：D2、E2。

```text
  ABCDEFG
1 ..O....
2 .......
3 ...xx..
4 .......
5 .xHx...
6 .xxx...
7 ..X....
```

焦點結果：A OutOfRange；B OutOfRange；C OutOfRange；D OutOfRange。

## warrior-no-new-bridge

第一子能接上遠方棋群，第二子仍不得借新連線。職業：Warrior；焦點：D4、E4。

```text
  ABCDEFG
1 ..O....
2 .......
3 ...xx..
4 .......
5 .xHx...
6 .xxx...
7 ..X....
```

焦點結果：A OutOfRange；B OutOfRange；C OutOfRange；D OutOfRange。

## warrior-remote-commander-threat

連線前線能直接提主將；對手可先補關鍵氣。職業：Warrior；焦點：C2、D3。

```text
  ABCDEFG
1 .xOx...
2 .......
3 ..x....
4 ..x....
5 .xHx...
6 .xxx...
7 ..X....
```

焦點結果：A OutOfRange；B None／黑方勝；C OutOfRange；D None／黑方勝。

## warrior-two-liberty-tempo

兩個遠方氣可用一個技能同時填完，普通落子需兩個AP。職業：Warrior；焦點：C2、E2。

```text
  ABCDEFG
1 ...x...
2 ...O...
3 ..xxx..
4 ..xxx..
5 ..xHx..
6 ..xxx..
7 ...X...
```

焦點結果：A OutOfRange；B None／黑方勝；C OutOfRange；D None／黑方勝。

## warrior-one-liberty

英雄孤立且只有一氣，不能保證技能一定可用。職業：Warrior；焦點：D5、D6。

```text
  ABCDEFG
1 ..O....
2 .......
3 ...o...
4 ..oHo..
5 .......
6 .......
7 ...X...
```

焦點結果：A OutOfRange；B OutOfRange；C OutOfRange；D OutOfRange。

## mage-dense-front

射程內每顆士兵四鄰皆占據，只有異色交換能動棋。職業：Mage；焦點：D3 Left。

```text
  ABCDEFG
1 ...O...
2 .xxxoo.
3 .xxooo.
4 xxxHooo
5 .xxxoo.
6 .xxxoo.
7 ...X...
```

焦點結果：A Occupied；B Occupied；C None；D None。

## mage-remote-cut-win

距離二的異色交換可切斷主將棋串，盜賊在同位置碰不到敵兵。職業：Mage；焦點：D3 Up。

```text
  ABCDEFG
1 .......
2 ...xx..
3 .HxoOx.
4 ...ox..
5 .......
6 .......
7 ..X....
```

焦點結果：A Occupied；B Occupied；C None／黑方勝；D None／黑方勝。
