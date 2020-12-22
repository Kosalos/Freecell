import UIKit
import QuartzCore

var cards = Cards()
var game = Game()
var g = Graphics()

var screenYS = CGFloat()
var cardXS = CGFloat()
var cardYS = CGFloat()
var dealPosition = CGPoint()

class ViewController: UIViewController {
    
    @IBOutlet var newGameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let xs = view.bounds.width
        screenYS = view.bounds.height
        
        cardXS = xs/9
        cardYS = cardXS * 4 / 3

        cards.initialize(self.view)
        dealPosition = CGPoint(x: xs + 50, y: screenYS + 50)

        game.newGame()
    }
    
    @IBAction func newGame(_ sender: UIButton) {
        game.newGame()
    }

    override var prefersStatusBarHidden : Bool { return true;  }
}
