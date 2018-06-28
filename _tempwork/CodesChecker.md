# Codes Checker Tool

- [`CodesChecker.pb`][Checker.pb]
- https://github.com/Seven365/PureBasic-CodeArchiv-Rebirth/blob/repo-dev/CodesChecker.pb


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Tool Info](#tool-info)
    - [Check Operations](#check-operations)
- [Some Considerations](#some-considerations)
    - [Compiler checks](#compiler-checks)

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
    
        If the filename doesn't contain any OS reference, than it's assumed to be for all OSs, otherwise it must contain a ref to the currently running OS.

- Check for errors in the resource headers ("`*.pb`", "`*.pbi`", "`CodeInfo.txt`"):

    + check that a code header-comments block is present

    + check that the values for the following keys are present:

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


# Some Considerations

Some personal comments on how this (old) tools works, and potential limitations/issues, in order to reason how it should behave in its updated version:

## Compiler checks


+ Some subfoldered resources might contain multiple PB source/inc files, the tool has no way to know which is the main file in this case. The tools simply skips this check on `CodeInfo.txt` resources.
+ Code resources for other OSs are just ignored by this tool; but should the new version always run the PB Compiler check syntax? (see [Issue #10] for a discussion on this)

[Issue #10]: https://github.com/tajmone/PBCodeArcProto/issues/10#issuecomment-386054821

[Checker.pb]: ./CodesChecker.pb
[Cleaner.pb]: ./CodesCleaner.pb

