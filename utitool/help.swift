/*
    utitool
    help.swift

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


extension Utitool {

    /**
     Display help information.
     */
    internal static func showHelp() {

        showHeader()

        Stdio.report("\nA macOS tool to reveal a specified file’s Uniform Type Identifier (UTI).")
        Stdio.report("It can also be used to display information about a specific UTI, or a supplied file extension,")
        Stdio.report("and to view what information macOS holds about UTIs and the apps that claim them.\n")
        Stdio.report("\(String(.bold))USAGE\(String(.normal))\n    utitool [--more/-m] [path 1] [path 2] ... [path \(String(.italic))n\(String(.normal))] View specific files’ UTIs.")
        Stdio.report("            [--uti/-u [UTI]]                           View data for a specific UTI.")
        Stdio.report("            [--extension/-e {file extension}]          View data for a specific file extension.")
        Stdio.report("            [--list/-l] [--json/-j]                    List system UTI data, with optional JSON output.")
        Stdio.report("            [--apps/-a] [--json/-j]                    List system app data, with optional JSON output.")
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
        Stdio.report("\(String(.italic))https://smittytone.net/utitool/index.html\(String(.normal))")
    }


    /**
     Display the utility's version number
     */
    internal static func showHeader() {

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "utitool"
        Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal))")
        Stdio.report("Copyright © 2026, Tony Smith (@smittytone). Source code available under the MIT licence.")
    }
}
