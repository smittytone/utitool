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


// MARK: - Global Constants

// FROM 1.2.0
struct CliConstants {

    static let CtrlCExitCode: Int32 = 130
    static let CtrlCMessage: String = "\(Stdio.ShellCursor.Return)\(Stdio.ShellCursor.Clearline)"
}

// MARK: - Global Variables

var doOutputJson: Bool = false
var showMoreInfo: Bool = false
var highlightColour: String = String(Stdio.ShellColour.yellow)


// MARK: - Runtime Start

// FROM 1.2.0
// Will this ever be shown? I wish I had an old Mac to try it on!
if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11 {
    Stdio.reportErrorAndExit("utitool requires macOS 11 or above")
}

// Trap CTRL-C
// Make sure the signal does not terminate the application
signal(SIGINT, SIG_IGN)

// Set up an event source for SIGINT...
let dss: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGINT,
                                                                queue: DispatchQueue.main)
// ...add an event handler (from above)...
dss.setEventHandler {
    Stdio.write(message: CliConstants.CtrlCMessage, to: Stdio.ShellRoutes.Error)
    Stdio.reportWarning("utitool interrupted -- halting")
    exit(CliConstants.CtrlCExitCode)
}

// ...and start the event flow
dss.resume()

// FROM 1.2.0
// Check for a colour shift
if let _ = ProcessInfo.processInfo.environment["UTITOOL_USE_DARK_COLOUR"] {
    highlightColour = String(Stdio.ShellColour.blue)
}

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
    var prevArg: String = ""
    var argType: Int = -1
    var files: [String] = []
    var doLaunchServicesReadApps: Bool = false
    var doLaunchServicesReadUtis: Bool = false

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
                Stdio.reportErrorAndExit("Missing value for \(prevArg)")
            }

            argIsAValue = false

            switch argType {
                case 1:
                    exit(getExtensionData(argument, highlightColour))
                case 2:
                    exit(getUtiData(argument, true, highlightColour))
                default:
                    break
            }
        } else {
            switch argument {
                case "--extension", "-e":
                    argIsAValue = true
                    argType = 1
                case "--uti", "-u":
                    argIsAValue = true
                    argType = 2
                case "--more", "-m":
                    showMoreInfo = true
                case "--list", "-l":
                    doLaunchServicesReadUtis = true
                case "--apps", "-a":
                    doLaunchServicesReadApps = true
                case "--json", "-j":
                    doOutputJson = true
                case "-h", "-help", "--help":
                    showHelp()
                    exit(EXIT_SUCCESS)
                case "--version":
                    showHeader()
                    exit(EXIT_SUCCESS)
                default:
                    if argument.prefix(1) == "-" {
                        Stdio.reportErrorAndExit("Unknown argument: \(argument)")
                    } else {
                        files.append(argument)
                    }
            }

            prevArg = argument
        }

        argCount += 1

        // Trap commands that come last and therefore have missing args
        if argCount == CommandLine.arguments.count && argIsAValue {
            Stdio.reportErrorAndExit("Missing value for \(argument)")
        }
    }

    if doLaunchServicesReadApps {
        readLaunchServicesRegister(true, highlightColour)
    }

    if doLaunchServicesReadUtis {
        readLaunchServicesRegister(false, highlightColour)
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
                    var extra = ""
                    if url.known {
                        extra = "UTI is registered with the system"
                    } else if uti.hasPrefix("dyn") {
                        extra = "UTI was dynamically assigned"
                    }

                    if showMoreInfo {
                        Stdio.report("UTI for \(highlightColour)\(path)\(String(.normal)) is \(highlightColour)\(uti)\(String(.normal))")
                        _ = getUtiData(uti, false, highlightColour)
                    } else {
                        Stdio.report("UTI for \(highlightColour)\(path)\(String(.normal)) is \(highlightColour)\(uti)\(String(.normal)) (\(extra))")
                    }
                } else {
                    Stdio.reportError("Could not get UTI for \(path)")
                }

                // Tally the number of files reported on
                count += 1
            } else {
                Stdio.reportError("\(path) is not a valid file reference")
            }
        }
    } else if !doLaunchServicesReadApps && !doLaunchServicesReadUtis {
        // No reported files? Issue a warning
        Stdio.report("No files specified or present")
    }
}

// Exit gracefully
exit(EXIT_SUCCESS)


// MARK: - Help/Info Functions

/**
 Display help information.
 */
func showHelp() {

    showHeader()

    Stdio.report("\nA macOS tool to reveal a specified file’s Uniform Type Identifier (UTI).")
    Stdio.report("It can also be used to display information about a specific UTI, or a supplied file extension,")
    Stdio.report("and to view what information macOS holds about UTIs and the apps that claim them.\r\n")
    Stdio.report("\(String(.bold))USAGE\(String(.normal))\n    utitool [--more] [path 1] [path 2] ... [path \(String(.italic))n\(String(.normal))]    View specific files’ UTIs.")
    Stdio.report("            [--uti [UTI]]                              View data for a specific UTI.")
    Stdio.report("            [--extension {file extension}]             View data for a specific file extension.")
    Stdio.report("            [--list] [--json]                          List system UTI data, with optional JSON output.")
    Stdio.report("            [--apps] [--json]                          List system app data, with optional JSON output.")
    Stdio.report("\r\n\(String(.bold))EXAMPLES\(String(.normal))")
    Stdio.report("    utitool text.md                     Get UTI for a named file in the current directory.")
    Stdio.report("    utitool -m text.md                  Get extended UTI info for a named file in the current directory.")
    Stdio.report("    utitool text1.md text2.md           Get UTIs for named files in the current directory.")
    Stdio.report("    utitool -m *                        Get extended UTI info for all the files in the current directory.")
    Stdio.report("    utitool -e md                       Get data about UTIs associated with the file extenions \(String(.italic))md\(String(.normal)).")
    Stdio.report("    utitool -u com.bps.rust-source      Get data about UTIs associated with the UTI \(String(.italic))com.bps.rust-source\(String(.normal)).")
    Stdio.report("    utitool -l                          View human-readable UTI information held by macOS.")
    Stdio.report("    utitool -a                          View human-readable app information held by macOS.")
    Stdio.report("    utitool -l -j                       Output pipeable UTI information held by macOS in JSON.\n")
}


/**
 Display the utility's version number
 */
func showHeader() {

    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal))")
    Stdio.report("Copyright © 2025, Tony Smith (@smittytone). Source code available under the MIT licence.")
}
