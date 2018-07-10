; ******************************************************************************
; *                                                                            *
; *                   Test Writing to Cache Structured Data                    *
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

; Populate List from DataSection
; ==============================

Repeat
  Read.s Key
  If Key = #Empty$ : Break : EndIf
  Read.s Value
  AddElement( Metadata() )
  Metadata()\key = Key
  Metadata()\val = Value
ForEver

; Debug List Contents
; ===================
ForEach Metadata()
  Debug "'"+ Metadata()\key +"' : '"+ Metadata()\val +"'"
Next

; Cache List to File
; ==================

If Not CreateFile(0, "cached", #PB_UTF8) ; (UTF-8 is default anyway)
  MessageRequester("ERROR!", "Couldn't create file.", #PB_MessageRequester_Error)
  End 1
EndIf

ForEach Metadata()
  WriteStringN(0, Metadata()\key )
  WriteStringN(0, Metadata()\val )
Next

CloseFile(0)

; ------------------------------------------------------------------------------

DataSection
  Data.s "Title",  "Structured Data Caching Test"
  Data.s "Author", "John Doe"
  Data.s "Date",   "2018-07-10"
  Data.s #Empty$
EndDataSection