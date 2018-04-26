# Temporary Dev Folder

This folder contains parts of code and template work/test files that are being developed independently before insertion into the main app.

# Folder Contents

## Test Files

- [`/test_files/`](./test_files) — PB source files with header-blocks designed to test comments parsing and edge cases.
- [`/template/`](./template) — tests for building the final HTML5 template.
- [`erase-logs.bat`](./erase-logs.bat) — Delets all log files.

Currently there aren't any more prototypes for testing here.

## Old Tools

- [`CodesChecker.pb`][CodesChecker] » [`CodesChecker.md`][Checker.md`] (analysis doc)
- [`CodesCleaner.pb`][CodesCleaner] » [`CodesCleaner.md`][Cleaner.md`] (analysis doc)

These two tools were taken from the [`repo-dev` branch][repo-dev] of the original [PureBasic-CodeArchiv-Rebirth] project:

- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesCleaner.pb
- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesChecker.pb

The idea is to update both tools and try to integrate them into the current one to create a single check and update app for the project.

For more info, see their associated markdown docs and the following Issue:

- [Issue #10 — Integrating The Old Tools]

... and the side comments at following Issue:

- [Issue #8]
- [Issue #9]




# Usage and Testing

No test-codes available right now.



[CodesChecker]: ./CodesChecker.pb
[CodesCleaner]: ./CodesCleaner.pb
[Checker.md`]: ./CodesChecker.md "Read the doc for 'CodesChecker.pb'"
[Cleaner.md`]: ./CodesCleaner.md "Read the doc for 'CodesCleaner.pb'"

[repo-dev]: https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/

[PureBasic-CodeArchiv-Rebirth]: https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth

[Issue #10 — Integrating The Old Tools]: https://github.com/tajmone/PBCodeArcProto/issues/10
[Issue #9]: https://github.com/tajmone/PBCodeArcProto/issues/9#issuecomment-378416297
[Issue #8]: https://github.com/tajmone/PBCodeArcProto/issues/8#issuecomment-381436841

