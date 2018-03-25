; ******************************************************************************
; *                                                                            *
; *                             HTML Pages Creator                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "HTMLPagesCreator.pb" v.0.0.5 (2018/03/25) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Scans the project's files and folders and automatically generates HTML5 pages
; for browsing the project online (via GitHub Pages website) or offline.
; An "index.html" is built for each category, using the folder's "README.md"
; as introduction text, and a resume card is built for each resource in the
; category (via header comments parsing)
; ------------------------------------------------------------------------------
;{ CHANGELOG
;  =========
;  v.0.0.5 (2018/03/25)
;    - Add PandocConvert() procedure (from STDIN gfm to "index.html")
;    - Now an "index.html" page is created for each Category:
;        - "README.md" file used in content
;        - relative paths to assests (CSS) correctly handled
;    - Implemented first usable darft of "template.html" (breadcrumbs and sidebar
;      currently show sample contents only)
;  v.0.0.4 (2018/03/21)
;    - Add project integrity checks
;  v.0.0.3 (2018/03/21)
;    - Add CategoriesL()\Name.s to structure
;    - CategoriesL()\Path ends in "/" (unless root)
;    - Setup Categories iteration code-skeleton
;  v.0.0.2 (2018/03/19)
;    - ScanFolder() Debug now shown as directory tree:
;      - DBG Lev 3: Show only found Categories and Resources
;      - DBG Lev 4: Also show ignored files and folders 
;  v.0.0.1 (2018/03/19)
;    - Incorporate "BuildProjectTree.pb" and adapt it.
;    - Introduce DebugLevel filtering of output
;}
; ==============================================================================
;-                                   SETTINGS                                   
; ==============================================================================
#DBG_LEVEL = 2  ; Details Range 0—4:
                ;  - 0 : No extra info, just the basic feedback.
                ;  - 1 : (currently unused) 
                ;  - 2 : Extra details on Main code 
                ;  - 3 : Expose core procedure's internals: their steps, positive
                ;        findings and results.
                ;  - 4 : Also expose core procedure's ingnored details (misses,
                ;        skipped/ignored items, etc.)
DebugLevel #DBG_LEVEL

#CodeInfoFile = "CodeInfo.txt" ; found in multi-file subfoldered resources
#HTML5_TEMPLATE = "template.html5" ; pandoc template

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

#DIV1$ = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#DIV2$ = "=============================================================================="
#DIV3$ = "------------------------------------------------------------------------------"

#TOT_STEPS = "3"
Macro StepHeading(Text)
  StepNum +1
  Debug #DIV2$ + #EOL + "STEP "+Str(StepNum)+"/"+#TOT_STEPS+" | "+Text+ #EOL + #DIV2$
EndMacro
;}==============================================================================
;-                                  INITIALIZE                                  
;{==============================================================================
Debug #DIV1$ + #EOL + "HTMLPagesCreator" + #EOL + #DIV1$

ASSETS$ = GetCurrentDirectory() ; Path to assets folder

SetCurrentDirectory("../")
PROJ_ROOT$ = GetCurrentDirectory()
Debug "Project's Root Path: '" +PROJ_ROOT$ + "'", 2
; TODO: Check that pandoc >=2.0 is available
;}==============================================================================
;                                      MAIN                                     
;{==============================================================================

; ==============================================================================
;- 1. Build Categories List
;{==============================================================================
; Build a list of all the project's categories and their associated resources.
; ------------------------------------------------------------------------------
StepHeading("Build Categories List")
Debug "Scanning project to build list of categories and resources:"

Structure Category
  Name.s
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

; Build Root Categories List (for sidebar navigation)
; ==========================
FirstElement( CategoriesL() )
NewList RootCategoriesL.s()
CopyList( CategoriesL()\SubCategoriesL(), RootCategoriesL() )

CompilerIf #DBG_LEVEL >= 2
  Debug "Root Categories:"
  cnt = 1
  ForEach RootCategoriesL()
    Debug RSet(Str(cnt), 3, " ") + ". '" + RootCategoriesL() + "'"
    cnt +1
  Next
CompilerEndIf
;}==============================================================================
; - 2. Check Project Integrity
;{==============================================================================
StepHeading("Checking Project Integrity")

ForEach CategoriesL()
  ; Check that every category has a REAMDE file
  ; ===========================================
  README$ =  CategoriesL()\Path+"README.md"
  Select FileSize(README$)
    Case 0
      Debug "- WARNING: '" + README$ + "' file size is 0 Kb!"
      WARN +1
    Case -1
      Debug "- WARNING: Missing '" + README$ + "' file!"
      WARN +1
    Case -2
      ; This shouldn't happen; but just in case...
      Debug "- ERROR: '" + README$ + "' is directory!"
      ERR +1
  EndSelect
  ; Check that every category has a items to parse
  ; ==============================================
  If Not ListSize( CategoriesL()\FilesToParseL() ) And
     CategoriesL()\Name <> "" ; Allow Root Category to empty
    Debug "- WARNING: Category '" + CategoriesL()\Path + "' has no entries!"
    WARN +1
  EndIf
Next
; Evaluate Found Warnings/Errors
; ==============================
If WARN | ERR = 0
  Debug "All tests passed."
Else
  Debug "Total warnings: " + Str(WARN)
  Debug "Total errors: " + Str(ERR)
  If ERR
    Debug ~"Fix errors and try again!\nAborting..."
    End 1
  Else
    Debug "Please confirm if you wish to continue..."
    If MessageRequester("WARNING CONFIRMATION", 
                        ~"Some warnings were issued during project integrity check.\n"+
                        "Do you wish to continue anyhow?", 
                        #PB_MessageRequester_YesNo | 
                        #PB_MessageRequester_Warning) = #PB_MessageRequester_No
      Debug "Aborting..."
      End 1
    EndIf
  EndIf
EndIf

;}==============================================================================
; - 3. Iterate Categories Lists
; ==============================================================================
StepHeading("Iterate Categories List")

cnt = 1
ForEach CategoriesL()
  
  catPath.s = CategoriesL()\Path
  Debug "Processing " + Str(cnt) + "/" + Str(totCategories +1) +": './" + catPath + "'"
  Debug "Category name: '" + CategoriesL()\Name + "'", 2
  Debug "Category path: '" + CategoriesL()\Path + "'", 2
  
  ; TODO: Add Proc to fix dir sep "/" into "\" for Win Path
  ;      (Not stritcly required, but might be useful if path splitting operations
  ;       or other similar path manipulation need to be done).
  Debug "Current working dir: " + PROJ_ROOT$ + catPath, 2
  SetCurrentDirectory(PROJ_ROOT$ + catPath)
  ; ~~~~~~~~~~~~~
  
  ; ====================
  ; Build path2root$ var
  ; ====================
  path2root$ = ""
  For i = 1 To CountString(catPath, "/")
    path2root$ + "../" ; <= Use "/" as URL path separator
  Next 
  Debug "path2root$: '" + path2root$ + "'", 2
  ; ~~~~~~~~~~~~~
  
  ;  ===============
  ;- Get README File
  ;  ===============
  README$ = #Empty$

  If FileSize("README.md") >= 0
    If ReadFile(0, "README.md", #PB_UTF8)
      While Eof(0) = 0
        README$ + ReadString(0) + #EOL
      Wend
      CloseFile(0)
      
;       Debug "README extracted contents:" + #EOL + #DIV3$
;       Debug README$ + #DIV3$
      
    Else
      Debug "ERROR: Couldn't open README.md"
      MessageRequester("ERROR!","Couldn't open the README.md file!", #PB_MessageRequester_Error)
      End 1
    EndIf
  Else
    Debug "Skipping README file for this category (not found)..."
  EndIf
  ;  ====================
  ;- Convert Page to HTML
  ;  ====================
  ;  Currently only partially implemented:
  ;    [x] README.md
  ;    [ ] Bread Crumbs
  ;    [ ] Sidbebar Menu
  ;    [ ] SubCategories Links
  ;    [ ] Items Resume-Card
  Declare PandocConvert(options.s)
  
  MD_Page.s = README$
  
  pandocOpts.s = "-f gfm --template=" + ASSETS$ + #HTML5_TEMPLATE +
                 " -V ROOT=" + path2root$ +
                 " -o index.html"
  
  If Not PandocConvert(pandocOpts.s)
    ; TODO: Check if it's Warning or Error
    Debug "!!! Pandoc returned ERROR or WARNING"
    Debug "Pandoc STDERR:"+ #EOL + #DIV3$ + #EOL + PandocErr$ + #EOL + #DIV3$
  EndIf
  ; ~~~~~~~~~~~~~
  cnt +1
  Debug #DIV1$
Next ; <= ForEach CategoriesL()

; ShowVariableViewer()
; Repeat
;   ; Infinte Loop to allow Debugger Inspections
; ForEver
End

;}==============================================================================
;                                   PROCEDURES                                  
;{==============================================================================

Procedure ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
  ; ------------------------------------------------------------------------------
  ; Recursively scan project folders and build the List of Categories.
  ; ------------------------------------------------------------------------------
  Static recCnt ; recursion level counter 
  For i=1 To recCnt
    Ind$ + " |" 
  Next
  recCnt +1
  
  Shared totCategories, totResources, totSubFRes
  
  If ExamineDirectory(recCnt, PathSuffix, "")
    While NextDirectoryEntry(recCnt)
      
      entryName.s = DirectoryEntryName(recCnt)
      entryDBG$ = Ind$ + " |-"
      
      If DirectoryEntryType(recCnt) = #PB_DirectoryEntry_File
        entryDBG$ + "- " + entryName + "  "
        fExt.s = GetExtensionPart(entryName)
        
        If fExt = "pb" Or fExt = "pbi"
          AddElement( CategoriesL()\FilesToParseL() )
          CategoriesL()\FilesToParseL() = entryName ; relative path
          totResources +1
          Debug entryDBG$, 3
        Else
          ; Ignore other PB extensions (*.pbp|*.pbf)
          Debug entryDBG$ + "(ignore file)", 4
        EndIf
        
      Else ; EntryType is Directory
        
        ; Folder-Ignore patterns
        ; ----------------------
        If entryName = "." Or entryName = ".." Or 
           entryName = ".git" Or
           Left(entryName, 1) = "_"
          Debug entryDBG$ + "- /" + entryName + "/  (ignore folder)", 4
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
          Debug entryDBG$ + "- " + fName, 3
        Else
          ;  =========================
          ;- SubFolder is Sub-Category
          ;  =========================
          AddElement( CategoriesL()\SubCategoriesL() )
          CategoriesL()\SubCategoriesL() = entryName ; just the folder name
          totCategories +1
          Debug entryDBG$ + "+ /" + entryName + "/", 3          
          ; -------------------------
          ; Recurse into Sub-Category
          ; -------------------------
          entryPath.s = PathSuffix + entryName + "/"
          PushListPosition( CategoriesL() )
          AddElement( CategoriesL() )
          CategoriesL()\name = entryName
          CategoriesL()\Path = entryPath
          ScanFolder(CategoriesL(), entryPath)
          PopListPosition( CategoriesL() )
        EndIf
      EndIf
      
    Wend
    FinishDirectory(recCnt)
  EndIf
  
  recCnt -1
  Debug Ind$, 3 ; adds separation after sub-folders ends
EndProcedure




Procedure PandocConvert(options.s)    
      Debug ">>>>>>>>>> PandocConvert() >>>>>>>>>>"  ; DELME
  
  Shared PandocRunErr, PandocExCode, PandocErr$, PandocSTDOUT$
  
  Shared MD_Page
  
  ; TODO: Move these to PPP::Reset() proc
  PandocRunErr = #False
  PandocErr$ = ""
  PandocSTDOUT$ = ""
  
  Enumeration 
    #Failure
    #Success
  EndEnumeration
  ; ------------------------------------------------------------------------------
  ;                                 Invoke Pandoc                                 
  ; ------------------------------------------------------------------------------
  #PANDOC_PROC_FLAGS = #PB_Program_Open  | #PB_Program_Write | #PB_Program_Read |
                       #PB_Program_Error | #PB_Program_UTF8
  currDir.s = GetCurrentDirectory()
  Pandoc = RunProgram("pandoc", options, currDir, #PANDOC_PROC_FLAGS)
  Debug "> PANDOC CURR DIR: " + currDir
  Debug "> PANDOC OPTS: " + options
  ;     PrintN("options: " + options) ; DBG Pandoc Args
  If Not Pandoc
    ; ------------------------------------------------------------------------------
    ;                               Somethig Wrong...                               
    ; ------------------------------------------------------------------------------
    PrintN("Pandoc couldn't be started...") ; DELME
    PandocRunErr = #True
    ProcedureReturn #Failure
  EndIf 
  
  ; Feed GFM page to pandoc
  ; =======================
  WriteProgramString(Pandoc, MD_Page, #PB_UTF8)
  WriteProgramData(Pandoc,  #PB_Program_Eof, 0)
  
  While ProgramRunning(Pandoc)
    
    ; ------------------------------------------------------------------------------
    ; Capture Pandoc's STDOUT
    ; ------------------------------------------------------------------------------
    If AvailableProgramOutput(Pandoc)
      PandocSTDOUT$ + ReadProgramString(Pandoc) + #EOL
      ; NOTE: HTML docs must have native End-of-Line sequence/char. Git will handle
      ;       proper conversion at checkout via .gitattributes settings.
    EndIf
    ; ------------------------------------------------------------------------------
    ; Capture Pandoc's STDERR
    ; ------------------------------------------------------------------------------
    err$ = ReadProgramError(Pandoc)
    If err$
      If PandocErr$ <> "" ; Add Line-Feed if not empty...
        PandocErr$ + #LF$
      EndIf
      PandocErr$ + err$
    EndIf
    
  Wend
  
  PandocExCode = ProgramExitCode(Pandoc)
  
  CloseProgram(Pandoc) ; Close the connection to the program
  
      Debug "<<<<<<<<<< PandocConvert() <<<<<<<<<<" ; DELME
  
  
  If PandocExCode Or          ; <= Errors
     PandocErr$ <> ""         ; <= Warnings
    ProcedureReturn #Failure
  Else
    ProcedureReturn #Success
  EndIf
  
EndProcedure
;}