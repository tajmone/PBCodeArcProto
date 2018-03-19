# HTMLPagesCreator

    Pre-alpha drafting stage

__HTMLPagesCreator__ is going to be a website generator for the __[PureBasic CodeArchiv Rebirth]__ project.

Based on the original discussion with [@SicroAtGit] in [Issue #5].

-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="true" lowercase_only_ascii="true" uri_encoding="true" depth="3" -->

- [Files List](#files-list)
- [Project Status](#project-status)
    - [WIP TODOs](#wip-todos)
        - [HTML Template](#html-template)
        - [Project Tree Scanner](#project-tree-scanner)
        - [Comments Parser](#comments-parser)
    - [Comments Parsing Features](#comments-parsing-features)

<!-- /MarkdownTOC -->

-----

# Files List

Documentation of __HTMLPagesCreator__ features and workings (drafts and notes):

- [`DOC1_Intro.md`](./DOC1_Intro.md)
- [`DOC2_Comments_Parsing.md`](./DOC2_Comments_Parsing.md)

PB source files:

- [`BuildProjectTree.pb`](./BuildProjectTree.pb) — project-scanner prototype
- [`HTMLPagesCreator.pb`](./HTMLPagesCreator.pb) — the actual app (prototype code is integrated here when ready)


# Project Status

Here is a mixture of the TODOs list and what has been currently implemented. Since it's still an early draft, the list will change often.

## WIP TODOs

Currently the project's code is split in different source being built independently, which will be joined into a single program later on, when they are fully functional.

### HTML Template

- [`../_tempwork/template/`](../_tempwork/template/)

In this folder there are some tests and prototypes for the HTML5 template that will be used to render the project's webpages.

### Project Tree Scanner

- `BuildProjectTree.pb`

The project tree scanner is run agains the `real_files` folder, which contains a selection of real categories taken from the upstream project.


- [x] Scans the projects folders recursively
- [x] build list of categories (not a Tree, just a list).
- [x] ignore folders from scan:
    + [x] "`.`" and "`..`"
    + [x] "`.git`"
    + [x] folders whose name starts with "`_`"
- [x] establish if a subfolder is a category or a multifile sub-item (check if it contains a "`CodeInfo.txt`" file)
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







[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth "Visit the 'PureBasic CodeArchiv Rebirth' repository"

[Issue #5]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth/issues/5

[@SicroAtGit]: https://github.com/SicroAtGit "View @SicroAtGit's GitHub profile"
[@tajmone]: https://github.com/tajmone "View @tajmone's GitHub profile"
