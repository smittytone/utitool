/*
    utitool
    processes.swift

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


// MARK: - Process Handling Functions

/**
 Generic macOS process creation and run function.

 Make sure we clear the preference flag for this minor version, so that
 the sheet is not displayed next time the app is run (unless the version changes)

 - Parameters:
    - app:  The location of the app.
    - with: Array of arguments to pass to the app.

 - Returns: A tuple containing an error code (or zero for no error) and either
            the STD OUT output on success, or STD ERR output on error.
 */
func runProcess(app path: String, with args: [String]) -> (Int32, String) {

    let task: Process = Process()
    task.qualityOfService = .userInitiated
    task.executableURL = URL(fileURLWithPath: path)
    if args.count > 0 { task.arguments = args }

    // Pipe out the output to avoid putting it in the log
    let stdOutPipe = Pipe()
    let stdErrPipe = Pipe()
    var outputText: String = ""
    var errorText: String = ""

    let stdOutHandle = stdOutPipe.fileHandleForReading
    stdOutHandle.readabilityHandler = { fileHandle in
        // If there's available output to the redirected file handle,
        // get it and store it for processing later
        let data = fileHandle.availableData
        if let output = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                outputText += output
            }
        }
    }

    let stdErrHandle = stdErrPipe.fileHandleForReading
    stdErrHandle.readabilityHandler = { fileHandle in
        // If there's available output to the redirected file handle,
        // get it and store it for processing later
        let data = fileHandle.availableData
        if let output = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                errorText += output
            }
        }
    }

    // Hook up the outputs
    task.standardOutput = stdOutPipe
    task.standardError = stdErrPipe

    do {
        try task.run()
    } catch {
        return (1, errorText)
    }

    // Block until the task has completed (short tasks ONLY)
    task.waitUntilExit()

    // Clear the 'data availble' handlers
    // NOTE This seems to fix grabled data issues
    stdOutHandle.readabilityHandler = nil
    stdErrHandle.readabilityHandler = nil

    // Task completed successfully so return the standard output
    if task.terminationStatus == 0 {
        return (0, outputText)
    }

    // Task reported an error, so pass it back with any error message
    return (task.terminationStatus, errorText)
}
