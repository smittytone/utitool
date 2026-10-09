/*
    utitool
    utilities.swift

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
     Shutdown the timer and clear the line.
     */
    internal static func clearTimer(_ timer: Timer) {

        timer.invalidate()
        Stdio.write(message:"\(Stdio.ShellCursor.Clearline)\r", to: Stdio.ShellRoutes.Error)
    }


    /**
     Generate an array of strings by adding only those members of one array
     that are not present in a second array to the second array.

     - Parameters:
        - arrayA: An array of strings.
        - arrayB: The array into which the new, unique members are to be added.

     - Returns: The combined array,
     */
    internal static func dedupeStrings(_ arrayA: [String], _ arrayB: [String]) -> [String] {

        var arrayC = arrayB
        var modified = false
        for item in arrayA {
            var got = false
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

     - Parameters:
        - items: The source array.

     - Returns: A comma-separated list.

     */
    internal static func listify(_ items: [String]) -> String {

        if items.isEmpty {
            return ""
        }

        return String(items.joined(separator: ", "))
    }


    /**
     Check that the named app exists in one of the Mac's possible app locations.

     - Parameters:
        - appName: The name of the script in the bundle.

     - Returns: The app's absolute path including `.app` as an extension, or `nil` on error.
     */
    internal static func getAppPath(_ appName: String) -> String? {

        // Various possible Application locations are...
        var basePaths = ["/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities"]

        // ...and another is...
        let homeAppPath = ("~/Applications" as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: homeAppPath) {
            basePaths.append(homeAppPath)
        }

        // Run through the above list and check if the name app is there;
        // if it is, return it
        for basePath in basePaths {
            // Build the full app path
            var appPath = appName

            // Make sure our temporary full path ends in '.app'
            if !appPath.contains(".app") {
                appPath += ".app"
            }

            // Prefix the temp path with the current app folder
            if !appPath.contains(basePath) {
                appPath = basePath + "/" + appPath
            }

            // Check if the app is there -- if it is, return the full path
            if FileManager.default.fileExists(atPath: appPath) {
                return appPath
            }
        }

        // No match for the named app in any location,
        // so issue a failure note
        return nil
    }

}
