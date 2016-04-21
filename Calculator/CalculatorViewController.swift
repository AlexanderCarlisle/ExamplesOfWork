//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Carlisle on 4/4/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    private var userIsInMiddleOfTyping = false
    private var brain = CalculatorBrain()
    @IBOutlet private weak var display: UILabel!
    
    @IBOutlet weak var descript: UILabel!
    
    //This updates the display based on what the user pushed
    @IBAction private func touchDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if display.text!.rangeOfString(".") == nil || digit != "."{
            if userIsInMiddleOfTyping {
                let textCurrentlyInDisplay = display.text!
                display.text = textCurrentlyInDisplay + digit
            }
            else {
                if digit == "."{
                    display.text = display.text! + digit
                }
                else{
                    display.text = digit
                }
            }
            userIsInMiddleOfTyping = true
        }
    }
    //This function looks to see whether or not the description is describing an onging result or not, and updates the description accordingly
    private func updateDescription(){
        var value = brain.description
        if brain.isPartialResult{ value += " ..." }
        else{ value += " ="}
        descript.text = value
    }
    
    // computed property that returns a double when got and updates the display as a string when set
    private var displayValue : Double{
        get {
            if let number = Double(display.text!) {
                return number
            }
            else if let variableValue = brain.variableValues[display.text!]{
                return variableValue
            }
            return 0
            
        }
        set{
            let formatter = NSNumberFormatter()
            formatter.maximumSignificantDigits = 6
            display.text = formatter.stringFromNumber(newValue)
        }
    }
    var savedProgram: CalculatorBrain.PropertyList?
    
    //This function sets a variable of name n to be the current display value in the calculator brain in order to later use that variable in calculations
    @IBAction func setMValue(sender: UIButton) {
        brain.variableValues["M"] = displayValue
        savedProgram = brain.program
        brain.program = savedProgram!
        displayValue = brain.result
        userIsInMiddleOfTyping = false
    }
    
    //This function retrieves the M value from the brain so the display can use it
    @IBAction func getMFromBrain(sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        displayValue = brain.result
    }
    
    //If the user is in the middle of typing this function removes the last digit pressed from the display. Otherwise it removes the last operand added or operation pressed by removing the last object from the brain's internal program.
    @IBAction func undo(sender: UIButton) {
        //If the user is still typing, undo is essentially backspace
        if userIsInMiddleOfTyping{
            let formatter = NSNumberFormatter()
            formatter.maximumSignificantDigits = 6
            var stringDisplay = formatter.stringFromNumber(displayValue)!
            if stringDisplay.characters.count == 1{
                displayValue = 0.0
                userIsInMiddleOfTyping = false
            }
            else{
                stringDisplay.removeAtIndex(stringDisplay.endIndex.predecessor())
                displayValue = Double(stringDisplay)!
            }
        }
            //Otherwise we want to remove the last operand/operation from the brain's program
        else{
            if var newProgram = brain.program as? [AnyObject]{
                if newProgram.count > 0 {
                    newProgram.removeLast()
                    brain.program = newProgram
                    displayValue = brain.result
                    updateDescription()
                }
            }
        }
    }
    //If there isn't a partial result, aka a pending binary operation, the segue is allowed.
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if brain.isPartialResult{
            return false
        }
        return true
    }
    //This function tells the brain to clear itself, and resets the display and description
    @IBAction func clear(sender: UIButton) {
        brain.clearBrain()
        brain.variableValues.removeAll()
        userIsInMiddleOfTyping = false
        displayValue = brain.result
        descript.text = brain.description
    }
    
    //This function sets an operand if the user was typing something into the display and then performs the operation given by whichever button was pushed.
    @IBAction func performOperation(sender: UIButton) {
        if userIsInMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayValue = brain.result
        updateDescription()
    }
    // This functions transforms the brains program into a function and sends that function to the graph view controller. 
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationvc = segue.destinationViewController
        if let graphvc = destinationvc as? GraphViewController {
            //only have one segue, so no need to switch on which segue
            if let identifier = segue.identifier{
                if identifier == "showGraph"{
                    func toBeGraphed(x: CGFloat) -> CGFloat{
                        brain.variableValues["M"] = Double(x)
                        brain.program = brain.program
                        return CGFloat(brain.result)
                    }
                    graphvc.funcToGraph = toBeGraphed
                    
                }
            }
        }
        
    }
}

