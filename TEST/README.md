---
MISSINGtitle: TEST FOLDER
---

# TEST FOLDER

This is just a test folder for testing errors and warnings handling.

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

[foo]: bar

[foo]: baz

## Pandoc Error

Need to find a way to raise error from within markdown document.