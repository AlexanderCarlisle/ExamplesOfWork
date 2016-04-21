//
//  GraphViewController.swift
//  Calculator
//
//  Created by Alexander Carlisle on 4/16/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
    //This function is given to it by calculator view controller and from here will be passed on to the view
    var funcToGraph : ((x: CGFloat) -> CGFloat)?

    //This function adds the pinch and pan recognizers to the views
    @IBOutlet var graphView: GraphView! {didSet{
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(
            target: graphView, action: #selector(GraphView.changeScale(_:))
            ))
        graphView.addGestureRecognizer(UIPanGestureRecognizer(
            target: graphView, action: #selector(GraphView.pan(_:))
            ))
        graphView.funcToGraph = funcToGraph!
        }}
    
    //This method changes the location of the origin in the graph view on a double tap.
    @IBAction func moveOriginOnDoubleTap(recognizer: UITapGestureRecognizer) {
        graphView.origin = recognizer.locationInView(graphView)
    }
    
    
    
    
}
