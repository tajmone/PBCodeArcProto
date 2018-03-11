; MULTILINE ENTRIES TEST: This header block contains carry-on values that span
; across multiple lines.
; -----------------------------------------------------------------------------
;:   Description: A long description spanning across multiple lines.
;.                Carry on value: the dot indicates this line extends the value
;.                of the current key being parsed.
;.
;.                Every line is trimmed of leading and traling whitespace, and
;.                joined with the previous line -- a space separator is added
;.                between the joined lines, unless the previous line was empy.
;.
;.                Therefore, this line and the next one
;.                will be merged a single paragraph.
;.
;.                Empty lines are rendered as a double EOL sequence, to separate
;.                paragraphs.
;.
;.                   Because leading spaces are ignored, even if this line is
;.                   indentented by 2 spaces more than the rest, in the final
;.                   string should be just a plain paragraph.
;
;: carry-on 2: 1st line.
;.    2nd line (carry on).
;.    3rd line (carry on).
;:            OS: Mac
;: Value starting on carry-on:
;.     In this key-value pair the value string starts on the carry-on lines.
;.     Usually this is done to preserve text wrapping in long descriptions, or
;.     to make the text more readable.
;.
;.     The parser will not add an empty line at the start of this value.
; -----------------------------------------------------------------------------
;: English-Forum: http://www.purebasic.fr/english/viewtopic.php?p=404657#p404657
;:  French-Forum: 
;:  German-Forum: 
; -----------------------------------------------------------------------------

For i=1 To 10
  Debug i
Next
