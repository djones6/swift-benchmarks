import Foundation

let formatter:DateFormatter = DateFormatter()

let date:String = "Tue Jan 31 00:00:00 GMT 2017"
formatter.dateFormat = "E MMM dd HH:mm:ss z yyyy"

// This line causes a crash:
formatter.calendar = Calendar(identifier: .iso8601)
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)

let result = formatter.date(from: date)
if let result = result {
  print("Result: \(result)")
}
