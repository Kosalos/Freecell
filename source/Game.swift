import UIKit

let SCREEN_YS = 1024
let NUM_COLUMNS = 8
let NUM_ROWS = 50
let SX = CGFloat(16)
let SY = CGFloat(200)
let BXS = CGFloat(cardXS+6)
let BYS = CGFloat(cardYS+1)
let NUM_HOLD = 4
let HOLDX = SX - CGFloat(2)
let HOLDY = CGFloat(40)
let ACEX = HOLDX + 20 + CGFloat(NUM_HOLD) * BXS
let ACEY = HOLDY - CGFloat(20)
let MAX_VERTICAL_SPACING = 50

var gd = GameData()
var move = Move()
var multiCardMove = MultiCardMove()

let animateOptions = UIView.AnimationOptions.curveLinear

var cardIndex = 0
var columnVerticalSpacing = [Int]()
var destinationColumn = 0
var select = BoardCell()
var touchPt:CGPoint = CGPoint.zero
var tapped:Bool = false

var showDebug = true

// MARK:
// MARK: Game

class Game {
    init() {
        for _ in 0 ..< NUM_COLUMNS {
            columnVerticalSpacing.append(0)
        }
    }
    
    // MARK:
    
    @objc func runTimedCode() {
        showDebug = true
        startMoving()
    }
    
    func newGame() {
        showDebug = false
        
        gd.emptyBoard()
        cards.shuffle()
        move.add(.COLLECT)
        move.add(.DEAL)
        startMoving()
        Timer.scheduledTimer(timeInterval:5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats:false)
    }
    
    // MARK:
    
    func dealCards() {
        var dealDelay:TimeInterval = 0
        let DEAL_DELAY:TimeInterval = 0.01
        
        gd.dealtCardIndex = NUM_CARDS-1
        showDebug = false
        
        // 6 full rows, 1 partial row of 4 columns
        for i in 0 ..< NUM_COLUMNS*6 + 4 {
            move.add(.ADD,false,0,0,(i % NUM_COLUMNS),gd.dealtCardIndex,dealDelay)
            gd.dealtCardIndex -= 1
            dealDelay += DEAL_DELAY
        }
        
        updateVerticalSpacingOfAllCards()
    }
    
    func collectCards() {
        UIView.animate(withDuration: 0.5, delay:0, options: animateOptions, animations:  {
            for i in 0 ..< NUM_CARDS {
                cards.setFaceUp(i, faceUp:false)
                cards.setPosition(i, dealPosition)
                cards.setZ(i, i)
            }
        }, completion: { (complete: Bool) in self.startMoving() })
    }
    
    // MARK:
    
    func dropCardOnColumn(_ index:Int, _ column:Int, _ delay:TimeInterval, _ launchNextMove:Bool) {
        
        //  print("add card Index:",cardIndex,", C:",column,", D:",delay,", W:",wait)
        
        let row = gd.firstEmptyRow(column)
        if row == EMPTY { return }
        
        gd.board[column][row].index = index
        cards.setZ(index, row)
        
        UIView.animate(withDuration: 0.3, delay: delay, options: animateOptions, animations: {
            cards.setPosition(index, gd.board[column][row].position)
            cards.setFaceUp(index, faceUp:true)
        }, completion: { (complete: Bool) in if launchNextMove { self.startMoving() } })
    }
    
    func dropCardsOnColumn(_ src:BoardCell, _ destColumn:Int) {
        // source was ROW_HOLD?
        if src.r == ROW_HOLD {
            dropCardOnColumn(gd.hold[src.c], destColumn,0,true)
            gd.hold[src.c] = EMPTY
            return
        }
        
        var src = src
        var delay:TimeInterval = 0
        var count = gd.numberCardsInSelection(src)
        
        while(true) {
            if src.r >= NUM_ROWS {  break }
            
            cardIndex = gd.getBoardIndex(src)
            if cardIndex == EMPTY { break }
            
            count -= 1
            dropCardOnColumn(cardIndex, destColumn, delay, count == 0)
            
            gd.set(src,EMPTY)
            src.r += 1
            delay += 0.1
        }}
    
    // MARK:
    
    func dropCardOnHold(_ src:BoardCell, _ holdColumn:Int) {
        if src.r == EMPTY { return }
        
        if(src.r == ROW_HOLD) {
            cardIndex = gd.hold[src.c]
            gd.hold[src.c] = EMPTY
        }
        else {
            cardIndex = gd.getBoardIndex(src)
            gd.set(src,EMPTY)
        }
        
        gd.hold[holdColumn] = cardIndex
        
        UIView.animate(withDuration: 0.3, delay:0, options: animateOptions, animations: {
            cards.setPosition(cardIndex, CGPoint(x:HOLDX + CGFloat(holdColumn) * BXS, y:HOLDY))
        }, completion: { (complete: Bool) in self.startMoving() })
        
        cards.setZ(cardIndex,0)
    }
    
    func moveCardToAce(_ src:BoardCell) {
        if src.r == EMPTY { return }
        
        if src.r == ROW_HOLD {
            cardIndex = gd.hold[src.c]
            gd.hold[src.c] = EMPTY
        }
        else {
            cardIndex = gd.getBoardIndex(src)
            gd.set(src,EMPTY)
        }
        
        let card = cards.card(cardIndex)
        let pos = CGPoint(x:ACEX + CGFloat(card.suit) * BXS, y:ACEY)
        
        cards.setZ(cardIndex,card.rank+300)
        
        UIView.animate(withDuration: 0.15, delay:0, options: animateOptions, animations: {
            cards.setPosition(cardIndex, pos)
        }, completion: { (complete: Bool) in
            gd.addToAce(card)
            self.startMoving()
        }
        )
    }
    
    func checkAutoMoveToAce() {
        for i in 0 ..< NUM_SUIT {
            if gd.hold[i] != EMPTY {
                let card = cards.card(gd.hold[i])
                if gd.canMoveToAce(card) {
                    move.add(.ACE_DROP,true,i,ROW_HOLD,0)
                    startMoving()
                    return
                }}}
        
        for c in 0 ..< NUM_COLUMNS {
            let row = gd.rowOfBottomMostCardInColumn(c)
            if row >= NUM_ROWS-1 { continue }
            let index = gd.getBoardIndex(c,row)
            
            if index != EMPTY {
                let card = cards.card(index)
                if gd.canMoveToAce(card) {
                    move.add(.ACE_DROP,true,c,row,0)
                    startMoving()
                    return
                }}}
    }
    
    // MARK:
    
    func updatePositionOfSelectedCards(_ dx:CGFloat, _ dy:CGFloat) {
        if select.r == ROW_HOLD {
            if cardIndex != EMPTY {
                cards.setDeltaPosition(cardIndex, dx, dy)
            }
        }
        else {
            var selectRow = select
            while(true) {
                if selectRow.r >= NUM_ROWS { return }
                cardIndex = gd.getBoardIndex(selectRow)
                if cardIndex == EMPTY { break }
                
                cards.setDeltaPosition(cardIndex, dx, dy)
                selectRow.r += 1
            }}
    }
    
    func sendMovingCardsBackHome() {
        var selectRow = select
        
        if selectRow.r == ROW_HOLD {  // came from Hold
            cardIndex = gd.hold[selectRow.c]
            if cardIndex == EMPTY { return }
            let pos = CGPoint(x:HOLDX + CGFloat(selectRow.c) * BXS, y:HOLDY)
            
            UIView.animate(withDuration: 0.3, delay:0, options: animateOptions, animations: {
                cards.setPosition(cardIndex, pos)
            }, completion: { (complete: Bool) in
                self.startMoving()
            }
            )
            return
        }
        
        while(true) {
            if(selectRow.r >= NUM_ROWS) { return }
            cardIndex = gd.getBoardIndex(selectRow)
            if(cardIndex == EMPTY) { return }
            
            cards.goBackHome(cardIndex)
            selectRow.r += 1
        }
    }
    
    func updateVerticalSpacingOfAllCards() {
        for column in 0 ..< NUM_COLUMNS {
            let row = gd.rowOfBottomMostCardInColumn(column)
            
            if(row == 0) {
                columnVerticalSpacing[column] = MAX_VERTICAL_SPACING;
            }
            else {
                columnVerticalSpacing[column] = ((SCREEN_YS - Int(SY)) - Int(cardYS) - 70)/row
                if columnVerticalSpacing[column] > MAX_VERTICAL_SPACING { columnVerticalSpacing[column] = MAX_VERTICAL_SPACING }
            }
            
            for y:Int in 0 ..< NUM_ROWS {
                gd.board[column][y].position.y = SY + CGFloat(y * columnVerticalSpacing[column])
            }}
        
        // command all cards to move to updated positions, and adjust Z coords
        UIView.animate(withDuration: 0.3, delay: 0, options: animateOptions,  animations: {
            for c in 0 ..< NUM_COLUMNS {
                for r in 0 ..< NUM_ROWS {
                    cardIndex = gd.getBoardIndex(c,r)
                    if cardIndex == EMPTY { break }
                    
                    cards.setPosition(cardIndex, gd.board[c][r].position)
                    cards.setZ(cardIndex,r)
                }
            }
        }, completion: { (complete: Bool) in self.startMoving() })
    }
    
    // MARK:
    
    func startMoving() {
        let currentMove = move.nextMove()
        
        switch currentMove.command {
        case .COLLECT :
            collectCards()
            break
        case .DEAL :
            dealCards()
            break
        case .ADD :
            dropCardOnColumn(currentMove.index, currentMove.destColumn, currentMove.delay, false)
            if !currentMove.wait { startMoving() }
            return
        case .MOVE :
            dropCardsOnColumn(currentMove.src,currentMove.destColumn)
            break
        case .HOLD_DROP :
            dropCardOnHold(currentMove.src,currentMove.destColumn)
            break
        case .ACE_DROP :
            moveCardToAce(currentMove.src)
            break
        case .SEND_BACK :
            sendMovingCardsBackHome()
            break
        case .UPDATE_VERTICAL_SPACING :
            updateVerticalSpacingOfAllCards()
            break
        case .NONE :
            checkAutoMoveToAce()
            gd.debug()
            break
        }}
    
    // MARK:
    
    func holdTouch(_  pt:CGPoint) -> Int { // index of ROW_HOLD spot, or EMPTY
        var rect = CGRect(x:CGFloat(0), y:HOLDY, width:BXS, height:BYS)
        
        for c:Int in 0 ..< NUM_HOLD {
            rect.origin.x = HOLDX + CGFloat(c) * BXS
            if rect.contains(pt) { return c }
        }
        return EMPTY
    }
    
    func aceTouch(_  pt:CGPoint) -> Bool { // is pt in ace region?
        let rect = CGRect(x:ACEX, y:ACEY, width:BXS * 4.0, height:BYS)
        return rect.contains(pt)
    }
    
    var touchBeganPoint = CGPoint.zero
    
    func touchesBegan(_ pt:CGPoint) {
        let hIndex = holdTouch(pt)
        if hIndex != EMPTY {
            cardIndex = gd.hold[hIndex]
            cards.setZ(cardIndex,200)
            touchBeganPoint = pt
            select.c = hIndex
            select.r = ROW_HOLD
            return
        }
        
        // set touchX,Y to board index of selected card(s)
        select.c = EMPTY // assume nothing selected
        var rect = CGRect(x:CGFloat(0), y:CGFloat(0), width:BXS, height:CGFloat(0))
        
        for c in 0 ..< NUM_COLUMNS {
            rect.size.height = CGFloat(columnVerticalSpacing[c])
            
            for r in 0 ..< NUM_ROWS {
                if gd.getBoardIndex(c,r) == EMPTY { break }
                
                rect.origin = gd.board[c][r].position;
                
                // bottommost card has larger target area
                if gd.getBoardIndex(c,r+1) == EMPTY { rect.size.height = BYS }
                
                if rect.contains(pt) {
                    let pos = BoardCell(c,r)
                    if gd.isLegalToMoveThisCard(pos) {
                        touchBeganPoint = pt
                        select = pos
                        tapped = true
                    }
                    
                    return
                }}}
    }
    
    func touchesMoved(_ pt:CGPoint) {
        if select.c == EMPTY { return }
        if (abs(pt.x-touchBeganPoint.x) + abs(pt.y-touchBeganPoint.y)) > 10.0 {
            let dx = pt.x - touchBeganPoint.x
            let dy = pt.y - touchBeganPoint.y
            touchPt = pt
            
            if select.r == ROW_HOLD {  // from ROW_HOLD
                updatePositionOfSelectedCards(dx,dy)
            }
            else {
                // set moving cards higher Z than all board cards
                var r = select.r
                while(true) {
                    cardIndex = gd.getBoardIndex(select.c,r)
                    if cardIndex == EMPTY { break }
                    
                    cards.setZ(cardIndex,200+r)
                    r += 1
                }
                
                updatePositionOfSelectedCards(dx,dy)
            }}
    }
    
    func touchesEnded() {
        if select.c == EMPTY { return }
        
        let hIndex = holdTouch(touchPt) // drop to ROW_HOLD?
        if hIndex != EMPTY {
            if gd.hold[hIndex] == EMPTY {
                move.add(.HOLD_DROP,true,select.c,select.r,hIndex)
                move.add(.UPDATE_VERTICAL_SPACING)
            }
            else {
                move.add(.SEND_BACK)
            }
            startMoving()
            select.c = EMPTY
            return
        }
        
        if aceTouch(touchPt) { // drop to ROW_ACE?
            if select.r == ROW_ACE {
                move.add(.SEND_BACK)
                startMoving()
                select.c = EMPTY
                return
            }
            
            var card = CardData()
            if select.r == ROW_HOLD {
                card = cards.card(gd.hold[select.c])
            }
            else {
                card = cards.card(gd.getBoardIndex(select)) // top of moving group
            }
            
            if gd.canMoveToAce(card) {
                move.add(.ACE_DROP,true,select.c,select.r,hIndex)
                move.add(.UPDATE_VERTICAL_SPACING)
            }
            else {
                move.add(.SEND_BACK)
            }
            startMoving()
            select.c = EMPTY
            return
        }
        
        let count = gd.numberCardsInSelection(select)
        destinationColumn = Int((touchPt.x) / BXS)
        
        if count == 1 {
            if gd.isLegalToDropSelectionOnThisColumn(destinationColumn) {
                move.add(.MOVE,true,select.c,select.r,destinationColumn)
                move.add(.UPDATE_VERTICAL_SPACING)
            }
            else {
                move.add(.SEND_BACK)
            }
            
            startMoving()
            select.c = EMPTY
            return
        }
        
        multiCardMove.attempt(count)
    }
    
    func abortMultiCardMove() {
        move.add(.SEND_BACK)
        startMoving()
        select.c = EMPTY
    }
    
    // MARK:
    
    func draw() {
        let y1 = HOLDY
        let y2 = y1 + BYS
        let y3 = ACEY
        let y4 = y3 + BYS
        
        UIColor.white.setStroke()
        
        for i in 0 ..< NUM_HOLD {
            let x1 = HOLDX + CGFloat(i) * BXS
            let x2 = x1 + cardXS
            g.drawRectangle(x1,y1,x2,y2)
        }
        for i in 0 ..< NUM_SUIT {
            let x3 = ACEX + CGFloat(i) * BXS
            let x4 = x3 + cardXS
            g.drawRectangle(x3,y3,x4,y4)
        }
    }
}
