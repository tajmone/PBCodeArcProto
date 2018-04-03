; ******************************************************************************
; *                                                                            *
; *                             HTML Pages Creator                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "HTMLPagesCreator.pb" v.0.0.12 (2018/04/03) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Scans the project's files and folders and automatically generates HTML5 pages
; for browsing the project online (via GitHub Pages website) or offline.
; An "index.html" is built for each category, using the folder's "README.md"
; as introduction text, and a resume card is built for each resource in the
; category (via header comments parsing)
; ------------------------------------------------------------------------------
; TODO: Implement Warnings tracking to allow a resume at the end of execution.
; TODO: Fix debug messages in Comments Parser (according to Debug Level)
;{ CHANGELOG
;  =========
;  v.0.0.12 (2018/04/03)
;     - Add Abort() procedure -- starting to laying down the foundations for a
;       proper Warnings/Errors tracking and handling system. Still need to decide
;       if some issues should be treated as Warnings or Errors (see Issue #8).
;  v.0.0.11 (2018/03/31)
;     - Add Bulma-styled HTML Tags to Resume Card
;     - Add filename to card title bar
;  v.0.0.10 (2018/03/31)
;     - Integrated "comments_parser.pbi" code:
;       - ParseFile() now returns HTML Card string
;       - Fixed Bug in ParseComments(): Carry-On parsing didn't check if the
;         curr List Element was the last one, causing an infinite loop (only
;         in "CodeInfo.txt" files that didn't contain extra lines beside the
;         key-val comment lines)
;     - Now Resume Cards are created
;     - pandoc input format + extensions now is:
;         markdown_github + yaml_metadata_block + raw_attribute
; 
;     Still very drafty, the original parser code must be adapted to the host app:
;       - Error handling must be implemented for resources that yeld no key-vals
;       - Currently, a Card <table> is created even if no key-vals were extracted.
;       - CSS must be adapted (doen't look good)
;       - Must add table header with filename or app name
;
;  v.0.0.9 (2018/03/31)
;     - Read "_asstes/meta.yaml" and append it to MD source doc
;       (if README file contains YAML header, its vars definitions will prevail
;        over those of "meta.yaml" -- first definition is not overridable)
;     - Pandoc from format now "github_markdown" (because "gfm" doesn't support
;       "yaml_headers" extension"
;  v.0.0.8 (2018/03/28)
;    - Add links to SubCategories in Category pages.
;  v.0.0.7 (2018/03/28)
;    - Build BREADCRUMBS$ pandoc var (raw HTML)
;  v.0.0.6 (2018/03/28)
;    - Build SIDEBAR$ (pandoc var "SIDEBAR") raw HTML string.
;      (one level depth only, no "active" class for curr element)
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
;{==============================================================================
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

; Pandoc settings
; ===============
#PANDOC_TEMPLATE = "template.html5" ; pandoc template
#PANDOC_FORMAT_IN = "markdown_github+yaml_metadata_block+raw_attribute"

;}==============================================================================
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

Declare Abort(ErrorMsg.s)

; Misc Constants and Vars

#DIV1$ = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#DIV2$ = "=============================================================================="
#DIV3$ = "------------------------------------------------------------------------------"

;- RegEx
Enumeration RegExs
  #RE_URL
EndEnumeration

#RE_URL$ = "^(https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?)$"

If Not CreateRegularExpression(#RE_URL, #RE_URL$)
  ; FIXME: Internal Error (Bug) needs special Error Report
  Debug "RegEx URL Error: " + RegularExpressionError()
  MessageRequester("ERROR", "Error while creating URL RegEx!", #PB_MessageRequester_Error)
  End 1
EndIf

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
; FIXME: Missing README should be Error, not warning.
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
; TODO: Check which warnings need to be enlisted in the Warnings-Tracker
;       Some warnings might be catched later on, and they don't need to be enlisted here.
;       But some other types of warning might not be catched later on (eg: For loops where
;       there are 0 elements) and I must ensure they get all mentioned in the final report.
;       The ideal solution would be to catch all of them in their place instead of here
;       (this is just an overall integrity check), so it might be worth implemening some
;       checks on For loops, to catch skipped iterations.
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

; =========================
; Load Common YAML Metadata
; =========================
If ReadFile(0, ASSETS$ + "meta.yaml")
  While Eof(0) = 0
    YAML$ + ReadString(0) + #EOL
  Wend
  CloseFile(0)
Else
  Abort("Couldn't open '_assets/meta.yaml' file!") ;- ABORT: missing "meta.yaml"
EndIf

Debug #DIV2$ + #EOL + "YAML$:" + #EOL + YAML$ + #DIV2$ ; DELME

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
  pathLevels = CountString(catPath, "/")
  For i = 1 To pathLevels
    path2root$ + "../" ; <= Use "/" as URL path separator
  Next 
  Debug "path2root$: '" + path2root$ + "'", 2
  ; ===================
  ;- Build Bread Crumbs
  ; ===================
  BREADCRUMBS$ = "<li><a href='" + path2root$ + "index.html'>Home</a></li>" + #EOL
  
  For i = 1 To pathLevels
    crumb.s = StringField(catPath, i, "/")
    relPath.s = #Empty$
    For n = pathLevels To i+1 Step -1
      relPath + "../"
    Next
    BREADCRUMBS$ + "<li><a href='" + relPath + "index.html'>"+ crumb +"</a></li>" + #EOL
  Next
  
  Debug "BREADCRUMBS:" + #EOL + #DIV3$ + #EOL + BREADCRUMBS$ + #EOL + #DIV3$ ; FIXME
  
  ;  =============
  ;- Build Sidebar
  ;  =============
  ; TODO: Implement 3 Levels Sidebar
  ; TODO: Set active element
  SIDEBAR$ = #Empty$
  ForEach RootCategoriesL()
    SIDEBAR$ + "<li><a href='" + path2root$ + RootCategoriesL() + "/index.html'>" +
               RootCategoriesL() + "</a></li>" + #EOL ; single quotes only!
  Next
  
  Debug "SIDEBAR:" + #EOL + #DIV3$ + #EOL + SIDEBAR$ + #EOL + #DIV3$ ; FIXME
  
  
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
      Abort("Couldn't open the README file: '"+ catPath +"README.md'") ;- ABORT: Can't open README
    EndIf
  Else
    Abort("Missing README file: '"+ catPath +"README.md'") ;- ABORT: missing README
  EndIf
  ;  =========================
  ;- Build SubCategories links
  ;  =========================
  SubCatLinks.s = #Empty$
  With CategoriesL()
    If ListSize( \SubCategoriesL() )
      SubCatLinks = #EOL + #EOL + "---" + #EOL + #EOL
      SubCatLinks + "# Subcategories" +  #EOL + #EOL
      ForEach  \SubCategoriesL()
        cat$ = \SubCategoriesL()
        SubCatLinks + "- [" + cat$ + "](./"+ cat$ +"/index.html)" + #EOL
      Next
    Else
      Debug "No subcategories." ; FIXME
    EndIf
  EndWith
  
  Debug "SubCatLinks:" + #EOL + #DIV3$ + #EOL + SubCatLinks + #EOL + #DIV3$ ; FIXME
  
  
  ; ===================
  ;- Build Resume Cards
  ; ===================
  CARDS$ = "~~~{=html5}" + #EOL ; <= Raw content via panodc "raw_attribute" Extension
  Declare.s ParseFile(file.s)
  With CategoriesL()
    totItems = ListSize( \FilesToParseL() )
    Debug "Create Items Cards ("+ Str(totItems) +")"
    cnt = 1
    
    ForEach \FilesToParseL()
      file.s = \FilesToParseL()
      Debug Str(cnt) + ") '" + file +"'"
      Cards.s = ParseFile(file)
      CARDS$ + Cards
      ; Temporary Debug
      Debug "EXTRACTED CARD:" + #EOL + #DIV3$ + #EOL + Cards + #EOL + #DIV3$ ; FIXME
      cnt +1
    Next
    
  EndWith
  CARDS$ + "~~~" ; <= end Raw Content fenced block
  
  ;  ====================
  ;- Convert Page to HTML
  ;  ====================
  ;  Currently only partially implemented:
  ;    [x] README.md
  ;    [x] Bread Crumbs
  ;    [x] Sidbebar Menu
  ;        [ ] 3 Levels Depth
  ;    [x] SubCategories Links
  ;    [ ] Items Resume-Card
  ;    [ ] METADATA:
  ;        [ ] Create Title template var (for <title>)
  ;        [x] Append "common.yaml" metadata file
  ;            [x] $header-title$
  ;            [x] $header-subtitle$
  ;            [x] $description$
  ;            [x] $keywords$
  
  
  Declare PandocConvert(options.s)
  
  MD_Page.s = README$ + #EOL + #EOL + SubCatLinks + #EOL + #EOL + CARDS$ +
              #EOL + #EOL + YAML$
  
  pandocOpts.s = "-f "+ #PANDOC_FORMAT_IN +
                 " --template=" + ASSETS$ + #PANDOC_TEMPLATE +
                 " -V ROOT=" + path2root$ +
                 ~" -V BREADCRUMBS=\"" + BREADCRUMBS$ + ~"\"" +
                 ~" -V SIDEBAR=\"" + SIDEBAR$ + ~"\"" +
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
End ; <<< Main Ends Here

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

; ==============================================================================
;                               ERRORS & WARNINGS                               
; ==============================================================================
; TODO: Add Warnings-Tracking Procedure
; TODO: Add Warning Resume Procedure
Procedure Abort(ErrorMsg.s)
  
  Debug LSet("", 78, "\")
  Debug LSet("", 78, "*")
  Debug "FATAL ERROR: " + ErrorMsg + #EOL
  Debug "             Aborting program execution..."
  Debug LSet("", 78, "*")
  Debug LSet("", 78, "/")
  
  MessageRequester("FATAL ERROR", ErrorMsg + #EOL + #EOL + "Aborting execution...",
                   #PB_MessageRequester_Error)
  
  ; TODO: Show Warnings resume before aborting
  End 1
  
EndProcedure

;}==============================================================================
;                             Header Comments Parser                            
;{==============================================================================


Structure KeyValPair
  key.s
  val.s
EndStructure

;{ Procs Declarations
Declare   ExtractHeaderBlock(file.s, List CommentsL.s())
Declare   ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())
Declare.s BuildCard(List RawDataL.KeyValPair(), fileName.s)
;}



; ------------------------------------------------------------------------------
Procedure.s ParseFile(file.s)
  ; FIXME: Return Error instead of HTML str
  ;        Add str pointer to pass HTML results to main code, instead of return str
  
  ;{ check file exists
  Select FileSize(file.s)
    Case -1
      Debug "File not found: '" + file + "'"
      ;       ProcedureReturn #False
      ProcedureReturn
    Case -2
      Debug "File is a directory: '" + file + "'"
      ;       ProcedureReturn #False
      ProcedureReturn
  EndSelect ;}
  
  ;{ open file
  If Not ReadFile(0, file, #PB_UTF8)
    Debug "Can't open file: '" + file + "'"
    ;     ProcedureReturn #False
    ProcedureReturn
  EndIf
  ; Skip BOM
  ; TODO: Check enconding and if not UTF8 use it in read operations?
  ReadStringFormat(0) ;}
  
  NewList CommentsL.s()
  ExtractHeaderBlock(file, CommentsL())
  CloseFile(0)
  
  ;{ Debug Header Comments
  ;  =====================
  Debug "Header Block:"
  Debug LSet("--+", 80, "-")
  cnt=1
  ForEach CommentsL()
    Debug RSet(Str(cnt), 2, "0") + "| "+ CommentsL()
    cnt+1
  Next
  Debug LSet("--+", 80, "-") ;}
  
  NewList RawDataL.KeyValPair()
  ParseComments(CommentsL(), RawDataL())
  CardHTML.s = BuildCard( RawDataL(), file )
  
  ; TODO: Handle Empty Cards (don't return anything)
  ProcedureReturn CardHTML
  
EndProcedure
; ------------------------------------------------------------------------------
Procedure ExtractHeaderBlock(file.s, List CommentsL.s())
  Debug ">>> ExtractHeaderBlock("+file+", List CommentsL.s())"
  
  lineNum = 1
  
  Repeat
    
    line.s = ReadString(0)
    
    If Left(line, 1) <> ";"
      Debug "non comment line found at line " + Str(lineNum)
      Break
    Else
      AddElement(CommentsL())
      CommentsL() = line
      lineNum +1
    EndIf
    
  ForEver
  
  Debug "Total comments lines read: " + Str(lineNum -1)
  
  Debug "<<< ExtractHeaderBlock("+file+", List CommentsL.s())"
EndProcedure
; ------------------------------------------------------------------------------
Procedure ParseComments(List CommentsL.s(), List RawDataL.KeyValPair() )
  Debug ">>> ParseComments()"
  
  totLines = ListSize( CommentsL() )
  
  lineCnt = 1
  dbgIndent.s = "  | "
  
  ForEach CommentsL()
    lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
    commDelim.s = Left(CommentsL(), 3)
    If commDelim = ";: " Or commDelim = ";{:"  Or commDelim = ";}:"
      ; TODO: capture also ";{:" and ";}:"
      Debug lineNum + "Parse:"
      ;  ===========
      ;- Extract Key
      ;  ===========
      key.s = Trim(StringField(CommentsL(), 2, ":"))
      Debug dbgIndent + "- key found: '" + key +"'"
      ;  =============
      ;- Extract Value
      ;  =============
      valueStart = FindString(CommentsL(), ":", 4)
      value.s = Trim(Mid(CommentsL(), valueStart +1))
      If value = #Empty$
        Debug dbgIndent + "- value found: (empty)"
        newParagraph = #True
      Else
        Debug dbgIndent + "- value found: '" + value +"'"
        newParagraph = #False
      EndIf
      ;  =======================
      ;- Look for Carry-On Value
      ;  =======================
      carryOn = #False
      Repeat
        
        If lineCnt = totLines
          Break
        EndIf
        
        NextElement(CommentsL())
        lineCnt +1
        
        commDelim.s = Left(CommentsL(), 3)
        If Left(commDelim, 2) = ";." Or commDelim = ";{."  Or commDelim = ";}."
          
          ;- Carry-on line found
          ;  ~~~~~~~~~~~~~~~~~~~
          carryOn = #True
          valueNew.s = Trim(Mid(CommentsL(), 4))
          lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
          Debug lineNum + "Detected value carry-on:"
          Debug dbgIndent + "- carry-on value found: '" + valueNew +"'"
          ;  ------------------------------
          ;- Append Carry-On Value to Value
          ;  ------------------------------
          If valueNew <> #Empty$
            If newParagraph
              value + valueNew
            Else
              value + " " + valueNew
            EndIf
            newParagraph = #False
          Else
            value + #EOL + #EOL
            newParagraph = #True
          EndIf
          
        Else ;- No carry-on line found (or no more)
             ;  ~~~~~~~~~~~~~~~~~~~~~~
          If carryOn ; (there were carry-on lines)
                     ; Debug final value string
            Debug dbgIndent + "- Assembled value:"
            Debug LSet("", 80, "-")
            Debug value
          EndIf
          ;- Add <key> & <value> to list
          AddElement(RawDataL())
          RawDataL()\key = key
          RawDataL()\val = value
          ; Roll-back List Element and line counter...
          PreviousElement(CommentsL())
          lineCnt -1
          Break
        EndIf
        
      ForEver
      
    Else
      Debug lineNum + "Skip"
    EndIf
    lineCnt +1
    Debug LSet("", 80, "-")
  Next
  
  
  
  Debug "<<< ParseComments()"
EndProcedure
; ------------------------------------------------------------------------------
Procedure.s BuildCard( List RawDataL.KeyValPair(), fileName.s )
  Debug ">>> BuildCard()"
  
  ; TODO: Add link to fileName
  ; TODO: If file is "CodeInfo.txt" just add folder path
  
  Card.s = "<article class='message is-link'>" + #EOL +
           "<div class='message-header'>" + #EOL +
           "<p>" + fileName + "</p>" + #EOL +
           "</div>" + #EOL +
           "<div class='message-body is-paddingless'>" + #EOL +
           "<table class='res-card'><tbody>" + #EOL  
  
  ; TODO: Insert <p> tags?
  ForEach RawDataL()
    key.s   = EscapeString( RawDataL()\key, #PB_String_EscapeXML )
    Card + "<tr><td>" + key + ":</td><td>"
    
    value.s = RawDataL()\val
    
    value = EscapeString( value, #PB_String_EscapeXML )
    
    ;- Capture Links
    ;  =============
    ;  Only capture links if they are the sole content of value string.
    If ExamineRegularExpression(#RE_URL, value)
      While NextRegularExpressionMatch(#RE_URL)
        URL.s = RegularExpressionMatchString(#RE_URL)
        Link.s = ~"<a href=\"" + URL + ~"\">" + URL + "</a>"
        Debug "! URL Match: " + URL
        Debug "! URL Link: " + Link
        value = ReplaceString(value, URL, Link, #PB_String_CaseSensitive, 1, 1)
        ;         Debug "! URL Position: " + Str(RegularExpressionMatchPosition(#RE_URL))
        ;         Debug "! URL Length: " + Str(RegularExpressionMatchLength(#RE_URL))
      Wend
    EndIf
    
    ;- Convert EOLs to <br>
    ;  ====================
      value = ReplaceString(value, #EOL+#EOL, "<br /><br />") ; <= The optional " /" is for XML compatibility
      Card + value + "</td></tr>" + #EOL
      
    
  Next
  
  Card + "</tbody></table>" + #EOL +
         "</div></article>" + #EOL + #EOL
  
  Debug "<<< BuildCard()"
  ProcedureReturn Card
  
EndProcedure
;}==============================================================================
