/*
    utitool
    uti.swift

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


// MARK: - UTI Data Extraction and Output Functions

/**
 Using the supplied file extension, extract and display system UTI information.

 The routine checks for a dot prefix on the extension and, if one is present,
 removes it.

 - Parameters
    - fileExtension:   The specified file extension.
    - highlightColour: The current colour for printing title emphasis.

 - Returns An app exit code: success (0) or failure (1).
 */
func getExtensionData(_ fileExtension: String, _ highlightColour: String) -> Int32 {

    // Just in case the user supplied an extension with a dot
    var extn = fileExtension
    if extn.hasPrefix(".") {
        extn = String(extn.dropFirst())
    }

    // Get UTI data from the extension
    let utiTypes = UTType.types(tag: extn, tagClass: .filenameExtension , conformingTo: nil)
    if utiTypes.count > 0 {
        Stdio.report("\(String(.bold))UTI information for file extension \(highlightColour).\(extn)\(String(.normal))")
        if utiTypes.count > 1 {
            for (index, utiType) in utiTypes.enumerated() {
                let head = "\(index + 1). \(String(.bold))\(utiType.identifier)\(String(.normal))"
                let inset = head.components(separatedBy: ". ")[0].count + 2
                Stdio.report(head)
                outputDescription(utiType, inset)

                if utiType.tags.count > 0 {
                    outputMimeTypes(utiType.tags, inset)
                }

                outputRefUrl(utiType)
                outputStatus(utiType, inset)
            }
        } else {
            Stdio.report("UTI: \(String(.bold))\(utiTypes[0].identifier)\(String(.normal))")
            outputDescription(utiTypes[0])

            if utiTypes[0].tags.count > 0 {
                outputMimeTypes(utiTypes[0].tags)
            }

            outputRefUrl(utiTypes[0])
            outputStatus(utiTypes[0])
        }
    } else {
        Stdio.report("No info available for extension .\(extn)")
    }

    return EXIT_SUCCESS
}


/**
 Using the supplied UTI, extract and display system information.

 - Parameters
    - uti:             The specified UTI.
    - doShowHead:      Include the UTI name as a heading.
    - highlightColour: The current colour for printing title emphasis.

 - Returns An app exit code: success (0) or failure (1).
 */
func getUtiData(_ uti: String, _ doShowHead: Bool, _ highlightColour: String) -> Int32 {

    if let utiType = UTType(uti) {
        if doShowHead {
            Stdio.report("\(String(.bold))Information for UTI \(highlightColour)\(utiType.identifier)\(String(.normal))")
        }

        outputDescription(utiType)

        if utiType.tags.count > 0 {
            outputFileExtensions(utiType.tags)
            outputMimeTypes(utiType.tags)
        }

        outputStatus(utiType)
        outputRefUrl(utiType)
    } else {
        Stdio.report("UTI \(String(.bold))\(uti)\(String(.normal)) is not known to the system")
    }

    return EXIT_SUCCESS
}


/**
 Output to STD ERR a UTI's related MIME types.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
    - addSpace: Add a four-space prefix. Default: false.
 */
func outputMimeTypes(_ tags:  [UTTagClass : [String]], _ addSpaces: Int = 0) {

    outputTags(tags, .mimeType, addSpaces)
}


/**
 Output to STD ERR a UTI's related file extensions.

 - Parameters
    - tags: The specified UTI's tags as a dictionary.
    - addSpace: Add a four-space prefix. Default: false.
 */
func outputFileExtensions(_ tags:  [UTTagClass : [String]], _ addSpaces: Int = 0) {

    outputTags(tags, .filenameExtension, addSpaces)
}


/**
 Output to STD ERR a UTI's related tags by tag class.

 - Parameters
    - tags:     The specified UTI's tags as a dictionary.
    - tagClass: The required tag class as a `UTTagClass`.
    - addSpace: Add a four-space prefix. Default: false.
 */

func outputTags(_ tags:  [UTTagClass : [String]], _ tagClass: UTTagClass, _ addSpaces: Int = 0) {

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

            Stdio.report("\(String(repeating: " ", count: addSpaces))\(tagText.capitaliseFirst()) registered: \(items.dropLast(2))")
        } else {
            Stdio.report("\(String(repeating: " ", count: addSpaces))No \(tagText) registered")
        }
    } else {
        Stdio.report("\(String(repeating: " ", count: addSpaces))No \(tagText) registered")
    }
}


/**
 Output to STD ERR a UTI's registration status.

 - Parameters
    - utiType: The UTI as a `UTType` instance.
    - addSpace: Add a four-space prefix. Default: false.
 */
func outputStatus(_ utiType: UTType, _ addSpaces: Int = 0) {

    if utiType.isDeclared {
        Stdio.report("\(String(repeating: " ", count: addSpaces))UTI is registered with the system")
    } else if utiType.isDynamic {
        Stdio.report("\(String(repeating: " ", count: addSpaces))UTI is dynamically assigned")
    }
}


/**
 Output to STD ERR a UTI's reference URL.

 - Parameters
    - utiType: The UTI as a `UTType` instance.
    - addSpace: Add a four-space prefix. Default: false.
 */
func outputRefUrl(_ utiType: UTType, _ addSpaces: Int = 0) {

    if let url = utiType.referenceURL {
        Stdio.report("\(String(repeating: " ", count: addSpaces))Reference URL: \(String(.underline))\(url)\(String(.normal))")
    }
}


/**
 Output to STD ERR a UTI's description, if it has one.

 - Parameters
    - utiType:  The UTI as a `UTType` instance.
    - addSpace: Add a four-space prefix. Default: false.
 */
func outputDescription(_ utiType: UTType, _ addSpaces: Int = 0) {

    if let desc = utiType.localizedDescription {
        Stdio.report("\(String(repeating: " ", count: addSpaces))Content type: \(desc)")
    } else {
        Stdio.report("\(String(repeating: " ", count: addSpaces))Content type: \(utiType.debugDescription)")
    }
}


// MARK: - Launch Services Registry Processing Functions

/**
 Read `lsregister` dumped output for UIT records and add to a list of UTIs
 and, if requested, apps claiming those UTIs.

 - Parameters
    - listByApp:       Should we also record apps? Default: false.
    - highlightColour: The current colour for printing title emphasis.
 */
func readLaunchServicesRegister(_ listByApp: Bool = false, _ highlightColour: String) {

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
    Stdio.write(message: "Obtaining Launch Services’ registry data", to: Stdio.ShellRoutes.Error)

    // Set up and start the activity display timer
    let cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { time in
        Stdio.write(message: ".", to: Stdio.ShellRoutes.Error)
    }

    let recordPrefix = "type id"
    let keyValueSeparator = ":"
    let recordDelimiter = "--------------------------------------------------------------------------------"
    var utis: [String: UtiRecord] = [:]
    var apps: [String: AppRecord] = [:]


    // Get the data
    let (errCode, data) = runProcess(app: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", with: ["-dump"])

    // Check `data` for error conditions
    if errCode != EXIT_SUCCESS {
        Stdio.reportErrorAndExit(data, errCode)
    }

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
                                    newRecord?.uti = bits[0]
                                case "bundle":
                                    let bits = value.components(separatedBy: " (")

                                    var appRecord = AppRecord()
                                    appRecord.name = bits[0]
                                    if newRecord == nil {
                                        newRecord = UtiRecord()
                                        newRecord?.uti = "unknown"
                                    }

                                    newRecord?.apps.append(appRecord)

                                    if bits[0] == "CoreTypes" {
                                        if ignoreHardware(newRecord!.uti) {
                                            // Don't include the current UTI
                                            newRecord = nil
                                        }
                                    }
                                case "reference URL":
                                    // Because URLs contain the separator character, `value` will need to be combined
                                    // with the remainder of the line parts to form the full URL.
                                    if parts.count > 2 {
                                        newRecord?.ref = value + keyValueSeparator + parts[2].trimmingCharacters(in: .whitespaces)
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
                                            } else if bit.contains("/") {
                                                newRecord!.mimeTypes.append(bit)
                                            }
                                        }

                                        if newRecord!.mimeTypes.count > 10 {
                                            print("****", newRecord!.uti, "\n", line)
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
                    var appRecord = AppRecord()
                    appRecord.name = app.name
                    appRecord.utis.append(utiRecord.shortVersion())
                    apps[app.name] = appRecord
                } else {
                    apps[app.name]!.utis.append(utiRecord.shortVersion())
                }
            }
        }
    }

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

            clearTimer(cursorTimer)

            if let output = String(data: outputData, encoding: .utf8) {
                Stdio.output(output)
            } else {
                throw NSError()
            }
        } catch  {
            // Generic error for all three failures above
            Stdio.reportErrorAndExit("Could not process Launch Services to JSON")
        }
    } else {
        // User has not asked for JSON output, so provide human-readable text
        // according to the type of data the user wants
        if listByApp {
            // Get a list of alphabetically sorted UTIs from the dictionary
            let sortedKeys: [String] = Array(apps.keys).sorted { $0 < $1 }
            clearTimer(cursorTimer)

            // Iterate over that list and output the info
            for key in sortedKeys {
                let appRecord = apps[key]!
                Stdio.report("\(highlightColour)\(String(.bold))\(key)\(String(.normal)) is associated with the following UTIs:")
                if !appRecord.utis.isEmpty {
                    // Order the subsidiary UTI list
                    let orderedUtis = appRecord.utis.sorted { $0.uti < $1.uti }
                    for uti in orderedUtis {
                        Stdio.report("    \((uti.uti))")
                    }
                }
            }
        } else {
            // Get a list of alphabetically sorted UTIs from the dictionary
            let sortedKeys: [String] = Array(utis.keys).sorted { $0 < $1 }
            clearTimer(cursorTimer)

            // Iterate over that list and output the info
            for key in sortedKeys {
                let utiRecord = utis[key]!
                Stdio.report("\(highlightColour)\(String(.bold))\(key)\(String(.normal))")
                if !utiRecord.extensions.isEmpty {
                    Stdio.report("    File extension\(utiRecord.extensions.count == 1 ? "" : "s"): \(listify(utiRecord.extensions))")
                }

                if !utiRecord.mimeTypes.isEmpty {
                    Stdio.report("    Mime type\(utiRecord.mimeTypes.count == 1 ? "" : "s"): \(listify(utiRecord.mimeTypes))")
                }

                if !utiRecord.parents.isEmpty {
                    Stdio.report("    Conforms to: \(listify(utiRecord.parents))")
                }

                if !utiRecord.ref.isEmpty {
                    Stdio.report("    Reference Information: \(String(.underline))\(utiRecord.ref)\(String(.normal))")
                }

                var apps: [String] = []
                for appRecord in utiRecord.apps {
                    apps.append(appRecord.name)
                }

                if !apps.isEmpty {
                    Stdio.report("    Claimed by: \(listify(apps))")
                } else {
                    Stdio.report("    Claimed by no apps")
                }
            }
        }
    }
}


/**
 Ignore Apple hardware UTIs.

 Clunky, but they're not marked as such.
 */
func ignoreHardware(_ uti: String) -> Bool {

    let hardwareTypes = ["macbook", "ipad", "ipod", "iphone", "device", "homepod", "macpro", "watch", "macmini", "imac", "emac", "ios", "laptop", "power", "studio", "xserve", "tower", "rackmount", "pencil", "airpods", "airport", "airtag", "tv", "airdisk", "beats", "time-capsule", "storage-", "display", "accessory", "graphic-icon", "legacy", "icon-", "network", "alert", "vision-pro", "ibook", "-icon"]

    if uti == "com.apple.mac" {
        return true
    }

    if uti.hasPrefix("com.apple.") {
        let stub = uti.dropFirst(10)
        for hardwareType in hardwareTypes {
            if stub.contains(hardwareType) {
                return true
            }
        }
    }

    if uti.hasPrefix("public.") {
        let stub = uti.dropFirst(7)
        if stub.contains("app-category") {
            return true
        }
    }

    return false
}


/**
 Shutdown the timer and clear the line.
 */
func clearTimer(_ timer: Timer) {

    timer.invalidate()
    Stdio.write(message:"\(Stdio.ShellActions.Clearline)\r", to: Stdio.ShellRoutes.Error)
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
