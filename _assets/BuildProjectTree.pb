; ******************************************************************************
; *                                                                            *
; *                             Build Project Tree                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "BuildProjectTree.pb" v.0.0.3 (2018/03/19) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Build the project Tree of categories, sub-categories and sub-foldered items
; ------------------------------------------------------------------------------
;{ CHANGELOG
;  =========
;  v.0.0.3 (2018/03/19)
;    - Ignore folders: ".git" or if first name char is underscore.
;    - Always use "/" as dir separator char (works with all OSs and is the
;      correct separator to use for HTML links)
;  v.0.0.2 (2018/03/14)
;}
#CodeInfoFile = "CodeInfo.txt"

Structure Category
  Path.s
  List SubCategoriesL.s() ; Name/Link List to SubCategories
  List FilesToParseL.s()  ; List of files to parse (including "<subf>/CodeInfo.txt")
EndStructure

Declare ScanFolder(List ProjTreeL.Category(), PathSuffix.s = "")

;{ Define Directory Separator according to OS
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #DSEP = "\"
CompilerElse
  #DSEP = "/"
CompilerEndIf ;}

; ==============================================================================
;                                   INITIALIZE                                  
; ==============================================================================

SetCurrentDirectory("../")

Debug "Curr Dir: " + GetCurrentDirectory()

NewList ProjTreeL.Category()
AddElement( ProjTreeL() )
ProjTreeL()\Path = "" ; Root folder

; ==============================================================================
;                                      MAIN                                     
; ==============================================================================

ScanFolder(ProjTreeL())

ShowVariableViewer()

Repeat
  ; Infinte Loop to allow Debugger Inspections
ForEver

End

; ==============================================================================
;                                   procedures                                  
; ==============================================================================

Procedure ScanFolder(List ProjTreeL.Category(), PathSuffix.s = "")
  Static recCnt ; recursion level counter
  recCnt +1
  
  
  Debug LSet("", recCnt, ">") + " ScanFolder(): '" + PathSuffix + "'"
  
  If ExamineDirectory(recCnt, PathSuffix, "")
    While NextDirectoryEntry(recCnt)
      
      entryName.s = DirectoryEntryName(recCnt)
      
      If DirectoryEntryType(recCnt) = #PB_DirectoryEntry_File
        fName.s = PathSuffix + entryName
        fExt.s = GetExtensionPart(entryName)
        
        If fExt = "pb" Or fExt = "pbi"
          AddElement( ProjTreeL()\FilesToParseL() )
          ProjTreeL()\FilesToParseL() = fName
          Debug " + Enlist: " + fName
        Else
          ; Ignore other PB extensions (*.pbp|*.pbf)
          Debug " - Ignore: " + fName
        EndIf
        
      Else ; EntryType is Directory
        
        ; Folder-Ignore patterns
        If entryName = "." Or entryName = ".." Or 
           entryName = ".git" Or
           Left(entryName, 1) = "_"
          
          Debug "(skipping '" + entryName +"')"
          Continue 
        EndIf
        
        If FileSize(PathSuffix + entryName + "/" + #CodeInfoFile) >= 0
          ;  ================================          
          ;- SubFolder is Multi-File Sub-Item
          ;  ================================
          AddElement( ProjTreeL()\FilesToParseL() )
          fName.s = PathSuffix + entryName + "/" + #CodeInfoFile
          ProjTreeL()\FilesToParseL() = fName
          Debug " + Enlist: " + fName
        Else
          ;  =========================
          ;- SubFolder is Sub-Category
          ;  =========================
          Debug "Folder '"+ PathSuffix + entryName + "' is a category"
          AddElement( ProjTreeL()\SubCategoriesL() )
          ProjTreeL()\SubCategoriesL() = PathSuffix + entryName
          ; Recurse into Sub-Category
          PushListPosition( ProjTreeL() )
          AddElement( ProjTreeL() )
          ProjTreeL()\Path = PathSuffix + entryName
          ScanFolder(ProjTreeL(), PathSuffix + entryName + "/")
          PopListPosition( ProjTreeL() )
        EndIf
      EndIf
      
    Wend
    FinishDirectory(recCnt)
  EndIf
  
  Debug LSet("", recCnt, "<") + " ScanFolder(): '" + PathSuffix + "'"
  recCnt -1
  
EndProcedure
