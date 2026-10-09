/*
    utitool
    entities.swift

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


/*
 App Record - data for an app capable of handling zero or more UTIs.
 This is implemented as a struct so we have room to accommodate
 future properties.
 */
struct AppRecord: Encodable {

    var name: String                                = ""
    var utis: [UtiRecordShort]                      = []
}


/*
 UTI Record - data for a UTI, including the apps that claim it,
 file extensions it is bound to, MIME types it is bound to, and
 the parent UTIs to which it conforms.
 */
struct UtiRecord: Encodable {

    var uti: String                                 = ""
    var ref: String                                 = ""
    var apps: [AppRecord]                           = []
    var extensions: [String]                        = []
    var mimeTypes: [String]                         = []
    var parents: [String]                           = []

    /**
     Provide a simplified version of the UTI Record, ie. one
     without app data.
     */
    func shortVersion() -> UtiRecordShort {

        var basicRecord = UtiRecordShort()
        basicRecord.uti = self.uti
        basicRecord.extensions = self.extensions
        basicRecord.mimeTypes = self.mimeTypes
        basicRecord.parents = self.parents
        return basicRecord
    }
}


/*
 Brief UTI Record - data for a UTI, including the file extensions it is bound to,
 MIME types it is bound to, and the parent UTIs to which it conforms.
 */
struct UtiRecordShort: Encodable {

    var uti: String                                 = ""
    var extensions: [String]                        = []
    var mimeTypes: [String]                         = []
    var parents: [String]                           = []
}


/*
 Record to hold processing-oriented variables in new cli code format.
 */
struct Settings {

    var doOutputJson: Bool                          = false
    var showMoreInfo: Bool                          = false
    var doLaunchServicesReadApps: Bool              = false
    var doLaunchServicesReadUtis: Bool              = false
    var doSetDefaultApp: Bool                       = false
    var highlightColour: String                     = String(Stdio.ShellColour.yellow)
    var files: [String]                             = []
}


/*
 Processing outcome error value.
 */
public struct SetError: Error, LocalizedError {

    public var code: SetErrorKind                   = .noError
    public var text: String                         = "unknown"
    public var errorDescription: String? {
        switch self.code {
            case .noError:
                return nil
            case .badUTI:
                return "system did not recognise UTI \(text)"
            case .badApp:
                return "\(text)"
            case .badSet:
                return "could not set \(text)"
            case .badBundle:
                return "cound not get the bundle ID of app \(text)"
        }
    }
}


/*
 Processing error types.
 */
public enum SetErrorKind: Int, Error {

    case noError                                    = 0
    case badUTI                                     = 1
    case badApp                                     = 2
    case badSet                                     = 3
    case badBundle                                  = 4
}
