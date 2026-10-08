# utitool 2.0.0

`utitool` is a macOS command line tool you can use to reveal a file’s Uniform Type Identifier (UTI).

It can also be used to reveal information about a specified UTI, or the UTI(s) bound to a specified file extension. Default editor application, and other apps that say they can open a given UTI or extension, are also listed.

macOS’ Launch Services registry data for UTIs or apps can also be viewed in machine- or human-readable form.

You can use the tool to set the default app for a specific UTI.

`utitool` requires macOS 12.4 ‘Monterey’ or above.

Building `utitool` from source requires my [Clicore Swift Package](https://github.com/smittytone/clicore).

For more details, and full usage information, [please see my website](https://smittytone.net/utitool/index.html).

## Version Management

The source of truth for version information is the *Xcode* project. If you compile `utitool` for macOS using the Swift compiler, the file `swift.plist` will be compiled into the binary to provide version information and to permit subsequent notarisation (after code signing).

The `sync-version.sh` script is my tool to update the subsidiary files after I have updated the app using *Xcode*. The current version of the app, in the `main` branch of the repo, will always contain up-to-date `utitool` version information with the subsidiary version information files, so you should not need to alter these files yourself. The script is currently macOS only.

## Release Notes ##

See [Changelog](./CHANGELOG.md)

## Licence ##

*utitool* is copyright © 2026, Tony Smith. Its source code is released under the MIT Licence.
