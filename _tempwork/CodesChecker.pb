;   Description: A PB tool that helps to check codes from the CodeArchive
;        Author: Sicro
;          Date: 2017-08-02
;            OS: Windows, Linux, Mac
; English-Forum: Not in the forum
;  French-Forum: Not in the forum
;  German-Forum: Not in the forum
; -----------------------------------------------------------------------------

CompilerIf Not #PB_Compiler_Debugger
  CompilerError "Activate the debugger and run the code only inside the PB-IDE"
CompilerEndIf

EnableExplicit

Structure CodeHeaderInfos_Struc
  Description$
  Author$
  Date$
  OS$
  EnglishForum$
  FrenchForum$
  GermanForum$
EndStructure

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

Procedure$ GetCompilerErrors(CompilerPath$, CodePath$)
  
  Protected Result$, String$
  Protected Program
  
  Program = RunProgram(CompilerPath$, ~"--check --thread \"" + CodePath$ + ~"\"", GetPathPart(CodePath$), #PB_Program_Open | #PB_Program_Read)
  If Not Program : ProcedureReturn "" : EndIf
  
  While ProgramRunning(Program)
    If AvailableProgramOutput(Program)
      String$ = ReadProgramString(Program)
      If String$ <> ""
        Result$ + String$ + #CRLF$
      EndIf
    EndIf
  Wend
  
  CloseProgram(Program)
  ProcedureReturn Result$
  
EndProcedure

Procedure.i GetCodeHeaderInfos(CodePath$, *CodeHeaderInfos.CodeHeaderInfos_Struc)
  
  Protected File, StringFormat
  Protected String$
  
  With *CodeHeaderInfos
    \Author$       = ""
    \Date$         = ""
    \Description$  = ""
    \EnglishForum$ = ""
    \FrenchForum$  = ""
    \GermanForum$  = ""
    \OS$           = ""
  EndWith
  
  File = ReadFile(#PB_Any, CodePath$)
  If Not File : ProcedureReturn #False : EndIf
  
  StringFormat = ReadStringFormat(File)
  While Not Eof(File)
    String$ = ReadString(File, StringFormat)
    With *CodeHeaderInfos
      If Left(String$,                     Len(";   Description:")) = ";   Description:"
        \Description$ = Trim(Mid(String$,  Len(";   Description:") + 1))
      ElseIf Left(String$,                 Len(";        Author:")) = ";        Author:"
        \Author$ = Trim(Mid(String$,       Len(";        Author:") + 1))
      ElseIf Left(String$,                 Len(";          Date:")) = ";          Date:"
        \Date$ = Trim(Mid(String$,         Len(";          Date:") + 1))
      ElseIf Left(String$,                 Len(";            OS:")) = ";            OS:"
        \OS$ = Trim(Mid(String$,           Len(";            OS:") + 1))
      ElseIf Left(String$,                 Len("; English-Forum:")) = "; English-Forum:"
        \EnglishForum$ = Trim(Mid(String$, Len("; English-Forum:") + 1))
      ElseIf Left(String$,                 Len(";  French-Forum:")) = ";  French-Forum:"
        \FrenchForum$ = Trim(Mid(String$,  Len(";  French-Forum:") + 1))
      ElseIf Left(String$,                 Len(";  German-Forum:")) = ";  German-Forum:"
        \GermanForum$ = Trim(Mid(String$,  Len(";  German-Forum:") + 1))
      EndIf
    EndWith
  Wend
  CloseFile(File)
  
  ProcedureReturn #True
  
EndProcedure

Procedure.i ExistsCompilerMainFileCode(CodePath$)
  
  Protected File, StringFormat
  Protected FileContent$
  
  File = ReadFile(#PB_Any, CodePath$)
  If Not File : ProcedureReturn -1 : EndIf
  
  StringFormat = ReadStringFormat(File)
  FileContent$ = ReadString(File, StringFormat | #PB_File_IgnoreEOL)
      
  CloseFile(File)
  
  ProcedureReturn Bool(FindString(FileContent$, "CompilerIf #PB_Compiler_IsMainFile", 1, #PB_String_NoCase))
  
EndProcedure

Procedure.i RunStandardProgram(FilePath$)
  
  Protected Result
  
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
      Result = RunProgram(FilePath$)
    CompilerCase #PB_OS_Linux
      ; http://www.chabba.de/Linux/System/System_OpenWithStandardApp.pb
      Result = RunProgram("xdg-open", FilePath$, "")
      If Not Result
        Result = RunProgram("gnome-open", FilePath$, "")
      EndIf
  CompilerEndSelect
  
  ProcedureReturn Result
  
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Define CompilerPath$ = #PB_Compiler_Home + "Compilers\pbcompiler.exe"
CompilerElse ; Linux, Mac
  Define CompilerPath$ = #PB_Compiler_Home + "compilers/pbcompiler"
CompilerEndIf
Define CodesPath$ = PathRequester("Open archiv folder", "PureBasic-CodeArchiv")
Define RegEx_IsForRunningOS, RegEx_ExistsOSLimitations, RegEx_IsValidDateFormat
Define FileName$

Define CompilerErrors$
Define AllCompilerErrors$
Define CompilerErrorsFile$ = GetTemporaryDirectory() + "CompilerErrors.txt"

Define CodeHeaderInfos.CodeHeaderInfos_Struc

Define CodeHeaderErrors$
Define AllCodeHeaderErrors$
Define CodeHeaderErrorsFile$ = GetTemporaryDirectory() + "CodeHeaderErrors.txt"

Define AllFileNameErrors$
Define FileNameErrorsFile$ = GetTemporaryDirectory() + "FileNameErrors.txt"

Define NewList CodeFiles$()

If FileSize(CodesPath$) <> -2
  Debug "Code path is wrong"
  End
EndIf

Debug "Checking code archiv: " + CodesPath$

DeleteFile(CompilerErrorsFile$)
DeleteFile(CodeHeaderErrorsFile$)
DeleteFile(FileNameErrorsFile$)

CompilerSelect #PB_Compiler_OS
  CompilerCase #PB_OS_Windows: RegEx_IsForRunningOS = CreateRegularExpression(#PB_Any, "\[.*Win.*\]")
  CompilerCase #PB_OS_Linux:   RegEx_IsForRunningOS = CreateRegularExpression(#PB_Any, "\[.*Lin.*\]")
  CompilerCase #PB_OS_MacOS:   RegEx_IsForRunningOS = CreateRegularExpression(#PB_Any, "\[.*Mac.*\]")
CompilerEndSelect
RegEx_ExistsOSLimitations = CreateRegularExpression(#PB_Any, "\[.*(Win|Lin|Mac).*\]")
RegEx_IsValidDateFormat = CreateRegularExpression(#PB_Any, "^\d{4}-\d{2}-\d{2}$")
If Not RegEx_IsForRunningOS Or Not RegEx_ExistsOSLimitations Or Not RegEx_IsValidDateFormat
  Debug "RegEx can't created"
  End
EndIf

AddFiles(CodesPath$, "pb,pbi,txt", CodeFiles$())

ForEach CodeFiles$()
  
  ; Ignore txt files that don't match the filename "CodeInfo.txt"
  If GetExtensionPart(CodeFiles$()) = "txt" And GetFilePart(CodeFiles$(), #PB_FileSystem_NoExtension) <> "CodeInfo"
    Continue
  EndIf
  
  ; Ignore code files that don't support the running OS
  If Not MatchRegularExpression(RegEx_IsForRunningOS, CodeFiles$()) And MatchRegularExpression(RegEx_ExistsOSLimitations, CodeFiles$())
    Continue
  EndIf
  
  ; Check code syntax via the compiler syntax check function
  CompilerErrors$ = GetCompilerErrors(CompilerPath$, CodeFiles$())
  If Not FindString(CompilerErrors$, "Syntax check finished without error")
    If AllCompilerErrors$ <> ""
      AllCompilerErrors$ + #CRLF$ + "++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + #CRLF$ + #CRLF$
    EndIf
    AllCompilerErrors$ + "Check file: " + CodeFiles$() + #CRLF$ + CompilerErrors$
  EndIf
  
  ; Check for errors in the code headers
  If GetCodeHeaderInfos(CodeFiles$(), @CodeHeaderInfos)
    CodeHeaderErrors$ = ""
    With CodeHeaderInfos
      If (\Author$ + \Date$ + \Description$ + \EnglishForum$ + \FrenchForum$ + \GermanForum$ + \OS$) <> ""
        
        If \Author$ = ""
          CodeHeaderErrors$ = "- No author defined" + #CRLF$
        EndIf
        If \Date$ = ""
          CodeHeaderErrors$ = "- No date defined" + #CRLF$
        ElseIf Not MatchRegularExpression(RegEx_IsValidDateFormat, \Date$)
          CodeHeaderErrors$ = "- Wrong date format" + #CRLF$
        EndIf
        If \Description$ = ""
          CodeHeaderErrors$ = "- No description defined" + #CRLF$
        EndIf
        If \EnglishForum$ = "" And \FrenchForum$ = "" And \GermanForum$ = ""
          CodeHeaderErrors$ = "- No forum defined" + #CRLF$
        EndIf
        If \OS$ = ""
          CodeHeaderErrors$ = "- No operating system defined" + #CRLF$
        EndIf
        
      Else
        
        CodeHeaderErrors$ = "No code header found"
        
      EndIf
    EndWith
  Else
    CodeHeaderErrors$ = "Error: Can't open file" 
  EndIf
  
  If CodeHeaderErrors$ <> "" And CodeHeaderErrors$ <> "No code header found"
    If AllCodeHeaderErrors$ <> ""
      AllCodeHeaderErrors$ + #CRLF$ + "++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + #CRLF$ + #CRLF$
    EndIf
    AllCodeHeaderErrors$ + "Check file: " + CodeFiles$() + #CRLF$ + CodeHeaderErrors$
  EndIf
  
  ; Check for existing 'CompilerIf #PB_Compiler_IsMainFile' block on PBI files
  If LCase(GetExtensionPart(CodeFiles$())) = "pbi" And Not ExistsCompilerMainFileCode(CodeFiles$())
    If AllFileNameErrors$ <> ""
      AllFileNameErrors$ + #CRLF$ + #CRLF$ + "++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + #CRLF$ + #CRLF$
    EndIf
    AllFileNameErrors$ + "Check file: " + CodeFiles$() + #CRLF$ + "No 'CompilerIf #PB_Compiler_IsMainFile' found. Is file extension 'pbi' correct for this file?"
  EndIf
  
Next

If AllCompilerErrors$ And CreateFile(0, CompilerErrorsFile$)
  WriteStringFormat(0, #PB_UTF8)
  WriteStringN(0, AllCompilerErrors$)
  CloseFile(0)
  Debug "Created compiler errors file: " + CompilerErrorsFile$
  RunStandardProgram(CompilerErrorsFile$)
EndIf

If AllCodeHeaderErrors$ And CreateFile(0, CodeHeaderErrorsFile$)
  WriteStringFormat(0, #PB_UTF8)
  WriteStringN(0, AllCodeHeaderErrors$)
  CloseFile(0)
  Debug "Created code header errors file: " + CodeHeaderErrorsFile$
  RunStandardProgram(CodeHeaderErrorsFile$)
EndIf

If AllFileNameErrors$ And CreateFile(0, FileNameErrorsFile$)
  WriteStringFormat(0, #PB_UTF8)
  WriteStringN(0, AllFileNameErrors$)
  CloseFile(0)
  Debug "Created file name errors file: " + FileNameErrorsFile$
  RunStandardProgram(FileNameErrorsFile$)
EndIf

Debug "All done"