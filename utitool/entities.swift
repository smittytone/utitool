/*
    utitool
    entities.swift

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


/*
 App Record - data for an app capable of handling zero or more UTIs.
 This is implemented as a struct so we have room to accommodate
 future properties.
 */
struct AppRecord: Encodable {
    var name: String = ""
    var utis: [UtiRecordShort] = []
}


/*
 UTI Record - data for a UTI, including the apps that claim it,
 file extensions it is bound to, MIME types it is bound to, and
 the parent UTIs to which it conforms.
 */
struct UtiRecord: Encodable {
    var uti: String = ""
    var apps: [AppRecord] = []
    var extensions: [String] = []
    var mimeTypes: [String] = []
    var parents: [String] = []
    var ref: String = ""

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
    var uti: String = ""
    var extensions: [String] = []
    var mimeTypes: [String] = []
    var parents: [String] = []
}
