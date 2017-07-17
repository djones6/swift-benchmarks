//
//  StringToData.swift
//  Test performance of String to Data conversion
//
//  Created by David Jones (@djones6) on 17/07/2017
//

import Foundation
import Dispatch

// Determine how many concurrent blocks to schedule (user specified, or 10)
var CONCURRENCY:Int = 10

// Determines how many times to convert per block
var EFFORT:Int = 5000

// Test duration (milliseconds)
var TEST_DURATION:Int = 5000

// String to be converted
var STRLEN = 100

// Method of conversion
var METHOD = 1

// Determines how many times each block should be dispatched before terminating
var NUM_LOOPS:Int = 9999999

// Debug
var DEBUG = false

func usage() {
  print("Options are:")
  print("  -c, --concurrency n: number of concurrent Dispatch blocks (default: \(CONCURRENCY))")
  print("  -n, --num_loops n: no. of times to invoke each block (default: \(NUM_LOOPS))")
  print("  -e, --effort n: no. of conversions to perform per block (default: \(EFFORT))")
  print("  -t, --time n: maximum runtime of the test (in ms) (default: \(TEST_DURATION))")
  print("  -s, --string n: length of string to be converted to Data (default: \(STRLEN))")
  print("  -m, --method n: method of conversion:")
  print("          1 = String.data(using: .utf8)")
  print("          2 = Data(String.utf8)")
  print("  -d, --debug: print a lot of debugging output (default: \(DEBUG))")
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
    case "-t", "--time":
      TEST_DURATION = parseInt(param: _param, value: arg)
    case "-s", "--string":
      STRLEN = parseInt(param: _param, value: arg)
    case "-m", "--method":
      METHOD = parseInt(param: _param, value: arg)
    case "-n", "--num_loops":
      NUM_LOOPS = parseInt(param: _param, value: arg)
    default:
      print("Invalid option '\(arg)'")
      usage()
    }
  } else {
    switch arg {
    case "-c", "--concurrency", "-e", "--effort", "-t", "--time", "-s", "--string", "-n", "--num_loops", "-m", "--method":
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

extension String {
    func asciiData(using encoding: Encoding) -> Data? {
        if _core.isASCII {
            return Data(bytes: UnsafeRawPointer(_core.startASCII), count: _core.count)
        } else {
            return self.data(using: encoding)
        }
    }
}

if (DEBUG) {
  print("Concurrency: \(CONCURRENCY)")
  print("Effort: \(EFFORT)")
  print("Debug: \(DEBUG)")
}

var MAX_CONCURRENCY:Int = CONCURRENCY

// Separate String for each thread
var STRINGS:[String] = [String]()
for i in 1...MAX_CONCURRENCY {
  STRINGS.append(String(repeating: "a", count: STRLEN))
}

// Create a queue to run blocks in parallel
let queue = DispatchQueue(label: "hello", attributes: .concurrent)
let group = DispatchGroup()
let lock = DispatchSemaphore(value: 1)
var completeLoops:Int = 0
var RUNNING = true

// Block to be scheduled
func code(block: Int, loops: Int) -> () -> Void {
return {
  var data: Data?
  let lSTRING = STRINGS[block-1]
  switch METHOD {
  case 1:
    for _ in 1...EFFORT {
      data = lSTRING.data(using: .utf8)!
    }
  case 2:
    for _ in 1...EFFORT {
      data = Data(lSTRING.utf8)
    }
  case 3:
    for _ in 1...EFFORT {
      data = lSTRING.asciiData(using: .utf8)!
    }
  default:
    print("Error - unknown method")
    return
  }
  if DEBUG && loops == 1 { 
    print("Instance \(block) done")
    print("Converted data: '\(String(data: data!, encoding: .utf8)!)'")
  }
  // Update loop completion stats
  queue.async(group: group) {
    _ = lock.wait(timeout: .distantFuture)
    completeLoops += 1
    lock.signal()
  }
  if RUNNING && loops < NUM_LOOPS {
    // Dispatch a new block to replace this one
    queue.async(group: group, execute: code(block: block, loops: loops+1))
  } else {
    if DEBUG { print("Block \(block) completed \(loops) loops") }
  }
}
}

// warmup
queue.async(group: group, execute: code(block: 1, loops: 1))
_ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(1000)) // 1 second
RUNNING = false
_ = group.wait(timeout: .distantFuture) // allow final blocks to finish
if DEBUG { print("Warmup complete") }

for c in 1...MAX_CONCURRENCY {
CONCURRENCY = c
completeLoops = 0
RUNNING = true
if DEBUG {
  print("Concurrency: \(CONCURRENCY), Effort: \(EFFORT), Loops: \(NUM_LOOPS), Time limit: \(TEST_DURATION)ms")
}
let startTime = Date()
// Queue the initial blocks
for i in 1...CONCURRENCY {
  queue.async(group: group, execute: code(block: i, loops: 1))
}

// Go
_ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(TEST_DURATION)) // 5 seconds
RUNNING = false
_ = group.wait(timeout: .distantFuture) // allow final blocks to finish

let elapsedTime = -startTime.timeIntervalSinceNow
let completedOps = completeLoops * EFFORT

var displayOps = Double(completedOps)
var opsUnit:NSString = "%.0f"
if completedOps > 100000000 {
  displayOps = displayOps / 1000000
  opsUnit = "%.2fm"
} else if completedOps > 100000 {
  displayOps = displayOps / 1000
  opsUnit = "%.2fk"
}
let opsPerSec = displayOps / elapsedTime

let output = String(format: "Concurrency %d: completed %d loops (\(opsUnit) ops) in %.2f seconds, \(opsUnit) ops/sec", CONCURRENCY, completeLoops, displayOps, elapsedTime, opsPerSec)
print("\(output)")
}
