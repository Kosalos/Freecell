import UIKit

let NUM_RANK = 13
let NUM_SUIT = 4
let NUM_CARDS = NUM_SUIT * NUM_RANK

let rankStr = [ " A"," 2"," 3"," 4"," 5"," 6"," 7"," 8"," 9","10"," J"," Q"," K" ]
let suitStr = [ "C","H","S","D", ]  // [ "♣︎","♥︎","♠︎","♦︎", ]

struct CardData {
    var view:UIImageView
    var suit:Int
    var rank:Int
    var picIndex :Int
    var homePosition:CGPoint
    
    init() {
        view = UIImageView()
        suit = 0
        rank = 0
        picIndex = 0
        homePosition = CGPoint.zero
    }
    
    func isBlack() -> Bool { return suit == 1 || suit == 3 }
    func isRed() -> Bool { return suit == 0 || suit == 2 }
    
    func isSameColorAs( _ other:CardData) -> Bool {
        if isBlack() && other.isBlack() { return true }
        if isRed() && other.isRed() { return true }
        return false
    }
}

class Cards {
    var backFace = UIImage()
    var cardPicture = [UIImage]()
    var cardData = [CardData]()
    
    func initialize(_ parentView:UIView) {
        backFace = UIImage(named: "cardback.png")!
        let deck = UIImage(named: "cardFaces.png")
        
        // load all card faces into cardPicture[] -------------------
        let sx:CGFloat = 15
        let sy:CGFloat = 9
        let xs:CGFloat = 374
        let ys:CGFloat = 522
        let xh:CGFloat = 65
        let yh:CGFloat = 65
        
        for s in 0 ..< NUM_SUIT {
            for r in 0 ..< NUM_RANK {
                let x = sx + CGFloat(r) * (xs + xh)
                let y = sy + CGFloat(s) * (ys + yh)
                let rect = CGRect(x: x,y: y,width: xs,height: ys)
                let cardFace = deck!.cgImage!.cropping(to: rect)
                
                cardPicture.append(UIImage(cgImage: cardFace!))
            }
        }
        
        // create UIImageView for each card --------------------------
        for i in 0 ..< NUM_CARDS {
            var cd = CardData()
            cd.view = UIImageView()
            cd.view.isOpaque = true
            
            cardData.append(cd)
            parentView.addSubview(cd.view)
            
            setPosition(i, dealPosition)
            setFaceUp(i, faceUp:false)
            setZ(i,i)
            
            cd.view.layer.shadowColor = UIColor.black.cgColor
            cd.view.layer.shadowOpacity = 1
            cd.view.layer.shadowOffset = CGSize.zero
            cd.view.layer.shadowRadius = 3
            cd.view.layer.shadowPath = UIBezierPath(rect: cd.view.bounds).cgPath
        }
        
        // assign card images to deck
        var index = 0
        for s in 0 ..< NUM_SUIT {
            for r in 0 ..< NUM_RANK {
                cardData[index].suit = s
                cardData[index].rank = r
                cardData[index].picIndex = cardData[index].suit * NUM_RANK + r
                index += 1
            }
        }
    }
    
    func findIndex( _ rank:Int, _ suit:Int) -> Int {
        for i in 0 ..< NUM_CARDS {
            if cardData[i].rank == rank && cardData[i].suit == suit { return i }
        }
        return EMPTY
    }
    
    // MARK:
    
    func card(_ index:Int) -> CardData { return cardData[index] }
    func setZ(_ index:Int, _ value:Int) { if index >= 0 { cardData[index].view.layer.zPosition = CGFloat(value * 10) }}
    
    // MARK:
    
    func setPosition(_ index:Int, _ pos:CGPoint) {
        if index != EMPTY {
            cardData[index].homePosition = pos
            cardData[index].view.frame = CGRect(x: pos.x,y: pos.y,width: cardXS,height: cardYS)
        }
    }
    
    func goBackHome(_ index:Int) {
        UIView.animate(withDuration: 0.3, delay:0, options: animateOptions, animations: {
            self.setPosition(index, self.cardData[index].homePosition)
        }, completion: nil)
    }
    
    func setDeltaPosition(_ index:Int, _ dx:CGFloat, _ dy:CGFloat) {
        let pos = cardData[index].homePosition
        cardData[index].view.frame = CGRect(x: pos.x + dx,y: pos.y + dy,width: cardXS,height: cardYS)
    }
    
    // MARK:
    
    func setFaceUp(_ index:Int, faceUp:Bool) {
        self.cardData[index].view.image = faceUp ? self.cardPicture[self.cardData[index].picIndex] : backFace
    }
    
    // MARK:
    
    func shuffle() {
        for _ in 0 ..< 1000 {
            let i1 = Int(arc4random_uniform(UInt32(NUM_CARDS)))
            let i2 = Int(arc4random_uniform(UInt32(NUM_CARDS)))
            
            let t = cardData[i1]
            cardData[i1] = cardData[i2]
            cardData[i2] = t
        }
    }
    
    // MARK:
    
    func name(_ index:Int) -> String {
        if index == EMPTY { return "--- ----- " }
        
        let c = card(index)
        let hh = 100 + index as NSNumber
        return rankStr[c.rank] + suitStr[c.suit] + " (" + hh.stringValue + ") "
    }
}
