---
MISSINGtitle: ERRORS FOLDER
---

# TEST FOLDER

This is folder is for testing errors and warnings handling. It will produce a variety of errors.

# Pandoc Errors

See source file:

- [`Error.hs`](https://github.com/jgm/pandoc/blob/master/src/Text/Pandoc/Error.hs)

## Pandoc Warning

To test warnings, you can redefine twice a reference link:

``` markdown
[foo]

[foo]: bar

[foo]: baz
```

[foo]

[foo]: foo1

[foo]: foo2


[bar]

[bar]: bar1

[bar]: bar2

## Pandoc Error

Need to find a way to raise error from within markdown document.