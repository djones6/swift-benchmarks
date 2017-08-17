import Foundation

#if os(macOS) || os(iOS)
import Darwin
let CLOCK_MONOTONIC = _CLOCK_MONOTONIC
#else
import Glibc
#endif

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
let iterations = 10000

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
      if i == 1 { 
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
      if i == 1 { 
        print("Result (JSONEncoder Dict): \(String(data: result, encoding: .utf8) ?? "nil")")
      }
    }
  } catch {
    print("Fail")
  }
}

func jsonSerialization() {
  do {
    for i in 1...iterations {
      let result2 = try JSONSerialization.data(withJSONObject: myDict)
      if i == 1 {
        print("Result (JSONSerialization): \(String(data: result2, encoding: .utf8) ?? "nil")")
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
  jsonSerialization()
}
print("JSONSerialization took \(timeNanos / Double(iterations)) ns")
