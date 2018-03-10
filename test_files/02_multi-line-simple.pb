; MULTILINE ENTRIES TEST: This header block contains carry-on values that span
; across multiple lines.
; -----------------------------------------------------------------------------
;:   Description: A long description spanning across multiple lines.
;.                Carry on value: the dot indicates this line extends the value of
;.                the current key being parsed.
;.
;.                Indentation will be stripped by using the first carry-on line's
;.                indents as a base reference value.
;.
;.                  Therefore, this line should be indentented by 2 spaces.
;
;: carry-on 2: 1st line.
;.    2nd line (carry on).
;.    3rd line (carry on).
;:            OS: Mac
;: Value starting on carry-on:
;.     In this key-value pair the value string starts on the carry-on lines.
;.     Usually this is done to preserve text wrapping in long descriptions.
;.     The parser will not add an empty line at the start of this value.
; -----------------------------------------------------------------------------
;: English-Forum: http://www.purebasic.fr/english/viewtopic.php?p=404657#p404657
;:  French-Forum: 
;:  German-Forum: 
; -----------------------------------------------------------------------------

For i=1 To 10
  Debug i
Next
