/*
    utitool
    stdio.swift

    Copyright © 2025 Tony Smith. All rights reserved.

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

let STD_ERR: FileHandle = FileHandle.standardError
let STD_OUT: FileHandle = FileHandle.standardOutput

// TTY formatting
let BSP: String             = String(UnicodeScalar(8))


struct ShellColours {

    static let Black: String    = "\u{001B}[30m"
    static let Red: String      = "\u{001B}[31m"
    static let Green: String    = "\u{001B}[32m"
    static let Yellow: String   = "\u{001B}[33m"
    static let Blue: String     = "\u{001B}[34m"
    static let Magenta: String  = "\u{001B}[35m"
    static let Cyan: String     = "\u{001B}[36m"
    static let White: String    = "\u{001B}[37m"
}


struct ShellStyle {

    static let Bold: String     = "\u{001B}[1m"
    static let Italic: String   = "\u{001B}[3m"
    static let Normal: String   = "\u{001B}[0m"
}


/**
 Generic message display routine.
 */
func report(_ message: String) {

    writeToStderr(message)
}


/**
 Generic error display routine, but do not exit.
 */
func reportError(_ message: String) {

    writeToStderr(ShellColours.Red + ShellStyle.Bold + "ERROR" + ShellStyle.Normal + " " + message)
}


/**
 Generic error display routine, exiting the app after displaying the message.
 */
func reportErrorAndExit(_ message: String, _ code: Int32 = EXIT_FAILURE) {

    writeToStderr(ShellColours.Red + ShellStyle.Bold + "ERROR " + ShellStyle.Normal + message + " -- exiting")
    exit(code)
}


/**
 Write errors and other messages to STD ERR with a line break.
 */
func writeToStderr(_ message: String) {

    writeln(message: message, to: STD_ERR)
}


/**
 Write errors and other messages to STD OUT with a line break.
 */
func writeToStdout(_ message: String) {

    writeln(message: message, to: STD_OUT)
}


/**
 Write a message to a standard file handle with a line break.
 */
func writeln(message text: String, to fileHandle: FileHandle) {

   if let textAsData: Data = (text  + "\r\n").data(using: .utf8) {
        fileHandle.write(textAsData)
    }
}


/**
 Write a message to a standard file handle with no line break.
 */
func write(message text: String, to fileHandle: FileHandle) {

    if let textAsData: Data = (text).data(using: .utf8) {
        fileHandle.write(textAsData)
    }
}

