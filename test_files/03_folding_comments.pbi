; -----------------------------------------------------------------------------
;:   Description: A long description spanning across multiple lines.
;.                Carry on value: the dot indicates this line extends the value of
;.                the current key being parsed.
;.
;{.               This line has folding marks: ";{.". The parser should handle it
;.                smartly nonetheless, and preserver indentation.
;.
;}.               Folding ends here.
;:   Description2:
;{.    This carry on block has a folding mark on its first line, which could mess
;.     up the base indentantion level.
;.
;}.    Folding ends here.
;: Fold on 1st Carry-On Sinlge Spaced:
;{. This carry on block has a folding mark on its first line, and a single space
;.  indentation, which could mess up the base indentantion level.
;.
;}. Folding ends here.
;: Fold on Mid Carry-On Sinlge Spaced:
;.  This carry on block has a folding mark on its 2nd line, and a single space
;.{ indentation, which could mess up the base indentantion level.
;.
;}. Folding ends here.
; -----------------------------------------------------------------------------

For i=1 To 10
  Debug i
Next
