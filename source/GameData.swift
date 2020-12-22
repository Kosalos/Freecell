import UIKit

let MAX_GROUP = 20
let RANK_ACE = 0
let EMPTY = -1
let ROW_HOLD = -2
let ROW_ACE = -3

var debugLine = 0

struct BoardCell {
    var c = Int()   // column
    var r = Int()   // row
    
    init(_ nc:Int = EMPTY, _ nr:Int = EMPTY) { c = nc; r = nr }
    mutating func set(_ nc:Int, _ nr:Int) { c = nc; r = nr }
}

struct BoardPosition {
    var position = CGPoint()
    var index = 0
}

struct GameData {
    var board = Array<Array<BoardPosition>>()
    var group = Array<Int>()
    var groupCount = Int()
    var hold = [ EMPTY,EMPTY,EMPTY,EMPTY ]
    var ace = [ EMPTY,EMPTY,EMPTY,EMPTY ]
    var dealtCardIndex = Int()
    
    init() {
        for _ in 0 ..< NUM_COLUMNS {
            board.append(Array(repeating: BoardPosition(), count: NUM_ROWS))
        }
        
        for _ in 0 ..< MAX_GROUP { group.append(Int()) }
    }
    
    func getBoardIndex(_ pos:BoardCell) -> Int {
        if pos.c < 0 || pos.r < 0 { return EMPTY }
        return board[pos.c][pos.r].index
    }
    
    func getBoardIndex(_ c:Int, _ r:Int) -> Int {
        if c < 0 || r < 0 { return EMPTY }
        return board[c][r].index
    }
    
    mutating func set(_ pos:BoardCell, _ value:Int) { board[pos.c][pos.r].index = value }
    mutating func set(_ c:Int, _ r:Int, _ value:Int) { board[c][r].index = value }
    
    mutating func emptyBoard() {
        for c in 0 ..< NUM_COLUMNS {
            for r in 0 ..< NUM_ROWS {
                board[c][r].index = EMPTY
                board[c][r].position.x = SX + CGFloat(c) * BXS
                board[c][r].position.y = SY + CGFloat(r) * CGFloat(MAX_VERTICAL_SPACING)
            }
        }
        
        for c in 0 ..< 4 {
            hold[c] = EMPTY
            ace[c] = EMPTY
        }
    }
    
    func canMoveToAce(_ card:CardData) -> Bool {
        if card.rank == RANK_ACE { return true }
        if card.rank == ace[card.suit]+1 { return true }  // moving next card in series
        return false
    }
    
    mutating func addToAce(_ card:CardData) {
        ace[card.suit] = card.rank
    }
    
    mutating func removeFromAce(_ card:CardData) {
        ace[card.suit] = card.rank-1
    }
    
    func firstEmptyRow(_ column:Int) -> Int {
        for r in 0 ..< NUM_ROWS {
            if board[column][r].index == EMPTY { return r }
        }
        
        return EMPTY
    }
    
    func rowOfBottomMostCardInColumn(_ column:Int) -> Int {
        for row in 0 ..< NUM_ROWS-1 {
            if board[column][row+1].index == EMPTY { return row }
        }
        
        return NUM_ROWS-1
    }
    
    // MARK:
    // last card, or top of group
    
    func isLegalToMoveThisCard(_ pos:BoardCell) -> Bool {
        if pos.r == NUM_ROWS-1 { return false }
        
        var row = pos.r
        var topCardOfGroup = cards.card(board[pos.c][row].index)
        
        // if there are cards below the selected one they must descend rank in alternating colors
        while(true) {
            row += 1
            if row == NUM_ROWS { return true }
            if board[pos.c][row].index == EMPTY { return true } // reached bottom end of group
            
            let card = cards.card(board[pos.c][row].index)
            if card.isSameColorAs(topCardOfGroup) { return false }
            if card.rank != topCardOfGroup.rank-1 { return false }
            
            topCardOfGroup = card
        }
    }
    
    // current bottommost card of destination column must be rank+1 (or empty column)

    func isLegalToDropCardOnThisColumn(_ index:Int, _ column:Int) -> Bool {
        if index == EMPTY { return false }
        if board[column][0].index == EMPTY { return true }  // empty column
        
        let row = rowOfBottomMostCardInColumn(column)
        if row >= NUM_ROWS-1 { return false } // filled column
        
        let card1 = cards.card(index)
        let card2 = cards.card(board[column][row].index) // bottom of destination column
        
        if card1.isSameColorAs(card2) { return false }
        if card2.rank != card1.rank + 1 { return false }
        return true
    }

    func isLegalToDropSelectionOnThisColumn(_ column:Int) -> Bool {
        if board[column][0].index == EMPTY { return true }  // empty column
        
        var index = 0
        
        if select.r == ROW_HOLD {
            index = hold[select.c]
        }
        else if select.r == ROW_ACE {
            index = cards.findIndex(ace[select.c],select.c)
        }
        else {
            index = getBoardIndex(select) // top of moving group
        }
        
        return isLegalToDropCardOnThisColumn(index,column)
    }
    
    mutating func numberCardsInSelection(_ pos:BoardCell) -> Int {
        if pos.r == ROW_HOLD || pos.r == ROW_ACE { return 1 }
        
        var pos = pos
        groupCount = 0
        
        while(true) {
            if pos.r >= NUM_ROWS || pos.r <= EMPTY {  break }
            
            let index = getBoardIndex(pos)
            if index == EMPTY { break }
            
            group[groupCount] = index
            groupCount += 1
            pos.r += 1
        }
        
        return groupCount
    }
    
    mutating func dropCardOnColumn(_ index:Int, _ column:Int) {
        let row = firstEmptyRow(column)
        if row != EMPTY {
            set(column,row,index)
            cards.setZ(index, row)
        }
    }
    
    mutating func dropCardOnHold(_ src:BoardCell, _ holdColumn:Int) {
        if src.r == EMPTY { return }
        
        if(src.r == ROW_HOLD) {
            cardIndex = gd.hold[src.c]
            hold[src.c] = EMPTY
        }
        else {
            cardIndex = gd.getBoardIndex(src)
            set(src,EMPTY)
        }
        
        hold[holdColumn] = cardIndex
    }
    
    // MARK:
    
    func debugEntry(_ index:Int) {
        print(cards.name(index)," ", separator:"", terminator:"")
    }
    
    mutating func debug() {
        if !showDebug { return }
        
        print(" ")
        print(debugLine," --------------------------------------")
        debugLine += 1
        
        for i in 0 ..< 4 { debugEntry(hold[i]) }
        print("  ", terminator:"")
        
        for i in 0 ..< 4 {
            if ace[i] == EMPTY {
                print("--- ", terminator:"")
            }
            else {
                print(rankStr[ace[i]],suitStr[i]," ", separator:"", terminator:"")
            }
        }
        print(" ")
        
        for r in 0 ..< 12 {
            for c in 0 ..< NUM_COLUMNS {
                debugEntry(board[c][r].index)
            }
            print(" ")
        }
    }
    
    mutating func debugGroup() {
        if !showDebug { return }
        
        print(" ")
        print(debugLine," Group -------------------------------------")
        debugLine += 1
        
        print("Select = ",select.c,",",select.r,"  count:",groupCount)
        
        for i in 0 ..< groupCount {
            print(i,":  ", terminator:"")
            debugEntry(group[i])
            print(" ")
        }
        
        print(" ")
    }

}

