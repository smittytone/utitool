/*
    utitool
    main.swift

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


// MARK: - UTI Data Extraction and Output Functions

/**
 Using the supplied file extension, extract and display system UTI information.

 - Parameters
    - fileExtension: The specified file extension, minus the dot.

 - Returns An app exit code: success (0) or failure (1)
 */
func getExtensionData(_ fileExtension: String) -> Int32 {

    // Just in case the user supplied an extension with a dot
    var extn = fileExtension
    if extn.hasPrefix(".") {
        extn = String(extn.dropFirst())
    }

    // Get UIT data from the extension
    let utiTypes = UTType.types(tag: extn, tagClass: .filenameExtension , conformingTo: nil)
    if utiTypes.count > 0 {
        writeToStderr("\(BOLD)UTI information for file extension \(YELLOW).\(extn):\(RESET)")
        for (index, utiType) in utiTypes.enumerated() {
            writeToStderr("\(String(format: "%03d", index + 1)) \(BOLD)\(utiType.identifier)\(RESET)")
            outputDescription(utiType)

            if utiType.tags.count > 0 {
                outputMimeTypes(utiType.tags)
            }

            outputStatus(utiType)

            if index < utiTypes.count - 1 {
                writeToStderr("")
            }
        }
    } else {
        writeToStderr("No info available for extension .\(extn)")
    }

    return EXIT_SUCCESS
}


/**
 Using the supplied UTI, extract and display system information.

 - Parameters
    - uti: The specified UTI.

 - Returns An app exit code: success (0) or failure (1)
 */
func getUtiData(_ uti: String) -> Int32 {

    if let utiType = UTType(uti) {
        writeToStderr("\(BOLD)Information for UIT \(YELLOW).\(utiType.identifier):\(RESET)")
        outputDescription(utiType)

        if utiType.tags.count > 0 {
            outputMimeTypes(utiType.tags)
            outputFileExtensions(utiType.tags)
        }

        outputStatus(utiType)
    } else {
        report("UTI \(BOLD)\(uti)\(RESET) is not known to the system")
    }

    return EXIT_SUCCESS
}


/**
 Output a UTI's related MIME types.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
 */
func outputMimeTypes(_ tags:  [UTTagClass : [String]]) {

    outputTags(tags, .mimeType)
}


/**
 Output a UTI's related file extensions.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
 */
func outputFileExtensions(_ tags:  [UTTagClass : [String]]) {

    outputTags(tags, .filenameExtension)
}


/**
 Output a UTI's related tags by tag class.

 - Parameters
    - tags:     The specified UTI's tags as a dictionary.
    - tagClass: The required tag class as a `UTTagClass`.
 */

func outputTags(_ tags:  [UTTagClass : [String]], _ tagClass: UTTagClass) {

    // Set the output text header
    var tagText = "file extensions"
    if tagClass == .mimeType {
        tagText = "MIME types"
    }

    // Add the tag values
    for (key, value) in tags {
        if key == tagClass {
            if value.count > 0 {
                var items = ""
                for item in value {
                    items += item + ", "
                }

                writeToStderr("    \(tagText.capitaliseFirst()) registered: \(items.dropLast(2))")
            } else {
                writeToStderr("    No \(tagText) registered")
            }
        }
    }
}


/**
 Output a UTI's registration status.

 - Parameters
    - utiType: The UTI as a `UTType` instance.
 */
func outputStatus(_ utiType: UTType) {

    if utiType.isDeclared {
        writeToStderr("    UTI is registered with the system")
    } else if utiType.isDynamic {
        writeToStderr("    UTI is dynamically assigned")
    }
}


/**
 Output a UTI's description, if it has one.

 - Parameters
    - utiType: The UTI as a `UTType` instance.
 */
func outputDescription(_ utiType: UTType) {

    if let desc = utiType.localizedDescription {
        writeToStderr("    Content type: \(desc)")
    } else {
        writeToStderr("    Content type: \(utiType.debugDescription)")
    }
}


// MARK: - Path Processing Functions

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


// MARK: - STDIO Functions

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


// MARK: - Help/Info Functions

func showHelp() {

    // Display the help screen

    showHeader()

    report("\nA macOS tool to reveal a specified file’s Uniform Type Identifier (UTI).")
    report("It can also be used to display information about a specific UTI, or a supplied file extension.")
    report("Copyright © 2025, Tony Smith (@smittytone). Source code available under the MIT licence.\r\n")
    report("\(BOLD)USAGE\(RESET)\n    utitool [-e {extension}] [-u {UTI}] [path 1] [path 2] ... [path \(ITALIC)n\(RESET)]\r\n")
    report("\(BOLD)EXAMPLES\(RESET)")
    report("    utitool *                      -- Get data for all the files in the working directory.")
    report("    utitool text.md                -- Get data for a named file in the working directory.")
    report("    utitool text1.md text2.md      -- Get data for named files in the working directory.")
    report("    utitool /User/me/text1.md      -- Get data for any named file.")
    report("    utitool ../text1.md            -- Get data for a named file in the parent directory.")
    report("    utitool -e md                  -- Get data about UTIs associated with the file extenions \(ITALIC)md\(RESET).")
    report("    utitool -u com.bps.rust-source -- Get data about UTIs associated with the UTI \(ITALIC)com.bps.rust-source\(RESET).")
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
let args = CommandLine.arguments

// ...and process them
if args.count == 1 {
    // No user args? Just show the help info
    showHelp()
} else {
    // Get a file manager
    let fm = FileManager.default
    var count: UInt = 0
    var argCount: UInt = 0
    var argIsAValue: Bool = false
    var showMoreInfo:Bool = false
    var prevArg: String = ""
    var argType: Int = -1
    var files: [String] = []

    // Process the (separated) arguments
    for argument in args {
        // Ignore the first command line argument
        if argCount == 0 {
            argCount += 1
            continue
        }

        if argIsAValue {
            // Make sure we're not reading in an option rather than a value
            if argument.prefix(1) == "-" {
                reportErrorAndExit("Missing value for \(prevArg)")
            }

            argIsAValue = false

            switch argType {
                case 1:
                    exit(getExtensionData(argument))
                case 2:
                    exit(getUtiData(argument))
                default:
                    break
            }
        } else {
            switch argument {
                case "--extension":
                    fallthrough
                case "-e":
                    argIsAValue = true
                    argType = 1
                case "--uti":
                    fallthrough
                case "-u":
                    argIsAValue = true
                    argType = 2
                case "-m":
                    showMoreInfo = true
                case "-h":
                    fallthrough
                case "-help":
                    fallthrough
                case "--help":
                    showHelp()
                    exit(EXIT_SUCCESS)
                default:
                    if argument.prefix(1) == "-" {
                        reportErrorAndExit("Unknown argument: \(argument)")
                    } else {
                        files.append(argument)
                    }
            }

            prevArg = argument
        }

        argCount += 1

        // Trap commands that come last and therefore have missing args
        if argCount == CommandLine.arguments.count && argIsAValue {
            reportErrorAndExit("Missing value for \(argument)")
        }
    }

    // Convert passed paths to URL
    if files.count > 0 {
        for file in files {
            let path = getFullPath(file)
            var isDir: ObjCBool = false

            // Check that we're only dealing with files
            if fm.fileExists(atPath: path, isDirectory: &isDir) {
                if isDir.boolValue {
                    continue
                }
                
                // Make a URL from the path
                let url: URL = URL(fileURLWithPath: path, isDirectory: false)

                // And output the UTI if we can
                if let uti = url.typeIdentifier {
                    var kind = ""
                    if url.known {
                        kind = "system- or application"
                    } else if uti.hasPrefix("dyn") {
                        kind = "dynamically"
                    }

                    writeToStdout("UTI for \(path): \(uti) (\(kind)-declared type)")
                    if showMoreInfo {
                        _ = getUtiData(uti)
                    }
                } else {
                    reportError("Could not get UTI for \(path)")
                }

                // Tally the number of files reported on
                count += 1
            } else {
                reportError("\(path) is not a valid file reference")
            }

            if showMoreInfo {
                writeToStdout("")
            }
        }
    } else {
        // No reported files? Issue a warning
        report("No files specified or present")
    }
}

// Exit gracefully
exit(EXIT_SUCCESS)
