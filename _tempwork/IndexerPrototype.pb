; ******************************************************************************
; *                                                                            *
; *                       PB CodeArchiv Rebirth Indexer                        *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "IndexerPrototype.pb" v.0.0.4 (2018/03/10) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Main code to test the comments-parser.
; ------------------------------------------------------------------------------
; This is a prototype of an indexing app for the PB CodeArchiv Rebirth project.
; Its purpose is to scan all PB source files and extract key-valu pairs from
; their header comments in order to index contents and create HTML pages to
; navigate the website. In the future, it might also be used to create a database
; to index and search resources by keywords and categories, from a dedicate app.
; ------------------------------------------------------------------------------

IncludeFile "comments_parser.pbi"

; SETTINGS
; ========
#SAMPLE_DATA_FOLDER$ = "test_files"

;{ Define Directory Separator according to OS
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #DSEP = "\"
CompilerElse
  #DSEP = "/"
CompilerEndIf ;}

; ******************************************************************************
; *                                    MAIN                                    *
; ******************************************************************************
#PROJ_ROOT = #PB_Compiler_FilePath

; =======================
; BUILD SOURCE FILES LIST
; =======================

NewList FilesL.s()
Define filename.s

Debug "Scanning '"+ #SAMPLE_DATA_FOLDER$ +"' folder for source files:"

;- Scan Sample-Data Folder
;  -----------------------
;  Currently, subfolders are not recursed into.

If ExamineDirectory(0, #SAMPLE_DATA_FOLDER$, "*.pb?")
  While NextDirectoryEntry(0)
    If DirectoryEntryType(0) = #PB_DirectoryEntry_File
      fName.s = DirectoryEntryName(0)
      fExt.s = GetExtensionPart(fName)
      
      If fExt = "pb" Or fExt = "pbi"
        AddElement(FilesL())
        fName.s = #SAMPLE_DATA_FOLDER$ + #DSEP + fName
        FilesL() = fName
        Debug " + Enlist: " + fName
      Else
        ; Ignore other PB extensions (*.pbp|*.pbf)
        Debug " - Ignore: " + fName
      EndIf
      
    EndIf
  Wend
  FinishDirectory(0)
EndIf

Debug ~"\nDone.\nTotal files: " + Str(ListSize(FilesL()))
SaveDebugOutput(#PROJ_ROOT+"report.log")

; ==================
; PARSE SOURCE FILES
; ==================

ForEach FilesL()
  
  ClearDebugOutput()

  Debug LSet("", 80, "=")
  Debug "PARSE: " + FilesL()
  ParseFile(FilesL())
  
  SaveDebugOutput(#PROJ_ROOT + FilesL() + ".log")

Next

