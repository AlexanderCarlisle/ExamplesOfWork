//
//  GraphView.swift
//  Calculator
//
//  Created by Alexander Carlisle on 4/16/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
@IBDesignable
class GraphView: UIView {
    
    @IBInspectable
    var axesDrawer : AxesDrawer = AxesDrawer() { didSet {setNeedsDisplay() }}
    @IBInspectable
    var scale: CGFloat = 1.0 { didSet {setNeedsDisplay() }}
    @IBInspectable
    var origin : CGPoint? { didSet {setNeedsDisplay() }}
    
    //The view only needs the function it will graph, and will rely on any view controller to set it.
    var funcToGraph = {(x: CGFloat)->CGFloat in return x } { didSet {setNeedsDisplay()
        }}
    let pointsPerUnit: CGFloat = 50.0
    
    /*
     For changing the scale, this function multiplies the current scale by the recognizer's scale and then resets the recognizer's scale back to 1, as we don't want to capture how far the user has zoomed since starting to pinch, but rather just how far they have zoomed since the last time change scale was called.
     */
    func changeScale(recognizer: UIPinchGestureRecognizer){
        switch recognizer.state{
        case .Changed, .Ended:
            scale *= recognizer.scale
            recognizer.scale = 1.0
        default:
            break
        }
    }
    /*
     This function takes in a point in bounds' scale and returns the appropiate x coordinate that can be fed into a function.
     */
    private func xInputFromBoundPoint(boundValue : CGFloat)-> CGFloat{
        let unScaledX = ( boundValue - origin!.x)/pointsPerUnit
        let scaledX = unScaledX/scale
        return scaledX
    }
    /*
     This function takes a real y value and translates it to the y point in the bounds of the view. This is necessary for taking the output of the function being graphed and learning which point should actually be drawn
     */
    private func yBoundsFromYOutput(realY : CGFloat)-> CGFloat{
        return origin!.y - realY * scale * pointsPerUnit
    }
    
    /*
     This function starts at the leftmost point in the bounds, and iterates across the entire bounds. To plot it gets a bounds x coordinate, finds what x value it corresponds to on the axis, finds funcToGraph(x), and then translates the resulting axis y value back to a y value that makes sense in terms of the bounds.
     */
    func graphFunction(){
        let startX = bounds.minX
        let endX = bounds.maxX
        let step = CGFloat(0.25)
        let path  = UIBezierPath()
        let startY = funcToGraph(xInputFromBoundPoint(startX))
        path.moveToPoint(CGPoint(x : startX, y:  yBoundsFromYOutput(CGFloat(startY))))
        
        for boundX in startX.stride(to: endX, by: step){
            let inputX = xInputFromBoundPoint(boundX)
            let yValue = funcToGraph(inputX)
            let plotY = yBoundsFromYOutput(CGFloat(yValue))
            path.addLineToPoint(CGPoint(x : boundX, y: plotY))
        }
        UIColor.greenColor().set()
        path.lineWidth = 4
        path.stroke()
    }
  
    
    
    private var previousOrigin : CGPoint?
    /*
     Pan needs to keep track of previous origin, because the translation in view will return how far the user has moved from the point where they started to pan. Therefore, this function keeps updating the origin by adding the translation since the user started panning to the origin value when the user first started panning(previous origin).
     */
    func pan(recognizer : UIPanGestureRecognizer){
        switch recognizer.state{
        case .Began:
            previousOrigin = origin
        case  .Changed, .Ended:
            let translation = recognizer.translationInView(self)
            origin!.x = previousOrigin!.x + translation.x
            origin!.y = previousOrigin!.y + translation.y
        default:
            break
        }
        
    }
    /*
     Draws the axes and calls graph function. 
     */
    override func drawRect(rect: CGRect) {
        if origin == nil{
            origin = CGPoint(x : bounds.midX, y: bounds.midY)
        }
        axesDrawer.drawAxesInRect(bounds, origin: origin!, pointsPerUnit: pointsPerUnit * scale)
        graphFunction()
    }
}
