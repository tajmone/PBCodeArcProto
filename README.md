# PBCodeArcProto

    Pre-alpha drafting stage

- https://github.com/tajmone/PBCodeArcProto

Temporary dev repo for an Indexer prototype for the __[PureBasic CodeArchiv Rebirth]__ project. Will be destroyed once the Indexer is ready and integrated into the parent project.

Based on the original discussion with [@SicroAtGit] in [Issue #5].

-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="true" lowercase_only_ascii="true" uri_encoding="true" depth="3" -->

- [Introduction](#introduction)
- [Suggested Approach \(Draft\)](#suggested-approach-draft)
    - [Premise](#premise)
    - [Design Proposal](#design-proposal)
- [Project Status](#project-status)
    - [WIP TODOs](#wip-todos)
    - [Comments Parsing Features](#comments-parsing-features)
- [Project Structure](#project-structure)
- [Usage and Testing](#usage-and-testing)
- [License Info](#license-info)

<!-- /MarkdownTOC -->

-----

# Introduction

The goal is to write an app that can generate/update the HTML pages to create a website for __PureBasic-CodeArchiv-Rebirth__ via GitHub Pages project's website. Since the PB CodeArchive repo hosts various PureBasic resources — either single files or as a folder with multiple files — written by various authors, the goal is achievable via an _Indexer_ application that parses the header-comments blocks found at the beginning of the PB source files and extracts a series of `<key>:<value>` pairs which can then be manipulated to generate an HTML resume-card for each resource, and then created a single `index.html` page for each folder in the project, containing the resume-cards of all the resources of that folder.

Currently, all source files already contain a commented header block with all the relevant info. Here is an example taken from the `DriveSystem/GetDriveFreeSpaceSize[Win,Lin].pbi` file:

```purebasic
;   Description: Adds support to get the free space size of drives
;            OS: Windows, Linux
; English-Forum: http://www.purebasic.fr/english/viewtopic.php?p=466070#p466070
;  French-Forum: 
;  German-Forum: http://www.purebasic.fr/german/viewtopic.php?p=278150#p278150
```

The idea is to implement a parsing system that can extract this info with very little modifications to current headers.

# Suggested Approach (Draft)

## Premise

My consideration were that the system shoud have the following characteristics:

- Existing comment headers should require very little changes (single chars additions that can be handled via RegEx search-&-replace)
- The added char(s) must not be visually intrusive and compromise human readibility of the header by distracting the eye.
- The pasring system should be:
    + simple
    + fast
    + tollerant of textual variations (aliasing)
    + extensible via simple settings files (JSON or the like)

## Design Proposal

This is the proposed design, based on the original discussion on [Issue #5].

The app's parsing goal is to focus only on the block of comments found at the beginning of the file:

- The comments block parsing ends when the firs non-comment line is encountered

It's reasonable to expect all the data we need to be in that block, as it is customary in such header comments.

The parser extracts `<key>:<value>` string pairs from comment lines that start with the `;: ` delimiter:

```purebasic
;:            OS: Windows, Linux, Mac
;: English-Forum: http://www.purebasic.fr/english/viewtopic.php?
;:  French-Forum: 
;:  German-Forum: http://www.purebasic.fr/german/viewtopic.php?
; -----------------------------------------------------------------------------

```

The `;:` combination is pleasant to the eye: the colon is similar to the semicolon, so it goes almost unnoticed, and because it tends to form a vertical line with the other colon below, it doesn't disturb reading.

The parse will extract from the above examples the following `<key>:<value>` pairs (leading and trailing whitespace is stripped):

- `OS`:`Windows, Linux, Mac`
- `English-Forum`: `http://www.purebasic.fr/english/viewtopic.php?`
- `French-Forum`: (empty)
- `German-Forum`: `http://www.purebasic.fr/german/viewtopic.php?`

The parser itself is going to be "dumb", and just make a list of strings out of them (duplicates allowed). After parsing, the app will convert all keys to identifiers (ascii conversion, lowercase, spaces to underscore) and look up the identifiers in a Map (definable via a settings file) to determine if a key is of interest for building the resume or not (in the latter case, just discards it).

This approach allows to easily integrate new keys into the sytem via settings file. Also, the map allows aliases to map to the same significant key, which might be useful in some cases.

For long `<value>` entries that span across multiple lines, a carry-on comment delimiter `;.` will be used. After parsing a key-value pair, the parser will always check if the next line starts by `;.`, and if it does it will carry on parsing the following lines until a non-carry-on comment is encountered (or the end of the block). Example:


```purebasic
;:   Description: A very long descriptive text of what this piece of code
;.                does and doesn't do. It keeps going on for serverl lines,
;.                This is the last line.
;:            OS: Windows, Linux, Mac
;: English-Forum: http://www.purebasic.fr/english/viewtopic.php?
;:  French-Forum: 
;:  German-Forum: http://www.purebasic.fr/german/viewtopic.php?
; -----------------------------------------------------------------------------

```

Again, the dot of the `;.` delimiter is non-ivasive and blends well with the colon and semicolons. Also, both `:` and `.` are easy to remember (as the `:` is also used as a separator after the actual key).

In carry-on values, whitespace will be trimmed differently: the indententtion of the first carry-on line becomes the base indentation that will be stripped off from the rest of the following lines, so that any intended indentation will be preserved in the final block of text.

When using carry-on values, the value might actually start on the second line altogether:

```purebasic
;: Description:
;.    A very long descriptive text of what this piece of code
;.    does and doesn't do. It keeps going on for serverl lines,
;.    This is the last line.
```

... this allows some flexibility, and to have same-width text in the extracted text (most likely, the description text will be rendered as an HTML `<pre>` block, since it often contains significant spacing, ascii lists, etc.).

Finally, our special comment delimiters should allow the __special comment marks__ used for folding by PB IDE (`{ }`), as some users might add the folding marks to allow shrinking away the header block:

```purebasic
;{: Description:
;.    A very long descriptive text of what this piece of code
;.    does and doesn't do. It keeps going on for serverl lines,
;}.   This is the last line.
```

The `-` mark is not expected to be found in this context (and, unlike the folding mark, it would brake due to the adjacent `:` anyhow).

So, resuming: 

- we'll be only adding a `:` or a `.` to the comment delimiter of the lines which are meaningful to the parser; this is going to be easy also on the code maintainers.
- We'll be extracing `<key>:<value>` string pairs, which will be then looked up in a Map that allows aliases and slight text variations, so that the app can establish which key is what. (for example, `created_by` could be an alias of `author`; French and German translation could map to English, etc.)
- The entires of the Map used to correlate found keys to variables which are meaningful for the creation of the cards can be changed and extended via a simple settings file.
- The app will then further manipulate the value strings according to what they are used for (dates, OS names, authors lists, etc), using dedicated code for each specific key — some values might need manipulation (dates, version numbers, etc.), others not, depending if we need to the data to make decisions on it or if we just need to pass it on as is.

For example, a key like `OS` should be smart to understand not only "`OS: Windows, Linux, Mac`" but also `all`, `macOS`, `OSX`, `XP`, etc. But these details will be handled once there is some working code.

What do you think of this approach? Is it going to be simple enough on the coders side, and flexible enough for the project maintainers?

# Project Status

Here is a mixture of the TODOs list and what has been currently implemented. Since it's still an early draft, the list will change often.

## WIP TODOs

- [x] create a resource files list from all "`*.pb`" and "`*.pbi`" files inside "`test_files`" folder.
- [ ] implement recursive folder scanning
- [x] iterate through the list of files and for each file invoke `ParseFile(file.s)`:
    + [x] extract header-comments block — via `ExtractHeaderBlock(file.s, List CommentsL.s())`
    + [x] parse the Header Block and extract raw `<key>:<value>` pairs and store them in a structured list — via `ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())`
    + [x] log parsing details to `<filename>.log` to debug the parser's inner workings.
    + [ ] map raw keys to actual variables used by the Indexer.
    + [ ] create an HTML resume card for each resource.

## Comments Parsing Features

- [x] single line `<key>:<value>` pairs extraction. Syntax:

    `;: [space]<key>[space]:[space]<value>[space]`

    ... where `[space]` allows optional spaces that will be trimmed off.

- [x] multiline entries where `<value>` carries on multiple lines:

    `;. [indentation]<value carry-on>`

    + [x] left-indentation of first carry-on line sets the base indentation that will be removed from all following carry-on lines (of current key-val pair). Allows preserving intended indentantion.
    
    + [x] `<value>` definition starting on carry-on line: allows an empty value on the `;: <key>` line, so that `<value>` definition begins on carry-on lines. In this case don't add initial empty `<value>` string, to avoid empty line.

- [x] Allow folding marks in comment delimiters, without breaking indentation on multi-line carry-on values:
    + [x] `;{:`
    + [x] `;}:`
    + [x] `;{.`
    + [x] `;}.`

# Project Structure

- [`/test_files/`](./test_files) — PB source files with header-blocks designed to test comments parsing and edge cases.
- [`IndexerPrototype.pb`](./IndexerPrototype.pb) — Main file.
- [`comments_parser.pbi`](./comments_parser.pbi) — The comments parser.
- [`erase-logs.bat`](./erase-logs.bat) — Delets all log files.


# Usage and Testing

Open `IndexerPrototype.pb` and Run it with debugger.

For each source being parsed, the contents of the debug output window will be saved to disk as `<filename>.log`, and then the output window is cleared. The debug output is used as a means to quickly create individual file logs.


With each run, the code will create  "`report.log`" in the project's root, listing all resource files that were enlisted or skipped from the "`test_files`" folder. For each source file in "`test_files`" folder, a log file named `<filename>.log` will be created, with details of how the comment parsing steps and the `<key>:<value>` found.

To quickly delete all the generated log files, use "`erase-logs.bat`".

# License Info

    Copyright (c) Tristano Ajmone, 2018.

At the current stage it's impossible to determine any type of license for this project — much depends on whether or not we'll end up using third party resources.

You're free to clone this project, edit it, test and experiment with it, but if you wish to reuse or distribute any parts of it, please contact the author or wait until a license is chosen for the project.







[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth "Visit the 'PureBasic CodeArchiv Rebirth' repository"

[Issue #5]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth/issues/5

[@SicroAtGit]: https://github.com/SicroAtGit "View @SicroAtGit's GitHub profile"
[@tajmone]: https://github.com/tajmone "View @tajmone's GitHub profile"
