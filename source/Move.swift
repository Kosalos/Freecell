import UIKit

let MAX_MOVES = 100

enum MOVE_COMMAND {
    case NONE,COLLECT,DEAL,ADD,MOVE,HOLD_DROP,ACE_DROP,SEND_BACK,UPDATE_VERTICAL_SPACING
}

struct MoveData {
    var command:MOVE_COMMAND = .MOVE
    var wait = false
    var src = BoardCell()
    var destColumn = Int()
    var index = Int()
    var delay = TimeInterval()
}

var moveHead = 0
var moveTail = 0
var moveData = Array<MoveData>()

class Move {
    init() {
        for _ in 0 ..< MAX_MOVES { moveData.append(MoveData()) }
    }

    func reset() {
        moveHead = 0
        moveTail = 0
        for i in 0 ..< MAX_MOVES {
            moveData[i].command = .NONE
        }
    }
    
    func advanceIndex( _ index:Int) -> Int {
        var v = index + 1
        if v >= MAX_MOVES { v = 0 }
        return v
    }
    
    func add(_ command:MOVE_COMMAND, _ wait:Bool = true, _ srcC:Int = 0, _ srcR:Int = 0, _ destC:Int = 0, _ cardIndex:Int = 0, _ delay:TimeInterval = 0) {
        moveHead = advanceIndex(moveHead)
        if moveHead == moveTail {
            print("move storage too small")
            return
        }
        
        func mInit( _ m:inout MoveData) {
            m.command = command
            m.wait = wait
            m.src.c = srcC
            m.src.r = srcR
            m.destColumn = destC
            m.index = cardIndex
            m.delay = delay
        }
        
        mInit(&moveData[moveHead])
        moveDebug()
    }
    
    func nextMove() -> MoveData {
        if moveTail != moveHead {
            moveTail = advanceIndex(moveTail)
            return moveData[moveTail]
        }
        
        var noMove = MoveData()
        noMove.command = .NONE
        return noMove
    }
    
    func moveDebug(){
        print("Move H",moveHead,", T",moveTail," = ",
              moveData[moveHead].command," Src: ",
              moveData[moveHead].src.c,",", moveData[moveHead].src.r,
              " Dest ",
              moveData[moveHead].destColumn)
    }
}
