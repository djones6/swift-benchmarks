//
//  JSONTest.swift
//  Test performance of NSJSONSerialization converting to a Data
//
//  Created by David Jones (@djones6) on 16/11/2016 
//

import Foundation
import Dispatch

// Determine how many concurrent blocks to schedule (user specified, or 10)
var CONCURRENCY:Int = 10

// Determines how many times to convert per block
var EFFORT:Int = 100

// Determines the number of key:value pairs in the payload
var LENGTH:Int = 10

// Determines how many times each block should be dispatched before terminating
var NUM_LOOPS:Int = 100

// Debug
var DEBUG = false

func usage() {
  print("Options are:")
  print("  -c, --concurrency n: number of concurrent Dispatch blocks (default: \(CONCURRENCY))")
  print("  -n, --num_loops n: no. of times to invoke each block (default: \(NUM_LOOPS))")
  print("  -e, --effort n: no. of conversions to perform per block (default: \(EFFORT))")
  print("  -l, --length n: no. of key/value pairs to be converted (size of payload) (default: \(LENGTH))")
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
    case "-l", "--length":
      LENGTH = parseInt(param: _param, value: arg)
    case "-n", "--num_loops":
      NUM_LOOPS = parseInt(param: _param, value: arg)
    default:
      print("Invalid option '\(arg)'")
      usage()
    }
  } else {
    switch arg {
    case "-c", "--concurrency", "-e", "--effort", "-l", "--length", "-n", "--num_loops":
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
  print("Length: \(LENGTH)")
  print("Debug: \(DEBUG)")
}

// The string to convert
var PAYLOAD = [String:Any]()
for i in 1...LENGTH {
  PAYLOAD["Item \(i)"] = Double(i)
}
if true { print("Payload length \(PAYLOAD.count), contents: \(PAYLOAD)") }

// Create a queue to run blocks in parallel
let queue = DispatchQueue(label: "hello", attributes: .concurrent)
let group = DispatchGroup()

// Block to be scheduled
func code(block: Int, loops: Int) -> () -> Void {
return {
  var data: Data? 
  for _ in 1...EFFORT {
    do {
      data = try JSONSerialization.data(withJSONObject: PAYLOAD)
    } catch {
      fatalError("Could not serialize to JSON: \(error)")
    }
  }
  if DEBUG {  print("Instance \(block) done") }
  if DEBUG { print("Serialized form = \(String(data: data!, encoding: .utf8)!)") }
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
  queue.async(group: group, execute: code(block: i, loops: 0))
}

print("Go!")

// Go
//dispatch_main()
//_ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(5000)) // 5 seconds
_ = group.wait(timeout: .distantFuture) // forever
//print("Waited 5 seconds, or completed")
