//
//  StringCompare.swift
//  Test performance of String comparison
//
//  Created by David Jones (@djones6) on 16/11/2016 
//

import Foundation
import Dispatch

// Determine how many concurrent blocks to schedule (user specified, or 10)
var CONCURRENCY:Int = 1

// Determines how many times to convert per block
var EFFORT:Int = 1000000

// Strings to be compared
let STRINGS:[Int:String] = [
  1:"The witch had a cat and a very tall hat", 
  2:"The witch had a cat and a very tall foo", 
  3:"The witch had a cat and a very tall banana", 
  4:"The witch had a cat and a very tall h\u{00C5}t", 
  5:"The witch had a cat and a very tall h\u{0041}\u{030A}t",
  6:"The witch had a cat and a very tall h\u{0041}\u{030A}T",
]
var LHS:String = STRINGS[1]!
var RHS:String = STRINGS[1]!

// Determines how many times each block should be dispatched before terminating
var NUM_LOOPS:Int = 1

// Debug
var DEBUG = false

func usage() {
  print("Options are:")
  print("  -c, --concurrency n: number of concurrent Dispatch blocks (default: \(CONCURRENCY))")
  print("  -n, --num_loops n: no. of times to invoke each block (default: \(NUM_LOOPS))")
  print("  -e, --effort n: no. of conversions to perform per block (default: \(EFFORT))")
  print("  -l, --lhs String: 1st String to be compared (default: \(LHS))")
  print("  -r, --rhs String: 2nd String to be compared (default: \(RHS))")
  print("  -ln, --lhs_num n: Select 1st string from a set of built-in strings (see below)")
  print("  -rn, --rhs_num n: Select 2nd string from a set of built-in strings (see below)")
  print("  -d, --debug: print a lot of debugging output (default: \(DEBUG))")
  print("")
  print("Built-in strings:")
  for i in 1...STRINGS.count {
    print("  \(i): \"\(STRINGS[i]!)\" - elementWidth: \(STRINGS[i]!._core.elementWidth)")
  }
  exit(1)
}

// Parse an expected int value provided on the command line
func parseInt(param: String, value: String) -> Int {
  if let userInput = Int(value) {
    return userInput
  } else {
    print("Invalid value for \(param): '\(value)'")
    exit(1)
  }
}

// Parse command line options
var param:String? = nil
var remainingArgs = CommandLine.arguments.dropFirst(1)
for arg in remainingArgs {
  if let _param = param {
    param = nil
    switch _param {
    case "-c", "--concurrency":
      CONCURRENCY = parseInt(param: _param, value: arg)
    case "-e", "--effort":
      EFFORT = parseInt(param: _param, value: arg)
    case "-l", "--lhs":
      LHS = arg
    case "-r", "--rhs":
      RHS = arg
    case "-ln", "--lhs_num":
      let strNum = parseInt(param: _param, value: arg)
      LHS = STRINGS[min(STRINGS.count, strNum)]!
    case "-rn", "--rhs_num":
      let strNum = parseInt(param: _param, value: arg)
      RHS = STRINGS[min(STRINGS.count, strNum)]!
    case "-n", "--num_loops":
      NUM_LOOPS = parseInt(param: _param, value: arg)
    default:
      print("Invalid option '\(arg)'")
      usage()
    }
  } else {
    switch arg {
    case "-c", "--concurrency", "-e", "--effort", "-l", "--lhs", "-ln", "--lhs_num", "-r", "--rhs", "-rn", "--rhs_num", "-n", "--num_loops":
      param = arg
    case "-d", "--debug":
      DEBUG = true
    case "-?", "-h", "--help", "--?":
      usage()
    default:
      print("Invalid option '\(arg)'")
      usage()
    }
  }
}

if (DEBUG) {
  print("Concurrency: \(CONCURRENCY)")
  print("Effort: \(EFFORT)")
  print("Comparison: \"\(LHS)\" == \"\(RHS)\"")
  print("Debug: \(DEBUG)")
}

// Create a queue to run blocks in parallel
let queue = DispatchQueue(label: "hello", attributes: .concurrent)
let group = DispatchGroup()

// Block to be scheduled
func code(block: Int, loops: Int) -> () -> Void {
return {
  var yes = 0
  var no = 0
  for _ in 1...EFFORT {
    if LHS == RHS {
      yes += 1
    } else {
      no += 1
    }
  }
  if DEBUG && loops == 1 { print("Instance \(block) done") }
  if DEBUG && loops == 1 { print("Result: \"\(LHS)\" == \"\(RHS)\"?  yes: \(yes), no: \(no)") }
  // Dispatch a new block to replace this one
  if (loops < NUM_LOOPS) {
    queue.async(group: group, execute: code(block: block, loops: loops+1))
  } else {
    print("Block \(block) completed \(loops) loops")
  }
}
}

print("Queueing \(CONCURRENCY) blocks")

// Queue the initial blocks
for i in 1...CONCURRENCY {
  queue.async(group: group, execute: code(block: i, loops: 1))
}

print("Go!")

// Go
//dispatch_main()
//_ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(5000)) // 5 seconds
_ = group.wait(timeout: .distantFuture) // forever
//print("Waited 5 seconds, or completed")
