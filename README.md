---
title: Home
---

# PBCodeArcProto

    Pre-alpha drafting stage

- https://github.com/tajmone/PBCodeArcProto

Temporary prototype dev repo for a website generator for the __[PureBasic CodeArchiv Rebirth]__ project. Will be destroyed once the Indexer is ready and integrated into the parent project.

Based on the original discussion with [@SicroAtGit] in [Issue #5].

Project organization:

- [`/_assets/`](./_assets) — the actual __HTMLPagesCreator__ code + HTML assets
- [`/_tempwork/`](./_tempwork) — isolated code work
- [`/_morgue/`](./_morgue) — left-over temp code

the remaining folders are contents taken from the PureBasic CodeArchiv Rebirth project to test the app.



# License Info

This is a temporary project, there isn't a single license governing it as a whole. Third party resources herein contained (wether for testing purposes or as dependencies to the code I'm writing) are bound by their specific license, so make sure to check the source file headers and/or for the presence of a license file in each subfolder.

## Third Party Resources

This project contains code from various sources, each governed by their own license terms which can be found in the source files commente headers, or in a license files inside the folder hosting the resource(s).

### Bulma

- https://bulma.io/
- https://github.com/jgthms/bulma

The prototype I'm working on in this project uses the Bulma CSS framework, by Jeremy Thomas, released under MIT License.

```
The MIT License (MIT)

Copyright (c) 2018 Jeremy Thomas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## Tristano's Contributions

As a generale guideline, code written for this project by Tristano is to be considered as MIT Licensed:

```
MIT License

Copyright (c) 2018 Tristano Ajmone <tajmone@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

So any source file in this project bearing a `by Tristano Ajmone` in its source is to be considered MIT licensed, unless another license is expressily specified.

At the current stage it's impossible for me to determine if MIT will be the  final license for this project — ultimately, the final license will depend on the licenses of third party resources employed. As third party resources are added to the project, their license is also added. So, the current license terms of my code contributions might be subject to change if I end up using third party code which is MIT incompatible.

Because this is an experimental prototype, I didn't initally put too much emphasis on licensing; but as my dear collaborator @SicroAtGit has pointed out, it's time for me to put order in this project's licensing terms since it's starting to include more third party resource and opening up to third party contributions too.

My final goal is to release under a permissive license any code and/resources I'll have contributed toward creating an application for building a website for the [PureBasic CodeArchiv Rebirth] project. I want to share it, and that other might reuse it too.

You're free to clone this project, edit it, test and experiment with it, but if you wish to reuse or distribute any parts of it, please check the license of every single resource and contact their authors if in doubt.



[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth "Visit the 'PureBasic CodeArchiv Rebirth' repository"

[Issue #5]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth/issues/5

[@SicroAtGit]: https://github.com/SicroAtGit "View @SicroAtGit's GitHub profile"
[@tajmone]: https://github.com/tajmone "View @tajmone's GitHub profile"
