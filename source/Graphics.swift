import UIKit

class Graphics
{
    let path = UIBezierPath()
    
    func lineWidth(_ w:Int) { path.lineWidth = CGFloat(w) }
    
    func drawLine(_ x1:Int, _ y1:Int, _ x2:Int, _ y2:Int) {
        path.removeAllPoints()
        path.move(to: CGPoint(x: CGFloat(x1),y: CGFloat(y1)))
        path.addLine(to: CGPoint(x: CGFloat(x2),y: CGFloat(y2)))
        path.stroke()
    }
    
    func drawHLine(_ x1:Int, _ x2:Int, _ y:Int) { drawLine(x1,y,x2,y) }
    func drawVLine(_ x:Int, _ y1:Int, _ y2:Int) { drawLine(x,y1,x,y2) }
    
    func drawRectangle(_ x1:CGFloat, _ y1:CGFloat, _ x2:CGFloat, _ y2:CGFloat) {
        path.removeAllPoints()
        path.move(to: CGPoint(x:x1, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y2))
        path.addLine(to: CGPoint(x:x1, y:y2))
        path.close()
        path.stroke()
    }
    
    func drawFilledRectangle(_ x1:CGFloat, _ y1:CGFloat, _ x2:CGFloat, _ y2:CGFloat) {
        path.removeAllPoints()
        path.move(to: CGPoint(x:x1, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y2))
        path.addLine(to: CGPoint(x:x1, y:y2))
        path.close()
        path.fill()
    }
    
    func drawText(_ x:Int, _ y:Int, _ fontSize:Int, _ color:UIColor, _ str:NSString) {
        let fieldFont = UIFont(name: "Helvetica Neue", size: CGFloat(fontSize))
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = NSTextAlignment.center
        
        if let actualFont = fieldFont {
            let textFontAttributes = [
                NSAttributedString.Key.font: actualFont,
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.paragraphStyle: paraStyle,
                ]
            
            str.draw(in: CGRect(x: CGFloat(x-400), y: CGFloat(y), width: 800,height: 100), withAttributes: textFontAttributes)
        }
    }

    func drawText(_ pt:CGPoint, _ fontSize:Int, _ color:UIColor, _ str:NSString) {
        drawText(Int(pt.x),Int(pt.y),fontSize,color,str)
    }

    func drawTextValue(_ x:Int, _ y:Int, _ fontSize:Int, _ color:UIColor, _ value:Int) {
        let n = value as NSNumber
        drawText(x,y,fontSize,color,n.stringValue as NSString)
    }
    
    func drawFilledCircle(_ x:Int, _ y:Int, _ radius:Int) {
        let pt = CGPoint(x: CGFloat(x),y: CGFloat(y))
        let circlePath = UIBezierPath(arcCenter:pt, radius:CGFloat(radius), startAngle:0, endAngle:CGFloat(.pi * 2.0), clockwise: true)
        circlePath.fill()
    }
};
