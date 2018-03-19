# Temporary Dev Folder

This folder contains parts of code and template work/test files that are being developed independently before insertion into the main app.

# Folder Structure

- [`/test_files/`](./test_files) — PB source files with header-blocks designed to test comments parsing and edge cases.
- [`/template/`](./template) — tests for building the final HTML5 template.
- [`IndexerPrototype.pb`](./IndexerPrototype.pb) — Main file.
- [`comments_parser.pbi`](./comments_parser.pbi) — The comments parser.
- [`erase-logs.bat`](./erase-logs.bat) — Delets all log files.


# Usage and Testing

Open `IndexerPrototype.pb` and Run it with debugger.

For each source being parsed, the contents of the debug output window will be saved to disk as `<filename>.log`, and then the output window is cleared. The debug output is used as a means to quickly create individual file logs.


With each run, the code will create  "`report.log`" in the project's root, listing all resource files that were enlisted or skipped from the "`test_files`" folder. For each source file in "`test_files`" folder, a log file named `<filename>.log` will be created, with details of how the comment parsing steps and the `<key>:<value>` found.

To quickly delete all the generated log files, use "`erase-logs.bat`".
