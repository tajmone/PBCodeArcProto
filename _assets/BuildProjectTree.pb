; ******************************************************************************
; *                                                                            *
; *                             Build Project Tree                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "BuildProjectTree.pb" v.0.0.2 (2018/03/14) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Build the project Tree of categories, sub-categories and sub-foldered items
; ------------------------------------------------------------------------------

#PROJ_ROOT_REL_PATH = "real_files"
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

SetCurrentDirectory(#PROJ_ROOT_REL_PATH)

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
        If entryName = "." Or entryName = ".."
          Debug "(skipping '" + entryName +"')"
          Continue 
        EndIf
        
        If FileSize(PathSuffix + entryName + #CodeInfoFile) >= 0
          ;  ================================          
          ;- SubFolder is Multi-File Sub-Item
          ;  ================================
          AddElement( ProjTreeL()\FilesToParseL() )
          fName.s = PathSuffix + entryName + #DSEP + #CodeInfoFile
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
          ScanFolder(ProjTreeL(), PathSuffix + entryName + #DSEP)
          PopListPosition( ProjTreeL() )
        EndIf
      EndIf
      
    Wend
    FinishDirectory(recCnt)
  EndIf
  
  Debug LSet("", recCnt, "<") + " ScanFolder(): '" + PathSuffix + "'"
  recCnt -1
  
EndProcedure
