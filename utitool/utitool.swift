/*
    utitool
    main.swift

    Copyright © 2026 Tony Smith. All rights reserved.

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
import Clicore


@main
struct Utitool {

    public static func main() async throws {

        // Set up Ctrl-C handling
        Stdio.enableCtrlHandler("utitool interrupted -- halting")

        // FROM 2.0.0
        var settings = Settings()

#if os(macOS)
        // Use emoji markers on macOS
        Stdio.settings.useEmoji = true
#endif

        // FROM 1.2.0
        // Check for a colour shift
        if let _ = ProcessInfo.processInfo.environment["UTITOOL_USE_DARK_COLOUR"] {
            settings.highlightColour = String(Stdio.ShellColour.blue)
        }

        // Get the command line args...
        let collatedArguments = Cli.unify(args: CommandLine.arguments)

        // ...and process them
        if collatedArguments.count == 0 {
            // No user args? Just show the help info
            showHelp()
        } else {
            // Process the (separated) arguments
            var previousArgument = ""
            var requiresValue = -1
            for argument in collatedArguments {
                if requiresValue > 0 {
                    // Make sure we're not reading in an option rather than a value
                    if argument.prefix(1) == "-" {
                        Stdio.reportErrorAndExit("Missing value for \(previousArgument)")
                    }

                    switch requiresValue {
                        case 1:
                            exit(getExtensionData(argument, settings))
                        case 2:
                            exit(getUtiData(argument, true, settings))
                        default:
                            break
                    }

                    requiresValue = -1
                    continue
                }

                switch argument {
                    case "--extension", "-e":
                        requiresValue = 1
                        previousArgument = argument
                    case "--uti", "-u":
                        requiresValue = 2
                        previousArgument = argument
                    case "--more", "-m":
                        settings.showMoreInfo = true
                    case "--list", "-l":
                        settings.doLaunchServicesReadUtis = true
                    case "--apps", "-a":
                        settings.doLaunchServicesReadApps = true
                    case "--json", "-j":
                        settings.doOutputJson = true
                    case "-h", "-help", "--help":
                        showHelp()
                        Stdio.exitApp()
                    case "--version":
                        showHeader()
                        Stdio.exitApp()
                    default:
                        if argument.prefix(1) == "-" {
                            Stdio.reportErrorAndExit("Unknown argument: \(argument)")
                        } else {
                            settings.files.append(argument)
                        }
                }

                // Trap commands that come last and therefore have missing args
                if requiresValue > 0 && argument == collatedArguments.last {
                    Stdio.reportErrorAndExit("Missing value for argument \(argument)")
                }
            }

            if settings.doLaunchServicesReadApps {
                await readLaunchServicesRegister(true, settings)
            }

            if settings.doLaunchServicesReadUtis {
                await readLaunchServicesRegister(false, settings)
            }

            // Convert passed paths to URL
            var count = 0
            if settings.files.count > 0 {
                for file in settings.files {
                    let path = Path.getFullPath(file)
                    var isDir: ObjCBool = false

                    // Check that we're only dealing with files
                    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
                        if isDir.boolValue {
                            continue
                        }

                        // Make a URL from the path
                        let url = URL(fileURLWithPath: path, isDirectory: false)

                        // And output the UTI if we can
                        if let uti = url.typeIdentifier {
                            var extra = ""
                            if url.known {
                                extra = "UTI is registered with the system"
                            } else if uti.hasPrefix("dyn") {
                                extra = "UTI was dynamically assigned"
                            }

                            if settings.showMoreInfo {
                                Stdio.report("UTI for \(settings.highlightColour)\(path)\(String(.normal)) is \(settings.highlightColour)\(uti)\(String(.normal))")
                                _ = getUtiData(uti, false, settings)
                            } else {
                                Stdio.report("UTI for \(settings.highlightColour)\(path)\(String(.normal)) is \(settings.highlightColour)\(uti)\(String(.normal)) (\(extra))")
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
            } else if !settings.doLaunchServicesReadApps && !settings.doLaunchServicesReadUtis {
                // No reported files? Issue a warning
                Stdio.report("No files specified or present")
            }
        }

        // Exit gracefully
        Stdio.exitApp()
    }
}
