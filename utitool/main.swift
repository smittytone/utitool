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
import UniformTypeIdentifiers


// MARK: - Constants

let STD_ERR: FileHandle = FileHandle.standardError
let STD_OUT: FileHandle = FileHandle.standardOutput

// TTY formatting
let RED: String             = "\u{001B}[31m"
let YELLOW: String          = "\u{001B}[33m"
let MAGENTA: String         = "\u{001B}[35m"
let RESET: String           = "\u{001B}[0m"
let BOLD: String            = "\u{001B}[1m"
let ITALIC: String          = "\u{001B}[3m"
let BSP: String             = String(UnicodeScalar(8))
// FROM 1.0.4
let EXIT_CTRL_C_CODE: Int32 = 130
let CTRL_C_MSG: String      = "\(BSP)\(BSP)\rutitool interrupted -- halting"


// MARK: - Global Variables

var doOutputJson: Bool = false
var showMoreInfo:Bool = false


// MARK: - UTI Data Extraction and Output Functions

/**
 Using the supplied file extension, extract and display system UTI information.

 The routine checks for a dot prefix on the extension and, if one is present,
 removes it.

 - Parameters
    - fileExtension: The specified file extension.

 - Returns An app exit code: success (0) or failure (1).
 */
func getExtensionData(_ fileExtension: String) -> Int32 {

    // Just in case the user supplied an extension with a dot
    var extn = fileExtension
    if extn.hasPrefix(".") {
        extn = String(extn.dropFirst())
    }

    // Get UTI data from the extension
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

 - Returns An app exit code: success (0) or failure (1).
 */
func getUtiData(_ uti: String) -> Int32 {

    if let utiType = UTType(uti) {
        writeToStderr("\(BOLD)Information for UTI \(YELLOW).\(utiType.identifier)\(RESET):")
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
 Output to STD ERR a UTI's related MIME types.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
 */
func outputMimeTypes(_ tags:  [UTTagClass : [String]]) {

    outputTags(tags, .mimeType)
}


/**
 Output to STD ERR a UTI's related file extensions.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
 */
func outputFileExtensions(_ tags:  [UTTagClass : [String]]) {

    outputTags(tags, .filenameExtension)
}


/**
 Output to STD ERR a UTI's related tags by tag class.

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
    if let value = tags[tagClass] {
        if value.count > 0 {
            var items = ""
            for item in value {
                items += item + ", "
            }

            writeToStderr("    \(tagText.capitaliseFirst()) registered: \(items.dropLast(2))")
        } else {
            writeToStderr("    No \(tagText) registered")
        }
    } else {
        writeToStderr("    No \(tagText) registered")
    }
}


/**
 Output to STD ERR a UTI's registration status.

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
 Output to STD ERR a UTI's description, if it has one.

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


// MARK: - Launch Services Registry Processing Functions

/**
 Read `lsregister` dumped output for UIT records and add to a list of UTIs
 and, if requested, apps claiming those UTIs.

 - Parameters
    - listByApp: Should we also record apps? Default: false
 */
func readLaunchServicesRegister(_ listByApp: Bool = false) {

    /* This is a typical record from `lsregister -dump`

     --------------------------------------------------------------------------------
     type id:                    com.apple.realitycomposerpro (0x343d0)
     bundle:                     Reality Composer Pro (0x62c4)
     uti:                        com.apple.realitycomposerpro
     localizedDescription:       "Base" = ?, "en" = ?, "LSDefaultLocalizedValue" = "Reality Composer Pro Swift Package"
     flags:                      active  apple-internal  exported  trusted (0000000000000055)
     icons:                      0 values (272384 (0x42800))
     {
     }
     conforms to:                com.apple.package, public.composite-content, public.directory, public.item
     tags:                       .realitycomposerpro, application/octet-stream
     */

    // Tell the user what's happening
    write(message: "Obtaining Launch Services’ registry data", to: STD_ERR)

    // Set up and start the activity display timer
    let cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { time in
        write(message: ".", to: STD_ERR)
    }

    let recordPrefix = "type id"
    let keyValueSeparator = ":"
    let recordDelimiter = "--------------------------------------------------------------------------------"
    var utis: [String: UtiRecord] = [:]
    var apps: [String: AppRecord] = [:]


    // Get the data
    let data = runProcess(app: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", with: ["-dump"])
    // TODO Check `data` for error conditions

    var locale: String.Index = recordPrefix.startIndex
    var scanned: String? = nil
    let scanner: Scanner = Scanner(string: data)
    scanner.charactersToBeSkipped = nil

    // Scan for UTI records
    while !scanner.isAtEnd {
        // Here we're at the start of a record
        locale = scanner.currentIndex
        scanned = scanner.scanUpToString(keyValueSeparator)

        if let content = scanned, !content.isEmpty {
            if content.trimmingCharacters(in: .whitespaces) != recordPrefix {
                // Scan to start of next record
                _ = scanner.scanUpToString(recordDelimiter)
                scanner.skipCharacters(recordDelimiter.count)
                continue
            }

            // Step back to the start of the record
            scanner.currentIndex = locale

            // Get the record and move the index to the next one
            scanned = scanner.scanUpToString(recordDelimiter)
            scanner.skipCharacters(recordDelimiter.count)

            if let record = scanned, !record.isEmpty {
                var newRecord: UtiRecord? = nil
                let lines = record.components(separatedBy: "\n")
                if lines.count > 1 {
                    // Process the record line by line
                    for line in lines {
                        let parts = line.components(separatedBy: keyValueSeparator)
                        if parts.count > 1 {
                            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let value = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                            switch key {
                                case "type id":
                                    let bits = value.components(separatedBy: " ")
                                    newRecord = UtiRecord()
                                    newRecord!.uti = bits[0]
                                case "bundle":
                                    let bits = value.components(separatedBy: " (")
                                    if bits[0] != "CoreTypes" {
                                        var appRecord = AppRecord()
                                        appRecord.name = bits[0]
                                        newRecord!.apps.append(appRecord)
                                    } else {
                                        // This is a very crude method to remove hardware UTIs:
                                        // `CoreTypes` contains other UTIs
                                        newRecord = nil
                                    }
                                case "conforms to":
                                    let bits = value.components(separatedBy: ", ")
                                    if bits.count > 0 && newRecord != nil {
                                        newRecord!.parents.append(contentsOf: bits)
                                    }
                                case "tags":
                                    let bits = value.components(separatedBy: ", ")
                                    if bits.count > 0 && newRecord != nil {
                                        for bit in bits {
                                            if bit.hasPrefix(".") {
                                                newRecord!.extensions.append(bit)
                                            } else {
                                                newRecord!.mimeTypes.append(bit)
                                            }
                                        }
                                    }
                                default:
                                    break
                            }
                        }
                    }

                    // If we have a UTI record, add it to the store
                    if let utiRecord = newRecord {
                        if utis[utiRecord.uti] == nil {
                            utis[utiRecord.uti] = utiRecord
                        } else {
                            // Got it - add the parts with dedupe
                            for appRecordA in utiRecord.apps {
                                var got: Bool = false
                                for appRecordB in utis[utiRecord.uti]!.apps {
                                    if appRecordA.name == appRecordB.name {
                                        got = true
                                        break
                                    }
                                }

                                if !got {
                                    utis[utiRecord.uti]!.apps.append(appRecordA)
                                }
                            }

                            utis[utiRecord.uti]!.extensions = dedupeStrings(utiRecord.extensions, utis[utiRecord.uti]!.extensions)
                            utis[utiRecord.uti]!.mimeTypes = dedupeStrings(utiRecord.mimeTypes, utis[utiRecord.uti]!.mimeTypes)
                        }
                    }
                }
            }
        }
    }

    // If requested, build the app database from the UTI database
    if listByApp {
        for (_, utiRecord) in utis {
            for app in utiRecord.apps {
                if apps[app.name] == nil {
                    var ar = AppRecord()
                    ar.name = app.name
                    ar.utis.append(utiRecord.shortVersion())
                    apps[app.name] = ar
                } else {
                    apps[app.name]!.utis.append(utiRecord.shortVersion())
                }
            }
        }
    }

    // Shutdown the timer and clear the line
    cursorTimer.invalidate()
    write(message:"\r", to: STD_ERR)

    // Write out the results
    if doOutputJson {
        // User has asked for JSON output. This is sent to STD_OUT so it can be piped
        // to another tool, for example `jq`.
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .sortedKeys

            var outputData: Data
            if listByApp {
                outputData = try jsonEncoder.encode(apps)
            } else {
                outputData = try jsonEncoder.encode(utis)
            }

            if let output = String(data: outputData, encoding: .utf8) {
                writeToStdout(output)
            } else {
                throw NSError()
            }
        } catch  {
            // Generic error for all three failures above
            reportErrorAndExit("Could not process Launch Services to JSON")
        }
    } else {
        // User has not asked for JSON output, so provide human-readable text
        // according to the type of data the user wants
        if listByApp {
            for (app, appRecord) in apps {
                writeToStdout("\(YELLOW)\(BOLD)\(app)\(RESET) is associated with the following UTIs:")
                if !appRecord.utis.isEmpty {
                    for uti in appRecord.utis {
                        writeToStdout("  \((uti.uti))")
                    }
                }
            }
        } else {
            for (uti, utiRecord) in utis {
                writeToStdout("\(YELLOW)\(BOLD)\(uti)\(RESET)")
                if !utiRecord.extensions.isEmpty {
                    writeToStdout("  File extension\(utiRecord.extensions.count == 1 ? "" : "s"): \(listify(utiRecord.extensions))")
                }

                if !utiRecord.mimeTypes.isEmpty {
                    writeToStdout("  Mime type\(utiRecord.mimeTypes.count == 1 ? "" : "s"): \(listify(utiRecord.mimeTypes))")
                }

                if !utiRecord.parents.isEmpty {
                    writeToStdout("  Conforms to: \(listify(utiRecord.parents))")
                }

                var apps: [String] = []
                for appRecord in utiRecord.apps {
                    apps.append(appRecord.name)
                }

                if !apps.isEmpty {
                    writeToStdout("  Claimed by: \(listify(apps))")
                } else {
                    writeToStdout("  Claimed by no apps")
                }
            }
        }
    }
}


/**
 Generate an array of strings by adding only those members of one array
 that are not present in a second array to the second array.

 - Parameters
    arrayA: An array of strings.
    arrayB: The array into which the new, unique members are to be added.

 - Returns The combined array,
 */
func dedupeStrings(_ arrayA: [String], _ arrayB: [String]) -> [String] {

    var arrayC: [String] = arrayB
    var modified: Bool = false
    for item in arrayA {
        var got: Bool = false
        if arrayC.contains(item) {
            got = true
        }

        if !got {
            arrayC.append(item)
            modified = true
        }
    }

    return modified ? arrayC : arrayB
}


/**
 Generate a human-readable list of comma-separated strings from
 an array of strings.

 - Parameters
    items: The source array.

 - Returns A comma-separated list.

 */
func listify(_ items: [String]) -> String {

    if items.isEmpty {
        return ""
    }
    
    var text: String = ""
    for item in items {
        text += item + ", "
    }

    return String(text[...].dropLast(2))
}


// MARK: - Path Processing Functions

/**
 Convert a partial path to an absolute path.

 - Parameters
    - relativePath: The partial path.

 - Returns The generated absolute path.
 */
func getFullPath(_ relativePath: String) -> String {

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


/**
 Add the the current working directory to the supplied relative path - and then resolve it.

 - Parameters
    - relativePath: The partial path.

 - Returns The generated absolute path.
 */
func processRelativePath(_ relativePath: String) -> String {

    let absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
    return (absolutePath as NSString).standardizingPath
}


// MARK: - STDIO Functions

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

    writeToStderr(RED + BOLD + "ERROR" + RESET + " " + message)
}


/**
 Generic error display routine, exiting the app after displaying the message.
 */
func reportErrorAndExit(_ message: String, _ code: Int32 = EXIT_FAILURE) {

    writeToStderr(RED + BOLD + "ERROR " + RESET + message + " -- exiting")
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


// MARK: - Help/Info Functions

/**
 Display help information.
 */
func showHelp() {

    showHeader()

    report("\nA macOS tool to reveal a specified file’s Uniform Type Identifier (UTI).")
    report("It can also be used to display information about a specific UTI, or a supplied file extension,")
    report("and to view what information macOS holds about UTIs and the apps that claim them.\r\n")
    report("\(BOLD)USAGE\(RESET)\n    utitool [--more] [path 1] [path 2] ... [path \(ITALIC)n\(RESET)]    View specific files’ UTIs.")
    report("            [--uti [UTI]]                                    View data for a specific UTI.")
    report("            [--extension {file extension}]                   View data for a specific file extension.")
    report("            [--list] [--json]                                List system UTI data, with optional JSON output.")
    report("            [--apps] [--json]                                List system app data, with optional JSON output.")
    report("\r\n\(BOLD)EXAMPLES\(RESET)")
    report("    utitool *                      -- Get data for all the files in the working directory.")
    report("    utitool text.md                -- Get data for a named file in the working directory.")
    report("    utitool -m text.md             -- Get data for a named file in the working directory and include extra UTI information.")
    report("    utitool text1.md text2.md      -- Get data for named files in the working directory.")
    report("    utitool /User/me/text1.md      -- Get data for any named file.")
    report("    utitool ../text1.md            -- Get data for a named file in the parent directory.")
    report("    utitool -e md                  -- Get data about UTIs associated with the file extenions \(ITALIC)md\(RESET).")
    report("    utitool -u com.bps.rust-source -- Get data about UTIs associated with the UTI \(ITALIC)com.bps.rust-source\(RESET).")
    report("    utitool -l                     -- View human-readable UTI information held by macOS.")
    report("    utitool -a                     -- View human-readable app information held by macOS.")
    report("    utitool -l -j                  -- Output pipeable UTI information held by macOS in JSON.\n")
}


/**
 Display the utility's version number
 */
func showHeader() {

    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    report(BOLD + "\(name) \(version) (\(build))" + RESET)
    report("Copyright © 2025, Tony Smith (@smittytone). Source code available under the MIT licence.")
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

    if doLaunchServicesReadApps {
        readLaunchServicesRegister(true)
    }

    if doLaunchServicesReadUtis {
        readLaunchServicesRegister()
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
                        writeToStdout("UTI for \(path): \(MAGENTA)\(uti)\(RESET)")
                        _ = getUtiData(uti)
                    } else {
                        writeToStdout("UTI for \(path): \(MAGENTA)\(uti)\(RESET) (\(extra))")
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
    } else if !doLaunchServicesReadApps && !doLaunchServicesReadUtis {
        // No reported files? Issue a warning
        report("No files specified or present")
    }
}

// Exit gracefully
exit(EXIT_SUCCESS)
