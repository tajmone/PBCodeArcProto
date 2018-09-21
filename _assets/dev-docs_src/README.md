# AsciiDoc Sources of CodeArchiv Dev-Docs

This folder contains the AsciiDoc source files and scripts to build the __PB CodeArchiv__ _Developers' Documentation_.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [About the Docs](#about-the-docs)
- [Doxter, A PureBasic Docs Generator](#doxter-a-purebasic-docs-generator)
    - [Doxter Migration Grace Period](#doxter-migration-grace-period)
- [AsciiDoc File Extensions Conventions](#asciidoc-file-extensions-conventions)
- [Bulding the Docs](#bulding-the-docs)
    - [System Requirements](#system-requirements)
- [AsciiDoc References](#asciidoc-references)
    - [Working With Split Documents](#working-with-split-documents)
    - [Including Source Code in Documents](#including-source-code-in-documents)

<!-- /MarkdownTOC -->

-----

# About the Docs

As the assets, tools and modules are starting to grow in number and size, we need to keep a well organized documentation to track their development and to document their usage.

The AsciiDoc format is a better choice for the task, and [Asciidoctor]  (Ruby) the ideal tool to handle it. Among the added benefits over markdown there is the possibility to directly include code snippets from the source files (by using comments in the file to set inclusion reference marks). This would allow to easily quote parts of the PureBasic source files directly in the documentation, and the documentation will always show the code as it is in the latest PB files.

Furthermore, AsciiDoc can import (even conditionally) into the document other AsciiDoc files, which allows to keep documentation sources into independent files in different folders, and keep the ADoc file of a given source module next to it, as well as to reuse the same contents files in multiple documents.

Because of the last point mentioned, the documents in this folder will import some ADoc files stored elsewhere in the project.

# Doxter, A PureBasic Docs Generator

- [`Doxter.html`](../Doxter.html) — Documentation ([Live HTML Preview][Doxter LiveHTML])

The new tool __Doxter__, created for this project, allows to maintain documentation inside the source code, and then parse the source and produce an AsciiDoc document.

The auto-generated ADocs will be subdivided in tagged regions, therefore every document (including documents independent from source files) can import regions from the auto-generate doc of every module and source file, and when Doxter updates their doc files, every document in the project will be automatically updated.

This will grante a documentation that is always on par with the source code(s) it refers to.

[Doxter LiveHTML]: http://htmlpreview.github.io/?https://github.com/tajmone/PBCodeArcProto/blob/master/_assets/Doxter.html "Live HTML Preview of Doxter Documentation"

## Doxter Migration Grace Period

Currently, the PB sources in the `/_assets/` folder tree still need to be readapted to employ __Doxter__. They are currently being documented in external AsciDoc files; we need to copy the relevant parts of the documentation directly in their source files, so that from thereon source code and its documentation will be bundled together and be always up to date.

Until all source files are ported to the new system, we'll have to endure a period of grace, in which scripts that update documentation will have to selectively choose which PB source to process with Doxter.

For more details, see:

- [`BUILD-DOCS.bat`](./BUILD-DOCS.bat)


# AsciiDoc File Extensions Conventions

For convenience, we'll adopt different file extensions for AsciiDoc files, according to their role:

- "`.asciidoc`" — A main document file that will be converted into HTML.
- "`.adoc`" — either:
    + A partial document that gets imported into a main doc,
    + A repository documentation file (e.g., a README file), intended for preview in GitHub (i.e., an alternative to using markdown).

This provides not only visual hints to quickly distinguish a main document from a partial one, but it's also required in automation scripts to find main documents to build based on their extension.

# Bulding the Docs

Use the shell scripts in this folder:

- [`BUILD-DOCS.bat`](./BUILD-DOCS.bat)


## System Requirements

In order to build (convert to HTML) these docs you'll need the following tools/apps on your system:

- [Ruby]
- [Asciidoctor][Asciidoctor GitHub]  (Ruby gem)

To install Ruby on Windows OS, you can use the [RubyInstaller], also available as a [Chocolatey package][Chocolatey Ruby].


-------------------------------------------------------------------------------

# AsciiDoc References

- [AsciiDoc Syntax Quick Reference]
- [AsciiDoc Recommended Practices]
- [Asciidoctor User Manual]

## Working With Split Documents

- [28. Include Directive]
    + [28.3. File resolution]
    + [28.4. Partitioning large documents and using leveloffset]
    + [28.6. Select Portions of a Document to Include]
        * [28.6.1. By tagged regions]
        * [28.6.2. Tag filtering]
        * [28.6.3. By line ranges]

## Including Source Code in Documents

- [46. Syntax Highlighting Source Code]: https://asciidoctor.org/docs/user-manual/#source-code-blocks


<!-----------------------------------------------------------------------------
                               REFERENCE LINKS                                
------------------------------------------------------------------------------>

[Asciidoctor]: https://asciidoctor.org/ "Visit Asciidoctor website"

[Asciidoctor GitHub]: https://github.com/asciidoctor/asciidoctor "Visit Asciidoctor repository on GitHub"

[Ruby]: https://www.ruby-lang.org
[RubyInstaller]: https://rubyinstaller.org/
[Chocolatey Ruby]: https://chocolatey.org/packages/ruby

<!-- AsciiDoc Docs and Guides -->

[AsciiDoc Recommended Practices]: https://asciidoctor.org/docs/asciidoc-recommended-practices/
[AsciiDoc Syntax Quick Reference]: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/

<!-- AsciiDoctor User Manual  -->

[Asciidoctor User Manual]: https://asciidoctor.org/docs/user-manual/

[28. Include Directive]: https://asciidoctor.org/docs/user-manual/#include-directive
[28.3. File resolution]: https://asciidoctor.org/docs/user-manual/#include-resolution
[28.4. Partitioning large documents and using leveloffset]: https://asciidoctor.org/docs/user-manual/#include-partitioning
[28.6. Select Portions of a Document to Include]: https://asciidoctor.org/docs/user-manual/#include-partial
[28.6.1. By tagged regions]: https://asciidoctor.org/docs/user-manual/#by-tagged-regions
[28.6.2. Tag filtering]: https://asciidoctor.org/docs/user-manual/#tag-filtering
[28.6.3. By line ranges]: https://asciidoctor.org/docs/user-manual/#by-line-ranges

[46. Syntax Highlighting Source Code]: https://asciidoctor.org/docs/user-manual/#source-code-blocks

<!-- EOF -->
