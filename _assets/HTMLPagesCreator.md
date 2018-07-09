# HTMLPagesCreator: Introduction

Documentation on how the __HTMLPagesCreator__ app works.


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

The details on how the header comments system and how its parser works are documented in:

- [`DOC_Header_Comments.md`](./DOC_Header_Comments.md)

# Sections Metadata

Pandoc will extract metadata for the final HTML doc from:

- [`_assets/meta.yaml`](./meta.yaml) (global)
- `**/README.md` — YAML headers in each Category README file

The file `_assets/meta.yaml` defines the core variables needed by the html5 pandoc template (eg: Header title, etc.) plus default values for metadata. Any metadata defined in the YAML headers of a `README.md` will override the default values of `meta.yaml`.

Some metadata entries don't have a default value and should/must be defined in each README file:

- `title` (_mandatory_)

## Category Title

The `title` will be used for the doc title in the browser tab (`<title>` tag) by combining it with the `title-sufffix` (defined in `meta.yaml`):

```html
<title>$title$ | $title-sufffix$</title>
```

Example:

```html
<title>Home | PureBasic CodeArchiv Rebirth</title>
```

If a category's `README.md` doesn't define a `title`, pandoc will raise a warning. We didn't provide a default value for `title` because we want a warning to inform the user about the need to provide a title for the category.

## Category Metadata

Each category should define in the YAML headers of its `README.md` file the following variables:

- `description` — (for SEO) `<head><meta name="description" ...>`
- `keywords` — (for SEO) `<head><meta name="keywords" ...>`

