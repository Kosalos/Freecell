import UIKit

struct ProposedMoveData {
    var src = BoardCell()
    var dest = BoardCell()
    var index = Int()
}

let MAX_PROPOSED_MOVES = 100

var pCount = 0
var pm = Array<ProposedMoveData>()
var gd2 = GameData()

class MultiCardMove {

    init() { for _ in 0 ..< MAX_PROPOSED_MOVES { pm.append(ProposedMoveData()) }}
    
    func attempt(_ count:Int) {
        if gd.groupCount < 2 {
            game.abortMultiCardMove()
            return
        }
        
        gd2 = gd
        
        //let n = destinationColumn as NSNumber
        //print("MultiCardMove. Dest C = " + n.stringValue)
        //gd2.debug()
        gd2.debugGroup()
        
        move.reset()
        pCount = 0
        var groupOkay = true
        
        for i in 0 ..< gd2.groupCount-1 {  // not include topmost
            let gIndex = gd2.groupCount - i - 1
            var okay = false
            
            pm[pCount].index = gd2.group[gIndex]
            pm[pCount].src.c = select.c
            pm[pCount].src.r = select.r + gIndex
            
            for c in 0 ..< NUM_COLUMNS {
                if gIndex > 0 && c == destinationColumn { continue } // only topmost of group can move to target immediately
                if gd2.isLegalToDropCardOnThisColumn(gd2.group[gIndex],c) {
                    pm[pCount].dest.c = c
                    
                    let row = gd2.firstEmptyRow(c)
                    pm[pCount].dest.r = row
                    gd2.board[c][row].index = gd2.group[gIndex]
                    pCount += 1
                    okay = true
                    break
                }
            }
            
            if !okay {
                for c in 0 ..< NUM_HOLD {
                    if gd2.hold[c] == EMPTY {
                        pm[pCount].dest.c = c
                        pm[pCount].dest.r = ROW_HOLD
                        pCount += 1
                        gd2.hold[c] = gd2.group[gIndex]
                        okay = true
                        break
                    }
                }
            }
            
            if !okay {
                groupOkay = false
                break
            }
        }

        if groupOkay {  // top card of group
            if !gd2.isLegalToDropCardOnThisColumn(gd2.group[0],destinationColumn) {
                groupOkay = false
            }
            pm[pCount].index = gd2.group[0]
            pm[pCount].src.c = select.c
            pm[pCount].src.r = select.r
            pm[pCount].dest.c = destinationColumn
            pm[pCount].dest.r = gd2.firstEmptyRow(destinationColumn)
            pCount += 1
        }
        
        debugProposedMoveData()
        
        if groupOkay {
            // last pm[] is top of selection to target
            for i in 0 ..< pCount {
                let cmd:MOVE_COMMAND = (pm[i].dest.r == ROW_HOLD) ? .HOLD_DROP : .MOVE
                move.add(cmd,true,pm[i].src.c,pm[i].src.r,pm[i].dest.c,pm[i].index)
            }
            
            // walk backwards from pCount-1 to 0 to move from Temp to target
            let destC = pm[pCount-1].dest.c
            
            for i in 1 ..< pCount {
                let index = pCount - i - 1
                move.add(.MOVE,true,pm[index].dest.c,pm[index].dest.r,destC,pm[index].index)
            }
            
            game.startMoving()
        }
        else {
            game.abortMultiCardMove()
        }
    }
    
    func debugProposedMoveData() {
        print("Proposed moves ----------------------------")
        
        for i in 0 ..< pCount {
            print(i,":  Src:",pm[i].src.c,",",pm[i].src.r," Dest:",pm[i].dest.c,",",pm[i].dest.r," Card:",cards.name(pm[i].index))
        }
    }
}
