import UIKit

class QuartzView: UIView
{
    override func draw(_ rect: CGRect) {
        game.draw()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesBegan(touch.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesMoved(touch.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        game.touchesEnded()
    }
}
