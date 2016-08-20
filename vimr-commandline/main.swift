/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func run(command command: String, arguments: [String] = []) -> String? {
  let pipe = NSPipe()
  
  let task = NSTask()
  task.standardOutput = pipe
  task.launchPath = command
  task.arguments = arguments
  
  task.launch()
  let file = pipe.fileHandleForReading;
  let data = file.readDataToEndOfFile()
  file.closeFile()
  
  let output = NSString(data: data, encoding: NSUTF8StringEncoding)
  return output?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
}

let supportedArgs = [
  "-d",
  "-R",
  "-Z",
  "-m",
  "-M",
  "-b",
  "-V",
  "-D",
  "-n",
  "-u",
  "-i",
  "--noplugin",
  "-o",
  "-O",
  "-p",
  "-o",
  "-O",
  "-p",
  "+",
  "--cmd",
  "-c",
  "-S",
  "--startuptime",
]

let args = Process.arguments.dropFirst()

let argsToCheck: [String]
if let idxOfDashDash = Process.arguments.indexOf("--") {
  argsToCheck = Array(Process.arguments[1..<idxOfDashDash])
} else {
  argsToCheck = Array(Process.arguments.dropFirst())
}

var invalidArgs = [String]()
argsToCheck.forEach { (arg) in
  guard arg.hasPrefix("-") || arg.hasPrefix("+") else {
    return
  }
  
  // "-" option (Read text from stdin) is explicitly forbidden.
  guard arg != "-" else {
    invalidArgs.append(arg)
    return
  }
  
  let supported = supportedArgs.reduce(false) { $0 || arg.hasPrefix($1) }
  if !supported {
    invalidArgs.append(arg)
  }
}

guard invalidArgs.isEmpty else {
  print("The argument(s)")
  print(invalidArgs.map { "  \($0)" }.joinWithSeparator("\n"))
  print("are not supported.")
  exit(1)
}

let allowedSet = NSCharacterSet.URLQueryAllowedCharacterSet()
guard let argString = args.joinWithSeparator(" ").stringByAddingPercentEncodingWithAllowedCharacters(allowedSet) else {
  print("There was an error while processing the arguments! Exiting...")
  exit(1)
}

let openArg = "vimr://vimr-cli?args=\(argString)"
run(command: "/usr/bin/open", arguments: [openArg])