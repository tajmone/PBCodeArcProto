; URL 2 LINK TESTS: Test that URLs are correctly parsed and converted into links-
; Only URLs that are the sole content of value (ie: a single line that is a URL)
; are converted to HTML links; URLs inside text are ignored.
; -----------------------------------------------------------------------------
;:   Description: This multiline description contains an URL in brackets
;.            (http://www.purebasic.fr/english/viewtopic.php?p=404657#p404657).
;.            The previous URL will not be rendered to a link.
;.
;.            URL1 (below) will be ocnverted to link, URL2 and URL3 not --- the
;.            former because of the text following the URL, the latter because
;.            it's a multiline value (even though each line is just a URL, there
;.            are newline characters, as well as an empty line).
;:  URL1: http://www.purebasic.fr/english/viewtopic.php?p=404657#p404657
;:  URL2: http://www.purebasic.fr/english/viewtopic.php?p=404657#p404657 (not a link)
;:  URL3:
;.       http://www.purebasic.fr/english/viewtopic.php?p=666
;.
;.       http://www.purebasic.fr/english/viewtopic.php?p=123
; -----------------------------------------------------------------------------

For i=1 To 10
  Debug i
Next
