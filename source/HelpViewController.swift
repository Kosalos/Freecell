import UIKit

let help = """
Move all cards from the play area to the four foundations on the top right.
Foundation piles must start with aces of each suit, and are built up in sequential order.

Cards can be moved from one column to another as long as their colors alternate
and they are in sequential order from highest to lowest.

Four free cells are located on the top left.
You can place any card in a free cell.
These cards can later be mobed to the play area or to the foundations.

You can also move any card to empty columns.

You can move mulitple cards together at the same time,
but only if they are in sequential order and
only if there are enough free cells or open columns for you
to move these cards at one time.
"""

class HelpViewController: UIViewController {

    @IBOutlet var helptext: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 550,height: 700)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        helptext.text = help
    }
}
