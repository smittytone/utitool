/*
    utitool
    uti.swift

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

import AppKit
import UniformTypeIdentifiers
import Clicore


extension Utitool {

    // MARK: Single Extension and UTI Look-up Functions

    /**
     Using the supplied file extension, extract and display system UTI information.

     The routine checks for a dot prefix on the extension and, if one is present,
     removes it.

     - Parameters:
        - fileExtension: The specified file extension.
        - settings:      The current processing settings.

     - Returns: An app exit code: success (0) or failure (1).
     */
    internal static func getExtensionData(_ fileExtension: String, _ settings: Settings) {

        // Just in case the user supplied an extension with a dot
        var extn = fileExtension
        if extn.hasPrefix(".") {
            extn = String(extn.dropFirst())
        }

        // Get UTI data from the extension
        let utiTypes = UTType.types(tag: extn, tagClass: .filenameExtension , conformingTo: nil)
        if utiTypes.count > 0 {
            Stdio.report("\(String(.bold))UTI information for file extension \(settings.highlightColour).\(extn)\(String(.normal))")
            if utiTypes.count > 1 {
                for (index, utiType) in utiTypes.enumerated() {
                    let head = "\(index + 1). \(String(.bold))\(utiType.identifier)\(String(.normal))"
                    let inset = head.components(separatedBy: ". ")[0].count + 2
                    Stdio.report(head)
                    showUtiData(utiType, false, inset)
                }
            } else {
                Stdio.report("UTI: \(String(.bold))\(utiTypes[0].identifier)\(String(.normal))")
                showUtiData(utiTypes[0], false)
                outputDescription(utiTypes[0])
            }
        } else {
            Stdio.report("No info available for extension .\(extn)")
        }
    }


    /**
     Using the supplied UTI, extract and display system information.

     - Parameters:
        - utiTest:    The specified UTI.
        - doShowHead: Include the UTI name as a heading.
        - settings:   The current processing settings.

     - Returns: An app exit code: success (0) or failure (1).
     */
    internal static func getUtiData(_ utiText: String, _ doShowHead: Bool, _ settings: Settings) {

        if let uti = UTType(utiText) {
            if doShowHead {
                Stdio.report("\(String(.bold))Information for UTI \(settings.highlightColour)\(uti.identifier)\(String(.normal))")
            }

            showUtiData(uti)
        } else {
            Stdio.report("UTI \(String(.bold))\(utiText)\(String(.normal)) is not known to the system")
        }
    }


    /**
     Show all the information for a specific UTI.

     - Parameters:
        - utiType:              The UTI to display.
        - includeExtensionInfo: Show information on file extensions.
        - inset:                The number of spaces, if any, to indent the readout.
     */
    private static func showUtiData(_ uti: UTType, _ includeExtensionInfo: Bool = true, _ inset: Int = 0) {

        outputDescription(uti, inset)

        if uti.tags.count > 0 {
            if includeExtensionInfo {
                outputFileExtensions(uti.tags, inset)
            }

            outputMimeTypes(uti.tags, inset)
        }

        outputRefUrl(uti, inset)
        outputStatus(uti, inset)
        // FROM 2.0.0
        outputDefaultApp(uti, inset)
        outputAllApps(uti, inset)
    }


    /**
     Output to STD ERR a UTI's related MIME types.

     - Parameters:
        - tags:     The specified UTI's tags as a dictionary.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputMimeTypes(_ tags:  [UTTagClass : [String]], _ addSpaces: Int = 0) {

        outputTags(tags, .mimeType, addSpaces)
    }


    /**
     Output to STD ERR a UTI's related file extensions.

     - Parameters:
        - tags:     The specified UTI's tags as a dictionary.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputFileExtensions(_ tags:  [UTTagClass : [String]], _ addSpaces: Int = 0) {

        outputTags(tags, .filenameExtension, addSpaces)
    }


    /**
     Output to STD ERR a UTI's related tags by tag class.

     - Parameters:
        - tags:     The specified UTI's tags as a dictionary.
        - tagClass: The required tag class as a `UTTagClass`.
        - addSpace: Add a four-space prefix. Default: false.
     */

    internal static func outputTags(_ tags:  [UTTagClass : [String]], _ tagClass: UTTagClass, _ addSpaces: Int = 0) {

        // Set the output text header
        var tagText = "file extensions"
        if tagClass == .mimeType {
            tagText = "MIME types"
        }

        // Add the tag values
        if let value = tags[tagClass] {
            if value.count > 0 {
                let items = value.joined(separator: ", ")
                Stdio.report("\(String(repeating: " ", count: addSpaces))\(tagText.capitaliseFirst()) registered: \(items)")
            } else {
                Stdio.report("\(String(repeating: " ", count: addSpaces))No \(tagText) registered")
            }
        } else {
            Stdio.report("\(String(repeating: " ", count: addSpaces))No \(tagText) registered")
        }
    }


    /**
     Output to STD ERR a UTI's registration status.

     - Parameters:
        - utiType: The UTI as a `UTType` instance.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputStatus(_ utiType: UTType, _ addSpaces: Int = 0) {

        if utiType.isDeclared {
            Stdio.report("\(String(repeating: " ", count: addSpaces))UTI is registered with the system")
        } else if utiType.isDynamic {
            Stdio.report("\(String(repeating: " ", count: addSpaces))UTI is dynamically assigned")
        }
    }


    /**
     Output to STD ERR a UTI's reference URL.

     - Parameters:
        - utiType:  The UTI as a `UTType` instance.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputRefUrl(_ utiType: UTType, _ addSpaces: Int = 0) {

        if let url = utiType.referenceURL {
            Stdio.report("\(String(repeating: " ", count: addSpaces))Reference URL: \(String(.underline))\(url)\(String(.normal))")
        }
    }


    /**
     Output to STD ERR a UTI's default application.

     - Parameters:
        - utiType:  The UTI as a `UTType` instance.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputDefaultApp(_ utiType: UTType, _ addSpaces: Int = 0) {

        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: utiType) else {
            Stdio.report("\(String(repeating: " ", count: addSpaces))Default app: None")
            return
        }

        var bundleID = "unknown"
        if let bundle = Bundle(url: appURL), let bid = bundle.bundleIdentifier {
            bundleID = bid
        }

        Stdio.report("\(String(repeating: " ", count: addSpaces))Default app: \(String(.underline))\(appURL.lastPathComponent.dropLast(4))\(String(.normal)) (\(bundleID))")
    }


    /**
     Output to STD ERR a UTI's default application.

     - Parameters:
        - utiType:  The UTI as a `UTType` instance.
        - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputAllApps(_ utiType: UTType, _ addSpaces: Int = 0) {

        var appURLs = NSWorkspace.shared.urlsForApplications(toOpen: utiType)
        if appURLs.count > 0, let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: utiType) {
            appURLs = appURLs.filter {
                $0 != defaultAppURL
            }
        }

        if !appURLs.isEmpty {
            let apps: [String] = appURLs.map {
                return String($0.lastPathComponent.dropLast(4))
            }

            let appList = apps.joined(separator: ", ")
            Stdio.report("\(String(repeating: " ", count: addSpaces))Other supporting apps: \(String(.underline))\(appList)\(String(.normal))")
        }
    }



    /**
     Output to STD ERR a UTI's description, if it has one.

     - Parameters:
     - utiType:  The UTI as a `UTType` instance.
     - addSpace: Add a four-space prefix. Default: false.
     */
    internal static func outputDescription(_ utiType: UTType, _ addSpaces: Int = 0) {

        if let desc = utiType.localizedDescription {
            Stdio.report("\(String(repeating: " ", count: addSpaces))Content type: \(desc)")
        } else {
            Stdio.report("\(String(repeating: " ", count: addSpaces))Content type: \(utiType.debugDescription)")
        }
    }


    // MARK: Launch Services Registry Processing Functions

    /**
     Read `lsregister` dumped output for UIT records and add to a list of UTIs
     and, if requested, apps claiming those UTIs.

     - Parameters:
     - listByApp: Should we also record apps? Default: false.
     - settings:  Current processing settings.
     */
    internal static func readLaunchServicesRegister(_ listByApp: Bool = false, _ settings: Settings) {

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
        Stdio.write(message: "Obtaining Launch Services’ registry data. This can take some time ", to: Stdio.ShellRoutes.Error)

        // Set up and start the activity display timer
        let cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { time in
            //Stdio.write(message: Stdio.ShellCursor.Backspace, to: Stdio.ShellRoutes.Error)
            Stdio.write(message: "•", to: Stdio.ShellRoutes.Error)
        }

        let recordPrefix = "type id"
        let keyValueSeparator = ":"
        let recordDelimiter = "--------------------------------------------------------------------------------"
        var utis: [String: UtiRecord] = [:]
        var apps: [String: AppRecord] = [:]


        // Get the data
        let (errCode, data) = Processes.runProcess(app: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", with: ["-dump"])

        // Check `data` for error conditions
        if errCode != EXIT_SUCCESS {
            Stdio.reportErrorAndExit(data, errCode)
        }

        var locale: String.Index = recordPrefix.startIndex
        var scanned: String? = nil
        let scanner = Scanner(string: data)
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
        if settings.doOutputJson {
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
                    Stdio.report("\(settings.highlightColour)\(String(.bold))\(key)\(String(.normal)) is associated with the following UTIs:")
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
                    Stdio.report("\(settings.highlightColour)\(String(.bold))\(key)\(String(.normal))")
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
    internal static func ignoreHardware(_ uti: String) -> Bool {

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
     Set an known UTI's default app.

     - Parameters:
        - settings: The current processing settings.

     - Return: Success (the messsage to output), or failure (an error)
     */
    internal static func setDefaultApp(_ settings: Settings) async -> Result<String, SetError> {

        // TODO allow these to be either way round
        let uti = settings.files[0]
        var app = settings.files[1]

        // Process the app name or path, to expand it
        if !app.hasPrefix("/") {
            // Convert an app name to a path
            guard let appPath = getAppPath(app) else {
                return .failure(SetError(code: .badApp, text: "could not determine path to app \(app)"))
            }

            app = appPath
        } else {
            if !app.hasSuffix(".app") {
                app.append(".app")
            }
        }

        // Get the key data
        let ws = NSWorkspace.shared
        guard let appID = getAppBundleID(app) else { return .failure(SetError(code: .badBundle, text: app))}
        guard let utiType = UTType(uti) else { return .failure(SetError(code: .badUTI, text: uti))}
        guard let appURL = ws.urlForApplication(withBundleIdentifier: appID) else {
            return .failure(SetError(code: .badApp, text: "could not access app \(app)"))
        }

        // Attempt to set the default app
        try? await ws.setDefaultApplication(at: appURL, toOpen: utiType)
        return .success("UTI \(uti) set to application \(appURL.lastPathComponent.dropLast(4)) (\(appID))")
    }


    /**
     Determine an app's Bundle ID.

     - Parameters:
        - verifiedAppPath: The path to the app.

     - Returns: The app's bundle ID, or `nil` on error.
     */
    internal static func getAppBundleID(_ verifiedAppPath: String) -> String? {

        if let bundleID = Bundle(path: verifiedAppPath)?.bundleIdentifier {
            return bundleID
        }

        return nil
    }
}
