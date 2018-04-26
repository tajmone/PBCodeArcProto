# Codes Checker Tool

- [`CodesChecker.pb`][Checker.pb]
- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesChecker.pb


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Tool Info](#tool-info)
    - [Check Operations](#check-operations)
    - [Unclear Points](#unclear-points)

<!-- /MarkdownTOC -->

-----

# Tool Info

```purebasic
;   Description: A PB tool that helps to check codes from the CodeArchive
;        Author: Sicro
;          Date: 2017-08-02
;            OS: Windows, Linux, Mac
; English-Forum: Not in the forum
;  French-Forum: Not in the forum
;  German-Forum: Not in the forum
; -----------------------------------------------------------------------------
```

## Check Operations

(_trying to work out what it does by looking at the source file, so the list might not reflect the exact workings of the tool_)

The CodesChecker performs the following actions:

- Check code syntax via the compiler syntax checker (`--check --thread`):
    + Ignore code files that don't support the running OS — this is checked by scanning file name via RegEx that looks for presence of:
        * `\[.*Win.*\]`
        * `\[.*Lin.*\]`
        * `\[.*Mac.*\]`
- Check for errors in the resource headers ("`*.pb`", "`*.pbi`", "`CodeInfo.txt`"):
    + check that a code header-comments block is present
    + check that the following keys are present:
        * `Author`
        * `Date`
        * `Description`
        * `English-Forum`
        * `French-Forum`
        * `German-Forum`
        * `OS`
    + check well-formedness of values for the following keys:
        * `Date` » `^\d{4}-\d{2}-\d{2}$` (= `YEAR-MM-DD`)

- If resource is an include file ("`*.pbi`"):
    + Check for presence of `CompilerIf #PB_Compiler_IsMainFile` block

## Unclear Points

I haven't worked out how the current tool behaves in some circumstances, and at the same time I'm asking here how it should behave in its updated version:

- Compiler checks:
    + How are `CodeInfo.txt` resources handled? The tool has no way to know which is the main file in this case.
    + How are code resources for other OSs checked? Are they just ignored?
- Code headers:
    + Is the order of the required key entries relevant? (or, should it be so?)
    + Can extra custom keys be inserted between the required keys, as long as they don't affect their relative order?
    + Should the required-keys checks allow empty values?
        * Obviously, some keys are differnt from others: `Author` looks like it should always have a value, but others like the Forum keys are likely to be empty.




[Checker.pb]: ./CodesChecker.pb
[Cleaner.pb]: ./CodesCleaner.pb

