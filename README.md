# utitool 1.2.0

*utitool* is a macOS command line tool you can use to reveal a file’s Uniform Type Identifier (UTI).

It can also be used to reveal information about a specified UTI, or the UTI(s) bound to a specified file extension.

macOS’ Launch Services registry data for UTIs or apps can also be viewed in machine- or human-readable form.

*utitool* requires macOS 11.5 ‘Big Sur’ or above.

For more details, [see here](https://smittytone.net/utitool/index.html).

## Release Notes ##

- 1.2.0 *Unreleased*
    - Add `--list` and `--app` options to retrieve and display system-recorded information for, respectively, UTIs and apps.
    - Support machine- or human-readable output for the above commands, with the `--json` switch for the former.
- 1.1.0 *1 August 2025*
    - Add extra file information.
    - Add `--extension` option to show info about specified a file extension.
    - Add `--uti` option to show info about a specified UTI.
    - Add `--more` option to show extra UTI information about specified files.
- 1.0.4 *23 July 2021*
    - Add async signal safe ctrl-c trapping code.
- 1.0.3 *15 June 2021*
    - Add support for macOS 11 Big Sur’s `UTType` API.
- 1.0.2 *8 February 2021*
    - Minor change to help text.
- 1.0.1 *4 February 2021*
    - Tiny bit of refactoring.
- 1.0.0 *12 January 2021*
    - Initial public release.

## Licence ##

*utitool* is copyright © 2025, Tony Smith. Its source code is released under the MIT Licence.