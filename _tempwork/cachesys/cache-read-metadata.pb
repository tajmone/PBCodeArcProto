; ******************************************************************************
; *                                                                            *
; *                  Test Reading from Cache Structured Data                   *
; *                                                                            *
; ******************************************************************************
; Since a resource metadata is just a list of key-val string pairs, the simplest
; way to cache it to write a series of strings to file.
; ------------------------------------------------------------------------------

; Define Structures and Vars
; ==========================
Structure KeyValPair
  key.s
  val.s
EndStructure

NewList Metadata.KeyValPair()

Define.s Key, Value


; Retrive List from Cache File
; ============================

If Not OpenFile(0, "cached", #PB_UTF8) ; (UTF-8 is default anyway)
  MessageRequester("ERROR!", "Couldn't open file.", #PB_MessageRequester_Error)
  End 1
EndIf

While Not Eof(0)
  AddElement( Metadata() )
  Metadata()\key = ReadString(0)
  Metadata()\val = ReadString(0)
Wend

CloseFile(0)

; Debug List Contents
; ===================
Debug "Here are the key-val contents of the structured list reconstructed from cache:" + #LF$

ForEach Metadata()
  Debug "'"+ Metadata()\key +"' : '"+ Metadata()\val +"'"
Next