//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Alexander Carlisle on 4/5/16.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import Foundation

class CalculatorBrain {
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    var description = " "
    
    //If there is a binary operation in progress then it is a partial result
    var isPartialResult : Bool{
        get {
            return pending != nil
        }
    }
    var result: Double{
        get{
            return accumulator
        }
    }
    // Resets all variable to the start state
    func clearBrain(){
        accumulator = 0
        description = " "
        pending = nil
        noNewOperand = true
        internalProgram.removeAll()
    }
    
    //Defining every symbol to operation key value pair
    private var operations : Dictionary< String, Operation> = [
        "π" : Operation.Constant(M_PI), //M_PI,
        "e" : Operation.Constant(M_E),
        "rnd": Operation.Random,
        "√" : Operation.UnaryOperation(sqrt),
        "±" : Operation.UnaryOperation({-$0}),
        "sin": Operation.UnaryOperation(sin),
        "cos": Operation.UnaryOperation(cos),
        "tan": Operation.UnaryOperation(tan),
        "log":Operation.UnaryOperation(log10),
        "ln": Operation.UnaryOperation(log),
        "x²": Operation.UnaryOperation({$0*$0}),
        "x⁻¹": Operation.UnaryOperation({  if $0 == 0{ return 0;} else {return 1/$0} }),
        "×": Operation.BinaryOperation({$0*$1}),
        "÷": Operation.BinaryOperation({$0/$1}),
        "+": Operation.BinaryOperation({$0+$1}),
        "−": Operation.BinaryOperation({$0-$1}),
        "=": Operation.Equals
    ]
    
    enum Operation {
        case Constant(Double)
        case Random
        case UnaryOperation((Double) -> Double)
        case BinaryOperation( (Double,Double) -> Double)
        case Equals
        
    }
    
    //No new operand tracks the case of a user inputting 7+=, and we need to know that the first 7 inputted was used twice to calculate the result
    private var noNewOperand = true
    
    
    //Previous operand tracks the last operand, in case the user inputs an operand and then a unary operation that operates on the last operand
    private var previousOperand = " "
    
    //This function takes in an operand as a Double and sets the accumulator to the operand
    func setOperand(operand: Double){
        accumulator = operand
        addOperandToDescriptionAndProgram(operand)
    }
    //This helper function takes care of formatting the description and updating the internal program
    private func addOperandToDescriptionAndProgram(op : AnyObject){
        noNewOperand = false
        if pending == nil{
            description = " "
        }
        let formatter = NSNumberFormatter()
        formatter.maximumSignificantDigits = 6
        var stringOperand = ""
        if let numOp = op as? Double{
            stringOperand  = formatter.stringFromNumber(numOp)!
        }
        else if let stringOp = op as? String{
            stringOperand = stringOp
        }
        previousOperand = String(stringOperand)
        description += String(stringOperand)
        internalProgram.append(op)
    }
    
    // This function when given a string, such as a variable, sets the internal accumulator to the given variable's associated value
    func setOperand(variableName: String){
        if let operand = variableValues[variableName]{
            accumulator = operand
        }
        else{
            accumulator = 0
        }
        addOperandToDescriptionAndProgram(variableName)
    }
    
    //This variable tracks each possible variable and the current associated values.
    var variableValues  = Dictionary<String, Double>()
    
    //This function updates the description variable based on the operation
    private func updateDescription(operation:Operation, symbol: String){
        switch operation{
            
        case .Constant:
            description += symbol
            noNewOperand = false
            
        case .Random:
            description += "R"
            noNewOperand = false
            
        case .UnaryOperation:
            //If there isn't a binary operation pending, this means that the unary operation just operated on
            // everything we had up this point in the description
            noNewOperand = false
            if pending == nil{
                description =  symbol + "(" + description + ")"
                
            }
            else{
                //Since there is a pending operation, this means that the last operand added ought to be acted on alone
                var lastOperandLength = previousOperand.characters.count
                lastOperandLength *= -1
                let end = description.endIndex.advancedBy(lastOperandLength)..<description.endIndex
                description.removeRange(end)
                description += symbol + "(" + previousOperand
                description += ")"
                //This is necessary because now the previous operand should be what it was,
                //but now it has been operated once by a unary operation
                previousOperand = symbol + "(" + previousOperand + ")"
                
            }
        case .BinaryOperation: description += symbol
        case .Equals:
            //case where user hit 7+ =, we need to add what is in the accumulator to the description
            if noNewOperand{
                description += previousOperand
            }
            
        }
    }
    
    typealias PropertyList = AnyObject
    //Will return the internal program, a list of either operations or operands if user wants to get
    //When set, it will go through the list of operations and operands performing each operation as needed.
    var program: PropertyList{
        get{
            return internalProgram
        }
        set{
            clearBrain()
            if let arrayOfOps = newValue as? [AnyObject]{
                for op in arrayOfOps{
                    if let operand = op as? Double{
                        setOperand(operand)
                    }
                    else if let operation = op as? String{
                        if variableValues[operation] != nil{
                            setOperand(operation)
                        }
                        else{
                            performOperation(operation)
                        }
                    }
                }
            }
        }
    }
    
    
    //Performs the operation based on which type of operation the user given symbol corresponds to
    func performOperation(symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol]{
            updateDescription(operation, symbol: symbol)
            switch operation{
            case .Constant(let value ):
                accumulator = value
            case .Random: accumulator = drand48()
            case .UnaryOperation(let function) :
                accumulator = function(accumulator)
            case .BinaryOperation(let function):
                noNewOperand = true
                executePendingBinaryOperation()
                pending = pendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
            case .Equals :
                executePendingBinaryOperation()
            }
        }
    }
    //Will execute a binary operation if one is in progress
    private func executePendingBinaryOperation(){
        if pending != nil{
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            pending = nil
        }
        
    }
    private var pending : pendingBinaryOperationInfo?
    struct pendingBinaryOperationInfo{
        var binaryFunction: (Double,Double) ->Double
        var firstOperand: Double
    }
    
}