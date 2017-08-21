import Foundation

#if os(macOS) || os(iOS)
import Darwin
let CLOCK_MONOTONIC = _CLOCK_MONOTONIC
#else
import Glibc
#endif

let DEBUG = false

let encoder = JSONEncoder()

struct MyValue: Codable {
  let int1:Int
  let int2:Int
  let int3:Int
  let int4:Int
  let int5:Int
  let int6:Int
  let int7:Int
  let int8:Int
  let int9:Int
  let int10:Int

  init() {
    int1 = 1
    int2 = 12
    int3 = 123
    int4 = 1234
    int5 = 12345
    int6 = 123456
    int7 = 1234567
    int8 = 12345678
    int9 = 123456789
    int10 = 1234567890
  }
}

let myValue = MyValue()
let myDict: [String:Int] = ["int1": 1, "int2": 12, "int3": 123, "int4": 1234,
 "int5": 12345, "int6": 123456, "int7": 1234567, "int8": 12345678,
 "int9": 123456789, "int10": 1234567890]
let myArray: [Any] = ["int1", "int2", "int3", "int4", "int5", "int6", "int7", "int8", "int9", "int10", 1, 12, 123, 1234, 12345, 123456, 1234567, 12345678, 123456789, 1234567890]
let iterations = 1000

func benchmark(_ work: () -> Void) -> Double {
    var start = timespec()
    var end = timespec()
    clock_gettime(CLOCK_MONOTONIC, &start)
    work()
    clock_gettime(CLOCK_MONOTONIC, &end)
    return (Double(end.tv_sec) * 1.0e9 + Double(end.tv_nsec)) - (Double(start.tv_sec) * 1.0e9 + Double(start.tv_nsec))
}

func jsonEncoder_Struct() {
  do {
    for i in 1...iterations {
      let result = try encoder.encode(myValue)
      if DEBUG && i == 1 { 
        print("Result (JSONEncoder Struct): \(String(data: result, encoding: .utf8) ?? "nil")")
      }
    }
  } catch {
    print("Fail")
  }
}

func jsonEncoder_Dict() {
  do {
    for i in 1...iterations {
      let result = try encoder.encode(myDict)
      if DEBUG && i == 1 { 
        print("Result (JSONEncoder Dict): \(String(data: result, encoding: .utf8) ?? "nil")")
      }
    }
  } catch {
    print("Fail")
  }
}

func jsonSerialization_Dict() {
  do {
    for i in 1...iterations {
      let result = try JSONSerialization.data(withJSONObject: myDict)
      if DEBUG && i == 1 {
        print("Result (JSONSerialization): \(String(data: result, encoding: .utf8) ?? "nil")")
      }
    }
  } catch {
    print("Fail")
  }
}

func jsonSerialization_Array() {
  do {
    for i in 1...iterations {
      let result = try JSONSerialization.data(withJSONObject: myArray)
      if DEBUG && i == 1 {
        print("Result (JSONSerialization): \(String(data: result, encoding: .utf8) ?? "nil")")
      }
    }
  } catch {
    print("Fail")
  }
}

var timeNanos = benchmark {
  jsonEncoder_Struct()
}
print("JSONEncoder (Struct) took \(timeNanos / Double(iterations)) ns")

timeNanos = benchmark {
  jsonEncoder_Dict()
}
print("JSONEncoder (Dict) took \(timeNanos / Double(iterations)) ns")

timeNanos = benchmark {
  jsonSerialization_Dict()
}
print("JSONSerialization (Dict) took \(timeNanos / Double(iterations)) ns")

timeNanos = benchmark {
  jsonSerialization_Array()
}
print("JSONSerialization (Array) took \(timeNanos / Double(iterations)) ns")

