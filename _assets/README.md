# The Assets Folder

The `/_assets/` folder contains:

- [Website assets] (CSS, etc)
- [Assets for building the website] (templates, metadata files, etc)
- [Maintainers/contributors apps]:
    + [Website builder] (__HTMLPagesCreator__)
    + Resources validation tools

[Website assets]: #website-assets
[Assets for building the website]: #website-creation-resources
[Website builder]: #htmlpagescreator
[Maintainers/contributors apps]: #apps-and-tools

-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Files List](#files-list)
    - [Apps and Tools](#apps-and-tools)
        - [Doxter, A PureBasic Docs Generator](#doxter-a-purebasic-docs-generator)
    - [Documentation](#documentation)
    - [Web and HTML Docs Assets](#web-and-html-docs-assets)
    - [Website Creation Resources](#website-creation-resources)
- [The CodeArchiv Website](#the-codearchiv-website)
    - [HTMLPagesCreator](#htmlpagescreator)

<!-- /MarkdownTOC -->

-----


# Files List

## Apps and Tools

PB source files:

- [`/pb-inc/`](./pb-inc) — modules shared by the various tools.
- [`HTMLPagesCreator.pb`](./HTMLPagesCreator.pb) — the website builder app (prototype code is integrated here when ready)
- [`CheckResources.pb`](./CheckResources.pb) — an app to validate all resources (similar to the old [`CodesChecker`][CodesChecker] app)

[CodesChecker]: ../_tempwork/CodesChecker.md "Read about the 'CodesChecker' app"

### Doxter, A PureBasic Docs Generator

- [`Doxter.html`](./Doxter.html) — Documentation ([Live HTML Preview][Doxter LiveHTML])
- [`Doxter.pb`](./Doxter.pb)

The new tool __Doxter__, created for this project, allows to maintain documentation inside the source code, and then parse the source and produce an AsciiDoc document.

The auto-generated ADocs will be subdivided in tagged regions, therefore every document (including documents independent from source files) can import regions from the auto-generate doc of every module and source file, and when Doxter updates their doc files, every document in the project will be automatically updated.

This will grante a documentation that is always on par with the source code(s) it refers to.

[Doxter LiveHTML]: http://htmlpreview.github.io/?https://github.com/tajmone/PBCodeArcProto/blob/master/_assets/Doxter.html "Live HTML Preview of Doxter Documentation"

## Documentation

- [`/dev-docs_src/`](./dev-docs_src) — AsciiDoc documentation sources and build scripts.
- [`/pb-inc/`](./pb-inc):
    + [`MODULARIZATION_NOTES.asciidoc`][MODULARZ adoc] ([__html__][MODULARZ live]) — notes and TODOs on the modularization of code shared by the various tools.
- [`DOC_Header_Comments.md`](./DOC_Header_Comments.md) — explains the system used to store info in the resources' comments.
- [`HTMLPagesCreator.md`](./HTMLPagesCreator.md) — an overview of the website creation app.

[MODULARZ adoc]: ./pb-inc/MODULARIZATION_NOTES.asciidoc
[MODULARZ live]: https://tajmone.github.io/PBCodeArcProto/_assets/pb-inc/MODULARIZATION_NOTES "Live HTML Preview"

## Web and HTML Docs Assets

Current assets for HTML pages and documentation:

- [`/hjs/`](./hjs) — modded [Highlight.js] release for syntax highlighting PureBasic.
- [`bulma.css`](./bulma.css) — created with [Bulma CSS framework].
- [`custom.css`](./custom.css) — custom tweaks.

These files are temporary; later on a proper Sass project will be added to build _ad hoc_ stylesheets.

## Website Creation Resources

- [`meta.yaml`](./meta.yaml) — global metadata settings.
- [`template.html5`](./template.html5) — pandoc template (based on [HTML5 Boilerplate]).


-------------------------------------------------------------------------------

# The CodeArchiv Website

Based on the original discussion with [@SicroAtGit] in [Issue #5].

The generated CodeArchiv HTML pages are intended for both the online website (via GitHub Pages) as well as for offline navigation of local clones of the CodeArchiv. 


## HTMLPagesCreator

__HTMLPagesCreator__ is going to be the website generator for the __[PureBasic CodeArchiv Rebirth]__ project. It's a static website generator that leverages pandoc to build an HTML5 website from markdown source files and auto-generated HTML code from scanning the projects' structure and resources.





<!-----------------------------------------------------------------------------
                               REFERENCE LINKS                                
------------------------------------------------------------------------------>

[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth "Visit the 'PureBasic CodeArchiv Rebirth' repository"

[Issue #5]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth/issues/5

[@SicroAtGit]: https://github.com/SicroAtGit "View @SicroAtGit's GitHub profile"
[@tajmone]: https://github.com/tajmone "View @tajmone's GitHub profile"

[Bulma CSS framework]: https://bulma.io/ "Visit Bulma CSS framework website"

[HTML5 Boilerplate]: https://html5boilerplate.com/ "Visit HTML5 Boilerplate website"

[Highlight.js]:https://highlightjs.org 

<!-- Project Files -->

<!-- EOF -->
