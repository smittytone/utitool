/*
    utitool
    main.swift

    Copyright © 2021 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/


import Foundation
// FROM 1.0.3 -- Use macOS 11's UTI library
import UniformTypeIdentifiers


// MARK: - Constants

let STD_ERR: FileHandle = FileHandle.standardError
let STD_OUT: FileHandle = FileHandle.standardOutput

// TTY formatting
let RED: String             = "\u{001B}[31m"
let YELLOW: String          = "\u{001B}[33m"
let RESET: String           = "\u{001B}[0m"
let BOLD: String            = "\u{001B}[1m"
let ITALIC: String          = "\u{001B}[3m"
let BSP: String             = String(UnicodeScalar(8))
// FROM 1.0.4
let EXIT_CTRL_C_CODE: Int32 = 130
let CTRL_C_MSG: String      = "\(BSP)\(BSP)\rutitool interrupted -- halting"


// MARK: - Functions

func getFullPath(_ relativePath: String) -> String {

    // Convert a partial path to an absolute path

    // Standardise the path as best as we can (this covers most cases)
    var absolutePath: String = (relativePath as NSString).standardizingPath

    // Check for a unresolved relative path -- and if it is one, resolve it
    // NOTE This includes raw filenames
    if (absolutePath as NSString).contains("..") || !(absolutePath as NSString).hasPrefix("/") {
        absolutePath = processRelativePath(absolutePath)
    }

    // Return the absolute path
    return absolutePath
}


func processRelativePath(_ relativePath: String) -> String {

    // Add the basepath (the current working directory of the call) to the
    // supplied relative path - and then resolve it

    let absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
    return (absolutePath as NSString).standardizingPath
}


func report(_ message: String) {

    // Generic message display routine

    writeToStderr(message)
}


func reportError(_ message: String) {

    // Generic error display routine, but do not exit

    writeToStderr(RED + BOLD + "ERROR" + RESET + " " + message)
}


func reportErrorAndExit(_ message: String, _ code: Int32 = EXIT_FAILURE) {

    // Generic error display routine, quitting the app after

    writeToStderr(RED + BOLD + "ERROR " + RESET + message + " -- exiting")
    exit(code)
}


func writeToStderr(_ message: String) {

    // Write errors and other messages to stderr

    write(message: message, to: STD_ERR)
}


func writeToStdout(_ message: String) {

    // Write errors and other messages to stderr

    write(message: message, to: STD_OUT)
}


func write(message text: String, to fileHandle: FileHandle) {
    
    // Write text to the specified channel
    
    if let textAsData: Data = (text  + "\r\n").data(using: .utf8) {
        fileHandle.write(textAsData)
    }
}


func showHelp() {

    // Display the help screen

    showHeader()

    report("\nA macOS tool to reveal a specified file’s Uniform Type Identifier (UTI).")
    report("Copyright © 2021, Tony Smith (@smittytone). Source code available under the MIT licence.\r\n")
    report(BOLD + "USAGE" + RESET + "\n    utitool [path 1] [path 2] ... [path " + ITALIC + "n" + RESET + "]\r\n")
    report(BOLD + "EXAMPLES" + RESET)
    report("    utitool *                 -- Get data for all the files in the working directory.")
    report("    utitool text.md           -- Get data for a named file in the working directory.")
    report("    utitool text1.md text2.md -- Get data for named files in the working directory.")
    report("    utitool /User/me/text1.md -- Get data for any named file.")
    report("    utitool ../text1.md       -- Get data for a named file in the parent directory.")
}


func showHeader() {

    // Display the utility's version number

    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    report(BOLD + "\(name) \(version) (\(build))" + RESET)
}


// MARK: - Runtime Start

// Trap CTRL-C
// Make sure the signal does not terminate the application
signal(SIGINT, SIG_IGN)

// Set up an event source for SIGINT...
let dss: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGINT,
                                                                queue: DispatchQueue.main)
// ...add an event handler (from above)...
dss.setEventHandler {
    writeToStderr(CTRL_C_MSG)
    exit(EXIT_CTRL_C_CODE)
}

// ...and start the event flow
dss.resume()


// Get the command line args...
var args = CommandLine.arguments

// ...and process them
if args.count == 1 {
    // No user args? Just show the help info
    showHelp()
} else {
    // Get a file manager
    let fm = FileManager.default
    var count: UInt = 0
    
    // Convert passed paths to URL
    for i: Int in 1..<args.count {
        
        let path = getFullPath(args[i])
        var isDir: ObjCBool = false
        
        // Check that we're only dealing with files
        if fm.fileExists(atPath: path, isDirectory: &isDir) {
            if !isDir.boolValue {
                // Make a URL from the path
                let url: URL = URL.init(fileURLWithPath: path, isDirectory: false)
                
                // And output the UTI if we can
                if let uti = url.typeIdentifier {
                    writeToStdout("UTI for \(path): \(uti)")
                } else {
                    reportError("Could not get UTI for \(path)")
                }
                
                // Tally the number of files reported on
                count += 1
            }
        } else {
            reportError("\(path) not a valid file reference")
        }
    }
    
    // No reported files? Issue a warning
    if count == 0 {
        report("No files specified or present")
    }
}

// Exit gracefully
exit(EXIT_SUCCESS)


// MARK: - URL Extension

extension URL {
    
    var typeIdentifier: String? {
        
        // FROM 1.0.3
        // Add support for Big Sur UTType functionality
        if #available(macOS 11, *) {
            let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.contentTypeKey])
            if let uti: UTType = resourceValues!.contentType {
                return uti.identifier
            } else {
                return nil
            }
        } else {
            let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.typeIdentifierKey])
            return resourceValues!.typeIdentifier
        }
    }
    
    var localizedName: String? {
        let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.localizedNameKey])
        return resourceValues!.localizedName
    }
        
}
