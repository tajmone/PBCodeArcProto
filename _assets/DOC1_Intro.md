# HTMLPagesCreator: Introduction

Documentation on the __HTMLPagesCreator__ app works.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="true" lowercase_only_ascii="true" uri_encoding="true" depth="3" -->

- [Introduction](#introduction)

<!-- /MarkdownTOC -->

-----


# Introduction

The goal is to write an app that can generate/update the HTML pages to create a website for __PureBasic-CodeArchiv-Rebirth__ via GitHub Pages project's website. Since the PB CodeArchive repo hosts various PureBasic resources — either single files or as a folder with multiple files — written by various authors, the goal is achievable via an application that parses the header-comments blocks found at the beginning of the PB source files and extracts a series of `<key>:<value>` pairs which can then be manipulated to generate an HTML resume-card for each resource, and then created a single `index.html` page for each folder in the project, containing the resume-cards of all the resources of that folder.

Currently, all source files already contain a commented header block with all the relevant info. Here is an example taken from the `DriveSystem/GetDriveFreeSpaceSize[Win,Lin].pbi` file:

```purebasic
;   Description: Adds support to get the free space size of drives
;            OS: Windows, Linux
; English-Forum: http://www.purebasic.fr/english/viewtopic.php?p=466070#p466070
;  French-Forum: 
;  German-Forum: http://www.purebasic.fr/german/viewtopic.php?p=278150#p278150
```

The idea is to implement a parsing system that can extract this info with very little modifications to current headers.

The details on how the comments parser works are documented in:

- [`DOC2_Comments_Parsing`](./DOC2_Comments_Parsing)
