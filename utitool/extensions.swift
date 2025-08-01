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


// MARK: - URL Extensions

extension URL {

    var typeIdentifier: String? {

        // FROM 1.0.3
        // Add support for Big Sur UTType functionality
        if #available(macOS 11, *) {
            let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.contentTypeKey])
            if let uti: UTType = resourceValues!.contentType {
                return uti.identifier
            } else {
                return nil
            }
        } else {
            let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.typeIdentifierKey])
            return resourceValues!.typeIdentifier
        }
    }

    var localizedName: String? {
        let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.localizedNameKey])
        return resourceValues!.localizedName
    }

    var known: Bool {

        if #available(macOS 11, *) {
            let resourceValues: URLResourceValues? = try? resourceValues(forKeys: [.contentTypeKey])
            if let uti: UTType = resourceValues!.contentType {
                return uti.isDeclared
            }
        }

        return false
    }
}


// MARK: - String Extensions

extension String {

    func capitaliseFirst() -> String {
        return prefix(1).uppercased() + self.dropFirst()
    }
}
