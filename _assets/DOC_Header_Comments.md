# HTMLPagesCreator: Comment Parsing

Documentation on the header-comments system used in CodeArchiv resource files for storing information that will be parsed by the __HTMLPagesCreator__ app (and by other maintainers/contributors tools).


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="true" lowercase_only_ascii="true" uri_encoding="true" depth="3" -->

- [Premise](#premise)
- [Comments Parsing Design](#comments-parsing-design)
    - [Carry-On Multi-Line Values](#carry-on-multi-line-values)
    - [URL Value Strings](#url-value-strings)
    - [Comments Folding Support](#comments-folding-support)
- [Resume...](#resume)

<!-- /MarkdownTOC -->

-----


# Premise

My consideration were that the system shoud have the following characteristics:

- Existing comment headers should require very little changes (single chars additions that can be handled via RegEx search-&-replace)
- The added char(s) must not be visually intrusive and compromise human readibility of the header by distracting the eye.
- The pasring system should be:
    + simple
    + fast
    + tollerant of textual variations (aliasing)
    + extensible via simple settings files (JSON or the like)

# Comments Parsing Design

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

The parser itself is going to be "dumb", and just make a list of strings out of them (duplicates allowed).

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

... this allows some flexibility, and to have same-width text in the source headers, which looks cleaner in the IDE.

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

# Resume...

So, resuming: 

- we'll be only adding a `:` or a `.` to the comment delimiter of the lines which are meaningful to the parser; this is going to be easy also on the code maintainers.
- We'll be extracing a list of `<key>:<value>` string pairs from each resource
- The app will then create a resume card for the resource, using the extracted list of `<key>:<value>` string pairs — the app won't interpret them, it will just format and use them, in their order of appearance.



