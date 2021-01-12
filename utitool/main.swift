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


// MARK: - Constants

let STD_ERR = FileHandle.standardError
let STD_IN = FileHandle.standardInput

// TTY formatting
let RED = "\u{001B}[31m"
let YELLOW = "\u{001B}[33m"
let RESET = "\u{001B}[0m"
let BOLD = "\u{001B}[1m"
let ITALIC = "\u{001B}[3m"
let BSP = String(UnicodeScalar(8))


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

    let messageAsString = message + "\r\n"
    if let messageAsData: Data = messageAsString.data(using: .utf8) {
        STD_ERR.write(messageAsData)
    }
}


func showHelp() {

    // Display the help screen

    showHeader()

    writeToStderr("\nA macOS tool to reveal a file’s Uniform Type Identifier (UTI).")
    writeToStderr("Copyright 2021, Tony Smith (@smittytone). Source code available under the MIT licence.\r\n")
    writeToStderr(BOLD + "USAGE" + RESET + "\n    utitool [path 1] [path 2] [path " + ITALIC + "n" + RESET + "]")
}


func showHeader() {

    // Display the utility's version number

    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    writeToStderr("\(name) \(version) (\(build))")
}


// MARK: - Runtime Start

signal(SIGINT) {
    theSignal in writeToStderr("\(BSP)\(BSP)\rutitool interrupted -- halting")
    exit(EXIT_FAILURE)
}

var args = CommandLine.arguments

if args.count == 1 {
    showHelp()
} else {
    // Convert passed paths to URL
    for i: Int in 1..<args.count {
        
        let path = getFullPath(args[i])
        let url: URL = URL.init(fileURLWithPath: path, isDirectory: false)

        if let uti = url.typeIdentifier {
            report("UTI for \(path) is: \(uti)")
        } else {
            reportError("Could not get UTI for \(path)")
        }
    }
}

exit(EXIT_SUCCESS)

// MARK: - URL Extension

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}
