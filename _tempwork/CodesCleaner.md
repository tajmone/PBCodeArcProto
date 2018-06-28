# Codes Cleaner Tool

- [`CodesCleaner.pb`][Cleaner.pb]
- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesCleaner.pb


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Tool Info](#tool-info)
    - [Clean Operations](#clean-operations)

<!-- /MarkdownTOC -->

-----

# Tool Info

```purebasic
;   Description: A PB tool that helps in cleaning codes from the CodeArchive
;        Author: Sicro
;          Date: 2017-06-04
;            OS: Windows, Linux, Mac
; English-Forum: Not in the forum
;  French-Forum: Not in the forum
;  German-Forum: Not in the forum
; -----------------------------------------------------------------------------
```

## Clean Operations

The CodesCleaner performs a single action:

- Remove any settings at the end of source file

The way it does it is by copying the source file to a temporary file, line by line, until the line "`; IDE Options = PureBasic`" is found — in this case, the temporary file replaces the original file.



[Checker.pb]: ./CodesChecker.pb
[Cleaner.pb]: ./CodesCleaner.pb
