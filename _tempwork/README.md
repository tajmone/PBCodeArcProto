# Temporary Dev Folder

This folder contains parts of code and template work/test files that are being developed independently before insertion into the main app.

# Folder Contents

## Test Files

- [`/test_files/`](./test_files) — PB source files with header-blocks designed to test comments parsing and edge cases.
- [`/template/`](./template) — tests for building the final HTML5 template.
- [`erase-logs.bat`](./erase-logs.bat) — Delets all log files.

Currently there aren't any more prototypes for testing here.

## Old Tools

- [`CodesChecker.pb`][CodesChecker]
- [`CodesCleaner.pb`][CodesCleaner]

These two tools were taken from the [`repo-dev` branch][repo-dev] of the original [PureBasic-CodeArchiv-Rebirth] project:

- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesCleaner.pb
- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesChecker.pb

The idea is to update both tools and try to integrate them into the current one to create a single check and update app for the project.

For more info, see the following Issue comments:

- https://github.com/tajmone/PBCodeArcProto/issues/9#issuecomment-378416297
- https://github.com/tajmone/PBCodeArcProto/issues/8#issuecomment-381436841


# Usage and Testing

No test-codes available right now.



[CodesChecker]: ./CodesChecker.pb
[CodesCleaner]: ./CodesCleaner.pb

[repo-dev]: https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/

[PureBasic-CodeArchiv-Rebirth]: https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth
