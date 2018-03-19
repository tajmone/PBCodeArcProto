; ******************************************************************************
; *                                                                            *
; *                             HTML Pages Creator                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "HTMLPagesCreator.pb" v.0.0.1 (2018/03/19) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Scans the project's files and folders and automatically generates HTML5 pages
; for browsing the project online (via GitHub Pages website) or offline.
; An "index.html" is built for each category, using the folder's "README.md"
; as introduction text, and a resume card is built for each resource in the
; category (via header comments parsing)
; ------------------------------------------------------------------------------
;{ CHANGELOG
;  =========
;  v.0.0.1 (2018/03/19)
;    - Incorporate "BuildProjectTree.pb" and adapt it.
;    - Introduce DebugLevel filtering of output
;}
; ==============================================================================
;-                                   SETTINGS                                   
; ==============================================================================
DebugLevel 0 ; Details Range 0—4:
             ;  - 0 : No extra info, just the basic feedback.
             ;  - 1 : (currently unused) 
             ;  - 2 : (currently unused) 
             ;  - 3 : Expose core procedure's internals: their steps, positive
             ;        findings and results.
             ;  - 4 : Also expose core procedure's ingnored details (misses,
             ;        skipped/ignored items, etc.)

#CodeInfoFile = "CodeInfo.txt" ; found in multi-file subfoldered resources

; ==============================================================================
;-                                    SETUP                                     
;{==============================================================================
; Cross Platform Settings
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #DSEP = "\"     ; Directory Separator Character
  #EOL = #CRLF$   ; End-Of-Line Sequence
CompilerElse
  #DSEP = "/"
  #EOL = #LF$
CompilerEndIf

;- Procedures Declaration

; Misc Constants and Vars
#TOT_STEPS = "1"

#DIV1$ = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#DIV2$ = "=============================================================================="
#DIV3$ = "------------------------------------------------------------------------------"

Macro StepHeading(StepNum, Text)
  Debug #DIV2$ + #EOL + "STEP "+Str(StepNum)+"/"+#TOT_STEPS+" -- "+Text+ #EOL + #DIV2$
EndMacro
;}==============================================================================
;-                                  INITIALIZE                                  
; ==============================================================================
Debug #DIV1$ + #EOL + "HTMLPagesCreator" + #EOL + #DIV1$

SetCurrentDirectory("../")

Debug "Current Work Directory: " + GetCurrentDirectory(), 1
;}==============================================================================
;                                      MAIN                                     
;{==============================================================================

; ==============================================================================
;- 1. Build Categories List
; ==============================================================================
; Build a list of all the project's categories and their associated resources.
; ------------------------------------------------------------------------------
StepHeading(1, "Build Categories List")
Debug "Scanning project to build list of categories and resources:"

Structure Category
  Path.s
  List SubCategoriesL.s() ; Name/Link List to SubCategories
  List FilesToParseL.s()  ; List of files to parse (including "<subf>/CodeInfo.txt")
EndStructure

Declare ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")


NewList CategoriesL.Category()
AddElement( CategoriesL() )
CategoriesL()\Path = "" ; Root folder

totCategories = 0 ; Total Categories count (Root excluded)
totResources = 0  ; Total Resources count
totSubFRes = 0    ; Total subfolder Resources  count

ScanFolder(CategoriesL())

Debug "- Categories found: "+ Str(totCategories) + " (excluding root folder)"
Debug "- Resources found: "+ Str(totResources) + " ("+ Str(totSubFRes) +" are subfolders)"

ShowVariableViewer()

Repeat
  ; Infinte Loop to allow Debugger Inspections
ForEver

End

;}==============================================================================
;                                   PROCEDURES                                  
;{==============================================================================

Procedure ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
  ; ------------------------------------------------------------------------------
  ; Recursively scan project folders and build the List of Categories.
  ; ------------------------------------------------------------------------------
  Static recCnt ; recursion level counter
  recCnt +1
  
  Shared totCategories, totResources, totSubFRes
  
  Debug LSet("", recCnt, ">") + " ScanFolder(): '" + PathSuffix + "'", 3
  
  If ExamineDirectory(recCnt, PathSuffix, "")
    While NextDirectoryEntry(recCnt)
      
      entryName.s = DirectoryEntryName(recCnt)
      
      If DirectoryEntryType(recCnt) = #PB_DirectoryEntry_File
        fExt.s = GetExtensionPart(entryName)
        
        If fExt = "pb" Or fExt = "pbi"
          AddElement( CategoriesL()\FilesToParseL() )
          CategoriesL()\FilesToParseL() = entryName ; relative path
          totResources +1
          Debug " + Enlist: " + PathSuffix + entryName, 3
        Else
          ; Ignore other PB extensions (*.pbp|*.pbf)
          Debug " - Ignore: " + PathSuffix + entryName, 4
        EndIf
        
      Else ; EntryType is Directory
        
        ; Folder-Ignore patterns
        If entryName = "." Or entryName = ".." Or 
           entryName = ".git" Or
           Left(entryName, 1) = "_"
          
          Debug "(skipping '" + entryName +"')", 4
          Continue 
        EndIf
        
        If FileSize(PathSuffix + entryName + "/" + #CodeInfoFile) >= 0
          ;  ================================          
          ;- SubFolder is Multi-File Sub-Item
          ;  ================================
          AddElement( CategoriesL()\FilesToParseL() )
          fName.s = entryName + "/" + #CodeInfoFile ; relative path
          CategoriesL()\FilesToParseL() = fName
          totResources +1
          totSubFRes +1
          Debug " + Enlist: " + fName, 3
        Else
          ;  =========================
          ;- SubFolder is Sub-Category
          ;  =========================
          Debug "Folder '"+ PathSuffix + entryName + "' is a category", 4
          AddElement( CategoriesL()\SubCategoriesL() )
          CategoriesL()\SubCategoriesL() = entryName ; just the folder name
          totCategories +1
          
          ; Recurse into Sub-Category
          ; -------------------------
          PushListPosition( CategoriesL() )
          AddElement( CategoriesL() )
          CategoriesL()\Path = PathSuffix + entryName
          ScanFolder(CategoriesL(), PathSuffix + entryName + "/")
          PopListPosition( CategoriesL() )
        EndIf
      EndIf
      
    Wend
    FinishDirectory(recCnt)
  EndIf
  
  Debug LSet("", recCnt, "<") + " ScanFolder(): '" + PathSuffix + "'", 4
  recCnt -1
  
EndProcedure

;}