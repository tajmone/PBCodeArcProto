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
    - [Carry-On Multi-Line Values](#carry-on-multi-line-values)
    - [URL Value Strings](#url-value-strings)
    - [Comments Folding Support](#comments-folding-support)
    - [Resume...](#resume)
- [Project Status](#project-status)
    - [WIP TODOs](#wip-todos)
        - [HTML Template](#html-template)
        - [Project Tree Scanner](#project-tree-scanner)
        - [Comments Parser](#comments-parser)
    - [Comments Parsing Features](#comments-parsing-features)
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

The parser itself is going to be "dumb", and just make a list of strings out of them (duplicates allowed). ~~After parsing, the app will convert all keys to identifiers (ascii conversion, lowercase, spaces to underscore) and look up the identifiers in a Map (definable via a settings file) to determine if a key is of interest for building the resume or not (in the latter case, just discards it)~~.

The extracted list of  `<key>:<value>` pairs will simply be converted to an HTML card, without the app caring what they might refer to. No maps are needed.

## Carry-On Multi-Line Values

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

## URL Value Strings

If an extracted value string contains a valid URL (and nothing else), it will be converted to an HTML link. This is intended to capture links to PB Forum references, or projects websites, as in:

```purebasic
;: English-Forum: http://www.purebasic.fr/english/viewtopic.php?
```

URLs that occur in the middle of other text are no converted to links. Here we're only concerned with reference links regarding the project of the current resume card.

## Comments Folding Support

Finally, our special comment delimiters should allow the __special comment marks__ used for folding by PB IDE (`{ }`), as some users might add the folding marks to allow shrinking away the header block:

```purebasic
;{: Description:
;.    A very long descriptive text of what this piece of code
;.    does and doesn't do. It keeps going on for serverl lines,
;}.   This is the last line.
```

The `-` mark is not expected to be found in this context (and, unlike the folding mark, it would brake due to the adjacent `:` anyhow).

## Resume...

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

Currently the project's code is split in different source being built independently, which will be joined into a single program later on, when they are fully functional.

### HTML Template

- `/Template/`

In this folder there are some tests and prototypes for the HTML5 template that will be used to render the project's webpages.

### Project Tree Scanner

- `BuildProjectTree.pb`

The project tree scanner is run agains the `real_files` folder, which contains a selection of real categories taken from the upstream project.


- [x] Scans the projects folders recursively
- [x] build list of categories (not a Tree, just a list).
- [x] establish if a subfolder is a category or a multifile sub-item
- [x] build list of files to comment-parse:
    + [x] all "`*.pb`" and "`*.pbi`" files
    + [x] "`CodeInfo.txt`" files in multi-file folder sub-items

... when comments-parser is ready, join them and carry on task:

- [ ] for each category build the HTML page:
    + [ ] build sidebar menu with root categories and links (relative to curr subfolder)
    + [ ] build breadcrumbs
    + [ ] PAGE CONTENTS:
        * [ ] convert category `README.md` to HTML and store in memory
        * [ ] create links to sub-categories (if any) and append to temp HTML
        * [ ] comment-parse all files in category and create HTML resume card, and append to in-memory temp HTML

### Comments Parser

- `../_tempwork/IndexerPrototype.pb`
- `../_tempwork/comments_parser.pbi`

Currently the comments parser is being developed and run against the custom test files found in the `test_files` folder.


- [x] create a resource files list from all "`*.pb`" and "`*.pbi`" files inside "`test_files`" folder.
- [ ] implement recursive folder scanning
- [x] iterate through the list of files and for each file invoke `ParseFile(file.s)`:
    + [x] extract header-comments block — via `ExtractHeaderBlock(file.s, List CommentsL.s())`
    + [x] parse the Header Block and extract raw `<key>:<value>` pairs and store them in a structured list — via `ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())`
    + [x] log parsing details to `<filename>.log` to debug the parser's inner workings.
    + [ ] ~~map raw keys to actual variables used by the Indexer~~.
    + [x] create an HTML resume card for each resource.

## Comments Parsing Features

- [x] single line `<key>:<value>` pairs extraction. Syntax:

    `;: [space]<key>[space]:[space]<value>[space]`

    ... where `[space]` allows optional spaces that will be trimmed off.

- [x] multiline entries where `<value>` carries on multiple lines:

    `;. [space]<value carry-on>[space]`

    + [x] any leading and trailing space is stripped off and the carry-on line is joined with the previous one (space inserted if previous line was not empty).
    + [x] Empty carry-on lines are rendered as double EOL.
    
    + [x] `<value>` definition starting on carry-on line: allows an empty value on the `;: <key>` line, so that `<value>` definition begins on carry-on lines. In this case don't add initial empty `<value>` string, to avoid empty line.

- [x] Allow folding marks in comment delimiters, without breaking indentation on multi-line carry-on values:
    + [x] `;{:`
    + [x] `;}:`
    + [x] `;{.`
    + [x] `;}.`


# License Info

    Copyright (c) Tristano Ajmone, 2018.

At the current stage it's impossible to determine any type of license for this project — much depends on whether or not we'll end up using third party resources.

You're free to clone this project, edit it, test and experiment with it, but if you wish to reuse or distribute any parts of it, please contact the author or wait until a license is chosen for the project.







[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth "Visit the 'PureBasic CodeArchiv Rebirth' repository"

[Issue #5]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth/issues/5

[@SicroAtGit]: https://github.com/SicroAtGit "View @SicroAtGit's GitHub profile"
[@tajmone]: https://github.com/tajmone "View @tajmone's GitHub profile"
