;   Description: A PB tool that helps in cleaning codes from the CodeArchive
;        Author: Sicro
;          Date: 2017-06-04
;            OS: Windows, Linux, Mac
; English-Forum: Not in the forum
;  French-Forum: Not in the forum
;  German-Forum: Not in the forum
; -----------------------------------------------------------------------------

; MIT License
; 
; Copyright (c) 2017-2018 Sicro [github.com/SicroAtGit/PureBasic-CodeArchiv-Rebirth]
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

CompilerIf Not #PB_Compiler_Debugger
  CompilerError "Activate the debugger and run the code only inside the PB-IDE"
CompilerEndIf

EnableExplicit

Procedure AddFiles(Path$, FileExtensions$, List Files$())
  
  Protected Slash$, EntryName$, FileExtension$
  Protected Directory
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Slash$ = "\"
  CompilerElse ; Linux, Mac
    Slash$ = "/"
  CompilerEndIf
  
  If Right(Path$, 1) <> Slash$
    Path$ + Slash$
  EndIf
  
  FileExtensions$ = RemoveString(FileExtensions$, " ")
  FileExtensions$ = "," + FileExtensions$ + ","
  
  Directory = ExamineDirectory(#PB_Any, Path$, "")
  If Directory
    
    While NextDirectoryEntry(Directory)
      EntryName$ = DirectoryEntryName(Directory)
      Select DirectoryEntryType(Directory)
        Case #PB_DirectoryEntry_File
          FileExtension$ = GetExtensionPart(EntryName$)
          If FileExtension$ = ""
            FileExtension$ = " "
          EndIf
          If FileExtensions$ <> "" And FindString(FileExtensions$, "," + FileExtension$ + ",", 1, #PB_String_NoCase) = 0
            Continue
          EndIf
          If AddElement(Files$())
            Files$() = Path$ + EntryName$
          EndIf
        Case #PB_DirectoryEntry_Directory
          Select EntryName$
            Case ".", ".."
            Default
              AddFiles(Path$ + EntryName$, FileExtensions$, Files$())
          EndSelect
      EndSelect
    Wend
    
    FinishDirectory(Directory)
  EndIf
  
EndProcedure

Procedure.i IsStringStartsWith(String$, StartsWithString$)
  
  ProcedureReturn Bool(Left(String$, Len(StartsWithString$)) = StartsWithString$)
  
EndProcedure

Procedure RemovePBSettings(CodeFile$)
  
  Protected Result, File, NewFile, StringFormat
  Protected ContentLine$
  
  Result = #True
  
  File = ReadFile(#PB_Any, CodeFile$)
  If Not File : ProcedureReturn : EndIf
  
  NewFile = CreateFile(#PB_Any, CodeFile$ + ".new")
  If Not NewFile
    CloseFile(File)
    ProcedureReturn #False
  EndIf
  
  ; Iterate though all lines of the file content and at them to the new file until PB settings are found
  StringFormat = ReadStringFormat(File)
  WriteStringFormat(NewFile, StringFormat)
  While Not Eof(File)
    ContentLine$ = ReadString(File, StringFormat)
    If IsStringStartsWith(ContentLine$, "; IDE Options = PureBasic")
      Result = 2 ; File has been cleaned
      Break
    EndIf
    WriteStringN(NewFile, ContentLine$, StringFormat)
  Wend
  CloseFile(File)
  CloseFile(NewFile)
  
  ; Replace the old file with the new file
  If Result = 2 And Not RenameFile(CodeFile$ + ".new", CodeFile$)
    Result = #False
  EndIf
  
  DeleteFile(CodeFile$ + ".new")
  
  ProcedureReturn Result
  
EndProcedure

Define Path$ = PathRequester("Open PureBasic-CodeArchiv-Rebirth", "")
If FileSize(Path$) <> -2
  Debug "Invalid path"
  End
EndIf

NewList Files$()
AddFiles(Path$, "pb,pbi", Files$())

ForEach Files$()
  Select RemovePBSettings(Files$())
    Case 2      : Debug "Cleaned: " + Files$()
    Case #True  ; Code is already clean
    Case #False : Debug "Error: " + Files$()
  EndSelect
Next

Debug "All done"
