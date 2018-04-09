; ******************************************************************************
; *                                                                            *
; *                             HTML Pages Creator                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "HTMLPagesCreator.pb" v0.0.25 (2018/04/09) | PureBasic 5.62
; ------------------------------------------------------------------------------
; Scans the project's files and folders and automatically generates HTML5 pages
; for browsing the project online (via GitHub Pages website) or offline.
; An "index.html" is built for each category, using the folder's "README.md"
; as introduction text, and a resume card is built for each resource in the
; category (via header comments parsing)
;{ -- TODOs LIST »»»------------------------------------------------------------
; TODO: Implement Warnings tracking to allow a resume at the end of execution.
; TODO: Polish debug messages in Comments Parser (according to Debug Level)
; TODO: Implement Comments Parser errors returning (empty cards handling)
; TODO: Terminology: implement more precise and consistent terminolgy in var
;       and procs naming, documentation and comments:
;       - Category » SubCategory
;       - Resource: can mean a single-file resource or a multi-file resource.
;                   But I need a further term to indicate the latter (resource
;                   folder; multi-file resource?)
; TODO: "curr" vars: The Warnings tracking system need to access at any time of
;       the Categories/Resources iteration process some vars referring to the
;       current elements being processed, in order to store the appropriate
;       references in the warning messages for the final report:
; 
;       - currCategory : full path (from root) of curr Category being processed
;       - currResource : full path (from root) of curr Resource being processed
;                        (if multi-file, just the folder name?)
;
;       Some of these are already in place, just need to rename them.
; TODO: 
;} -- TODOs LIST «««------------------------------------------------------------

;{ CHANGELOG
;  =========
;  v0.0.25 (2018/04/09)
;    - Clenaup DBG messages in Comments Parser (according to DBG Level)
;    - Add #DBGL1-#DBGL4 constants for use in DebugLevel (to allow quickly locating
;      Debug lines via Search)
;  v0.0.24 (2018/04/09)
;    - Handle pandoc Error/Warnings:
;      - Pandoc invocation failed (Abort)
;      - Pandoc exited with error (Abort)
;      - Pandoc exited with warning (report it)
;  v0.0.23 (2018/04/09)
;    - Code Cleanup
;    - Fix existing Abort() calls to include Error-Type
;  v0.0.22 (2018/04/09)
;    - Improved Abort() Procedure: not handles Error Types in messages, with a
;      default error message for every type of error, followed by the specific
;      error description.
;    - New AbortTypeMsg() structured Array with \Title and \Desc
;    - New FixLineEndings(StrToFix$) Procedure
;    - New QuoteText(text$) Procedure
;  v0.0.21 (2018/04/08)
;    - Proj.Integrity Check:
;      - Check integrity of "_assets/meta.yaml"
;  v0.0.20 (2018/04/06)
;    - Improved README file errors handling reports (via Select block):
;      - 0 Kb README File
;      - Missing README File
;      - "README.md" is directory
;    None of the above errors causes any longer the app to abort -- because user
;    was already informed about them at STEP 2 (Integrity Check) and chose to carry
;    on. Instead, these errors will be tracked by the Warning Tracker so that they
;    will show up in the final report.
;  v0.0.19 (2018/04/06)
;    - Cleanup bits and pieces
;  v0.0.18 (2018/04/06)
;    - ExtractHeaderBlock() now returns number of comment lines extracted
;    - ParseFileComments() now checks wether ExtractHeaderBlock() found a Header
;      Comments block, and only prints it out (DBG LEVEL 3) if it was found, and
;      issues a warning otherwise (still needs improvement in the warnings area)
;  v0.0.17 (2018/04/06)
;    - Cleanup comments
;  v0.0.16 (2018/04/04)
;    - Minor code cleanup
;  v0.0.15 (2018/04/03)
;    - #EOL2 (= #EOL + #EOL)
;    - Delimit Category being process by "DIV Ascii headers"
;    - Fix Category counter varname: "cnt" -> "cntCat" (was being overriden)
;    - When finished, save Debug Window to "_/assets/session.log" (unless Aborted)
;  v0.0.14 (2018/04/03)
;    - Cards Builder checks if curr Category contains resources or not.
;  v0.0.13 (2018/04/03)
;    - Renamed ParseFile() -> ParseFileComments()
;    - Changed: ParseFileComments() doesn't return string, instead uses
;      `Shared currCardHTML.s` to avoid passing strings around or using pointers
;      (I tried to use string pointers but the app hanged, even though tests
;       on a small scale were working; there seems to be a problem when handling
;       big strings via pointers, maybe a bug in PureBasic?)
;  v0.0.12 (2018/04/03)
;    - Add Abort() procedure -- starting to laying down the foundations for a
;      proper Warnings/Errors tracking and handling system. Still need to decide
;      if some issues should be treated as Warnings or Errors (see Issue #8).
;  v0.0.11 (2018/03/31)
;    - Add Bulma-styled HTML Tags to Resume Card
;    - Add filename to card title bar
;  v0.0.10 (2018/03/31)
;    - Integrated "comments_parser.pbi" code:
;      - ParseFile() now returns HTML Card string
;      - Fixed Bug in ParseComments(): Carry-On parsing didn't check if the
;        curr List Element was the last one, causing an infinite loop (only
;        in "CodeInfo.txt" files that didn't contain extra lines beside the
;        key-val comment lines)
;    - Now Resume Cards are created
;    - pandoc input format + extensions now is:
;        markdown_github + yaml_metadata_block + raw_attribute
; 
;    Still very drafty, the original parser code must be adapted to the host app:
;      - Error handling must be implemented for resources that yeld no key-vals
;      - Currently, a Card <table> is created even if no key-vals were extracted.
;      - CSS must be adapted (doen't look good)
;      - Must add table header with filename or app name
;
;  v0.0.9 (2018/03/31)
;    - Read "_asstes/meta.yaml" and append it to MD source doc
;      (if README file contains YAML header, its vars definitions will prevail
;        over those of "meta.yaml" -- first definition is not overridable)
;    - Pandoc from format now "github_markdown" (because "gfm" doesn't support
;      "yaml_headers" extension"
;  v0.0.8 (2018/03/28)
;    - Add links to SubCategories in Category pages.
;  v0.0.7 (2018/03/28)
;    - Build BREADCRUMBS$ pandoc var (raw HTML)
;  v0.0.6 (2018/03/28)
;    - Build SIDEBAR$ (pandoc var "SIDEBAR") raw HTML string.
;      (one level depth only, no "active" class for curr element)
;  v0.0.5 (2018/03/25)
;    - Add PandocConvert() procedure (from STDIN gfm to "index.html")
;    - Now an "index.html" page is created for each Category:
;      - "README.md" file used in content
;      - relative paths to assests (CSS) correctly handled
;    - Implemented first usable darft of "template.html" (breadcrumbs and sidebar
;      currently show sample contents only)
;  v0.0.4 (2018/03/21)
;    - Add project integrity checks
;  v0.0.3 (2018/03/21)
;    - Add CategoriesL()\Name.s to structure
;    - CategoriesL()\Path ends in "/" (unless root)
;    - Setup Categories iteration code-skeleton
;  v0.0.2 (2018/03/19)
;    - ScanFolder() Debug now shown as directory tree:
;      - DBG Lev 3: Show only found Categories and Resources
;      - DBG Lev 4: Also show ignored files and folders 
;  v0.0.1 (2018/03/19)
;    - Incorporate "BuildProjectTree.pb" and adapt it.
;    - Introduce DebugLevel filtering of output
;}
; ==============================================================================
;-                                   SETTINGS                                   
;{==============================================================================
#DBG_LEVEL = 4  ; Details Range 0—4:
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
  #DSEP = "\"       ; Directory Separator Character
  #EOL = #CRLF$     ; End-Of-Line Sequence
  #EOL_WRONG = #LF$ ; Wrong End-Of-Line Sequence
CompilerElse
  #DSEP = "/"
  #EOL = #LF$
  #EOL_WRONG = #CRLF$
CompilerEndIf
#EOL2 = #EOL + #EOL ; double EOL sequences

;- Procedures Declaration

;- Misc Constants and Vars

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> DEBUGGING
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Some helpers to handle text formatting in the debug output window.
; ------------------------------------------------------------------------------

; These constants are just to simplify finding Debug lines in the code by their
; DBG Level (no practical use beside that):
Enumeration DBG_Levels 1
  #DBGL1
  #DBGL2
  #DBGL3
  #DBGL4
EndEnumeration

#DIV1$ = "================================================================================"
#DIV2$ = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#DIV3$ = "~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~="
#DIV4$ = "--------------------------------------------------------------------------------"

#TOT_STEPS = "4"
Macro StepHeading(Text)
  StepNum +1
  Debug #DIV1$ + #EOL + "STEP "+Str(StepNum)+"/"+#TOT_STEPS+" | "+Text+ #EOL + #DIV1$
EndMacro

Procedure.s FixLineEndings(StrToFix$)
  ; Fix newline chars (CRLF/LF) according to OS.
  ; ------------------------------------------------------------------------------
  FixedStr$ = ReplaceString(StrToFix$, #EOL_WRONG, #EOL)
  ProcedureReturn FixedStr$
EndProcedure

Procedure.s QuoteText(text$)
  ; Convert string to quoted text by adding " | " at the beginning of each line.
  ; ------------------------------------------------------------------------------
  text$ = FixLineEndings(text$)
  text$ = " | " + ReplaceString(text$, #EOL, #EOL + " | ")
  ProcedureReturn text$
EndProcedure

;}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> ERRORS & WARNINGS HANDLING
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Some helpers to handle Warning and Errors, keep track of Warning to create a
; final report at the end, and handle messages when aborting on fatal errors.
; ------------------------------------------------------------------------------

; TODO: Add Warnings-Tracking Procedure
; TODO: Add Warning Résumé Procedure

; Define Error-Types which lead to aborting execution:
Enumeration AbortErrorsTypes
  #ABORT_GENERIC_ERROR
  #ABORT_INTERNAL_ERROR
  #ABORT_FILE_ACCESS_ERROR
  #ABORT_PANDOC_ERROR
EndEnumeration
totAbortErrorsTypes = #PB_Compiler_EnumerationValue -1

Structure ErrMessage
  Title.s     ; Error-Type Title
  Desc.s      ; Error-Type Description
EndStructure

; Array to associate Error-Types to their messages:
Dim AbortTypeMsg.ErrMessage(totAbortErrorsTypes)

For i=0 To totAbortErrorsTypes
  Read.s AbortTypeMsg(i)\Title 
  Read.s AbortTypeMsg(i)\Desc 
Next

AbortErrorMessages:
DataSection
  Data.s "FATAL ERROR", "The application encountered an fatal error."
  Data.s "INTERNAL ERROR", "The application encountered an internal error; if the problem persists contact the author."
  Data.s "FILE ACCESS ERROR", "The application encountered an error while trying to access a project file for I/O operations."
  Data.s "PANDOC ERROR", "An error was encountered while interacting with pandoc."
  ;   Data.s "", ""
EndDataSection


Procedure Abort(ErrorMsg.s, ErrorType = #ABORT_GENERIC_ERROR)
  ; ------------------------------------------------------------------------------
  ; Abort execution by reporting the Error-Type and its default description,
  ; followed by the specific error description. Abort message is both printed to
  ; debug output window and shown in MessageRequester.
  ; ------------------------------------------------------------------------------
  Shared AbortTypeMsg()
  
  ErrTypeTitle.s = AbortTypeMsg(ErrorType)\Title
  ErrTypeDesc.s  = AbortTypeMsg(ErrorType)\Desc
  
  Debug LSet("", 80, "\")
  Debug LSet("", 80, "*")
  Debug ErrTypeTitle + " — " + ErrTypeDesc + #EOL2 + ErrorMsg + #EOL
  Debug "Aborting program execution..."
  Debug LSet("", 80, "*")
  Debug LSet("", 80, "/")
  
  MessageRequester(ErrTypeTitle, ErrTypeDesc + #EOL2 + ErrorMsg + #EOL2 +
                                 "Aborting execution...", #PB_MessageRequester_Error)
  
  ; TODO: Show Warnings resume before aborting
  End 1
  
EndProcedure
;}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;- RegEx
Enumeration RegExs
  #RE_URL
EndEnumeration

#RE_URL$ = "^(https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?)$"

If Not CreateRegularExpression(#RE_URL, #RE_URL$)
  ; NOTE: Error tested!
  ErrMSG$ = "Error while trying to create the following RegEx:" + #EOL2 + #RE_URL$ + #EOL2 +
            "The Regular Expression library returned the following error:" + #EOL +
            QuoteText( RegularExpressionError() )
  Abort(ErrMSG$, #ABORT_INTERNAL_ERROR)
EndIf

;}==============================================================================
;-                                  INITIALIZE                                  
;{==============================================================================
Debug #DIV2$ + #EOL + "HTMLPagesCreator" + #EOL + #DIV2$

ASSETS$ = GetCurrentDirectory() ; Path to assets folder

SetCurrentDirectory("../")
PROJ_ROOT$ = GetCurrentDirectory()

Debug "Debug Level: " + Str(#DBG_LEVEL)
Debug "Project's Root Path: '" +PROJ_ROOT$ + "'", #DBGL2
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

CompilerIf #DBG_LEVEL >= #DBGL2
  Debug "Root Categories:"
  cnt = 1
  ForEach RootCategoriesL()
    Debug RSet(Str(cnt), 3, " ") + ". '" + RootCategoriesL() + "'"
    cnt +1
  Next
CompilerEndIf
;}==============================================================================
;- 2. Check Project Integrity
;{==============================================================================
StepHeading("Checking Project Integrity")
; FIXME: Missing README should be Error, not warning?
; TODO: Cleanup TESTS Reporting

; Check status of YAML Metadata file
; ==================================
; TODO: test all errors with real scenarios
Select FileSize(ASSETS$ + "meta.yaml")
  Case 0 ; File is 0 Kb
         ; ~~~~~~~~~~~~
    Debug "ERROR!! meta.yaml has size 0 Kb!"
    WARN +1
  Case -1 ; File not found
          ; ~~~~~~~~~~~~~~
    Debug "ERROR!!! Missing meta.yaml file"
    WARN +1
  Case -2 ; File is a directory
          ; ~~~~~~~~~~~~~~~~~~~~
    Debug "ERROR!! meta.yaml is a directory!"
    WARN +1
  Default ; TEST Passed
          ; ===========
    Debug "meta.yaml file seems Ok.", #DBGL2 ; FIXME Debug Level
EndSelect


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
      Debug "- WARNING: '" + README$ + "' is directory!"
      WARN +1
  EndSelect
  ; Check that every category has resources
  ; =======================================
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
;- 3. Process Categories
;{==============================================================================
StepHeading("Process Categories")

; =========================
; Load Common YAML Metadata
; =========================
If ReadFile(0, ASSETS$ + "meta.yaml")
  While Eof(0) = 0
    YAML$ + ReadString(0) + #EOL
  Wend
  CloseFile(0)
Else
  Abort("Couldn't read '_assets/meta.yaml' file!", #ABORT_FILE_ACCESS_ERROR) ;- ABORT: missing "meta.yaml"
EndIf

; Debug #DIV4$ + #EOL + "YAML$:" + #EOL + YAML$ + #DIV4$ ; DELME

cntCat = 1
ForEach CategoriesL()
  
  catPath.s = CategoriesL()\Path
  Debug #DIV2$ + #EOL + "CATEGORY " + Str(cntCat) + "/" + Str(totCategories +1) +
        " | ./" + catPath + #EOL + #DIV2$
  Debug "Category name: '" + CategoriesL()\Name + "'", #DBGL2
  Debug "Category path: '" + CategoriesL()\Path + "'", #DBGL2
  
  ; TODO: Add Proc to fix dir sep "/" into "\" for Win Path
  ;      (Not stritcly required, but might be useful if path splitting operations
  ;       or other similar path manipulation need to be done).
  Debug "Current working dir: " + PROJ_ROOT$ + catPath, #DBGL2
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
  Debug "path2root$: '" + path2root$ + "'", #DBGL2
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
  
  Debug "BREADCRUMBS:" + #EOL + #DIV4$ + #EOL + BREADCRUMBS$ + #EOL + #DIV4$ ; FIXME
  
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
  
  Debug "SIDEBAR:" + #EOL + #DIV4$ + #EOL + SIDEBAR$ + #EOL + #DIV4$ ; FIXME
  
  
  ;  ===============
  ;- Get README File
  ;  ===============
  README$ = #Empty$
  
  ; TODO: Change "If" to "Select" statement
  Select FileSize("README.md")
      ; ~~~~~~~~~~~~~~~~~~~~
      ; README File Problems
      ; ~~~~~~~~~~~~~~~~~~~~
      ; Don't abort, just warn
      ; (user was already warned about these and chose to continue!)
      ; NOTE: All three error cases tested!
    Case 0 ; File is 0 Kb
      Debug "WARNING!! README.md has size 0 Kb!"
    Case -1 ; File not found
      Debug "WARNING!!! Missing README file: '"+ catPath +"README.md'"
    Case -2 ; File is a directory
      Debug "WARNING!! README.md is a directory!"
    Default
      ; ========================
      ; Get README File Contents
      ; ========================
      If ReadFile(0, "README.md", #PB_UTF8)
        While Eof(0) = 0
          README$ + ReadString(0) + #EOL
        Wend
        CloseFile(0)
        ;       Debug "README extracted contents:" + #EOL + #DIV4$ ; DELME
        ;       Debug README$ + #DIV4$
      Else
        ; ~~~~~~~~~~~~~~~~~~~~~~~~
        ; Can't Access README File
        ; ~~~~~~~~~~~~~~~~~~~~~~~~
        ; TODO: This should be reported as a FILE ACCESS error
        Abort("Couldn't read the README file: '"+ catPath +"README.md'", #ABORT_FILE_ACCESS_ERROR) ;- ABORT: Can't open README
      EndIf
  EndSelect
  ;  =========================
  ;- Build SubCategories links
  ;  =========================
  SubCatLinks.s = #Empty$
  With CategoriesL()
    If ListSize( \SubCategoriesL() )
      SubCatLinks = #EOL2 + "---" + #EOL2
      SubCatLinks + "# Subcategories" +  #EOL2
      ForEach  \SubCategoriesL()
        cat$ = \SubCategoriesL()
        SubCatLinks + "- [" + cat$ + "](./"+ cat$ +"/index.html)" + #EOL
      Next
    Else
      Debug "No subcategories." ; FIXME
    EndIf
  EndWith
  
  Debug "SubCatLinks:" + #EOL + #DIV4$ + #EOL + SubCatLinks + #EOL + #DIV4$ ; FIXME
  
  
  ; ===================
  ;- Build Resume Cards
  ; ===================
  Declare ParseFileComments(resourcefile.s)
  With CategoriesL()
    totResources = ListSize( \FilesToParseL() )
    If totResources ; if Category contains Resources...
      
      CARDS$ = "~~~{=html5}" + #EOL ; <= Raw content via panodc "raw_attribute" Extension
      Debug "Create Items Cards ("+ Str(totResources) +")"
      cntRes = 1
      
      ForEach \FilesToParseL()
        file.s = \FilesToParseL()
        
        ;         Debug Str(cntRes) + ") '" + file +"'" ; DELME
        
        Debug #DIV3$ + #EOL + "RESOURCE " + Str(cntRes) + "/" + Str(totResources +1) +
              " | ./" + catPath + file + #EOL + #DIV3$
        
        currCardHTML.s = #Empty$ ; <= Shared in Parsing procedures!
        ParseFileComments(file)
        CARDS$ + currCardHTML
        ; Temporary Debug
        Debug "EXTRACTED CARD:" + #EOL + #DIV4$ + #EOL + currCardHTML + #EOL + #DIV4$ ; FIXME
        cntRes +1
      Next
      CARDS$ + "~~~" ; <= end Raw Content fenced block
    Else  
      ; Current Category doesn't have any Resources...
      Debug "!!! Current Category has no Resources !!!"
      ; TODO: issue a warning is Category is not Root?
    EndIf    
  EndWith
  
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
  
  MD_Page.s = README$ + #EOL2 + SubCatLinks + #EOL2 + CARDS$ +
              #EOL2 + YAML$
  
  pandocOpts.s = "-f "+ #PANDOC_FORMAT_IN +
                 " --template=" + ASSETS$ + #PANDOC_TEMPLATE +
                 " -V ROOT=" + path2root$ +
                 ~" -V BREADCRUMBS=\"" + BREADCRUMBS$ + ~"\"" +
                 ~" -V SIDEBAR=\"" + SIDEBAR$ + ~"\"" +
                 " -o index.html"
  
  Define PandocRunErr ; (bool) success/failure in invoking pandoc
  Define PandocExCode ; copy of pandoc exit code
  
  If Not PandocConvert(pandocOpts.s)
    ; Something went wrong with pandoc invocation...
    If PandocRunErr
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc invocation failed
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; NOTE: Tested!
      Abort("Failed to invoke/run pandoc! Please, check that pandoc is correctly setup.",
            #ABORT_PANDOC_ERROR)
    ElseIf PandocExCode
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc exited with Error
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; NOTE: Tested!
      Abort("Pandoc exited with error (" + Str(PandocExCode) + "):" + #EOL +
            QuoteText( PandocErr$ ), #ABORT_PANDOC_ERROR)
    Else
      ; ~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc returned Warning
      ; ~~~~~~~~~~~~~~~~~~~~~~~
      ; FIXME: Polishe Warning text
      ; FIXME: Track Warning
      Debug "!!! Pandoc returned a WARNING:"
      Debug QuoteText( PandocErr$ )
    EndIf
  EndIf
  ; ~~~~~~~~~~~~~
  cntCat +1
  Debug #DIV2$
Next ; <= ForEach CategoriesL()

;}==============================================================================
;- 4. Final Report And Quit
;{==============================================================================
StepHeading("Final Report")

; TODO: Implement Warning-Tracker Report

; ShowVariableViewer()
; Repeat
;   ; Infinte Loop to allow Debugger Inspections
; ForEver

;- Log Debug Window to File
SaveDebugOutput(ASSETS$ + "session.log")
End ;}- <<< Main Ends Here <<<

;}==============================================================================
;                                   PROCEDURES                                  
;{==============================================================================

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> PROJECT DATA & ACCESS
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
          Debug entryDBG$, #DBGL3
        Else
          ; Ignore other PB extensions (*.pbp|*.pbf)
          Debug entryDBG$ + "(ignore file)", #DBGL4
        EndIf
        
      Else ; EntryType is Directory
        
        ; Folder-Ignore patterns
        ; ----------------------
        If entryName = "." Or entryName = ".." Or 
           entryName = ".git" Or
           Left(entryName, 1) = "_"
          Debug entryDBG$ + "- /" + entryName + "/  (ignore folder)", #DBGL4
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
          Debug entryDBG$ + "- " + fName, #DBGL3
        Else
          ;  =========================
          ;- SubFolder is Sub-Category
          ;  =========================
          AddElement( CategoriesL()\SubCategoriesL() )
          CategoriesL()\SubCategoriesL() = entryName ; just the folder name
          totCategories +1
          Debug entryDBG$ + "+ /" + entryName + "/", #DBGL3          
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
  Debug Ind$, #DBGL3 ; adds separation after sub-folders ends
EndProcedure

;}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> PANDOC RELATED PROCEDURES
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


;}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> RESOURCES PARSER
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Structure KeyValPair
  key.s
  val.s
EndStructure

;{ Procs Declarations
Declare.i ExtractHeaderBlock(file.s, List CommentsL.s())
Declare   ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())
Declare.s BuildCard(List RawDataL.KeyValPair(), fileName.s)
;}



; ------------------------------------------------------------------------------
Procedure ParseFileComments(file.s)
  ; TODO: ParseFileComments() return Errors
  Shared currCardHTML
  
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
  If Not ExtractHeaderBlock(file, CommentsL())
    ; FIXME: Should be handled by Warnings Tracker
    Debug "WARNING: Missing Header Comments Blocks in '" + file +"'"
    ; FIXME: Should exit returning Err Code
  ElseIf #DBG_LEVEL >= 3
    ; ===========================
    ; Debug Header Comments Block
    ; ===========================
    ; TODO: Polish output text (and indentation?)
    Debug "Header Block:"
    Debug LSet("--+", 80, "-")
    cnt=1
    ForEach CommentsL()
      Debug RSet(Str(cnt), 2, "0") + "| "+ CommentsL()
      cnt+1
    Next
    Debug LSet("--+", 80, "-")
  EndIf
  CloseFile(0)
  
  
  
  NewList RawDataL.KeyValPair()
  ParseComments(CommentsL(), RawDataL())
  ; NOTE: instead of returning HTML string, handle it in BuildCard() via Shared currCardHTML
  currCardHTML = BuildCard( RawDataL(), file )
  
  ; TODO: Handle Empty Cards Error
  
EndProcedure
; ------------------------------------------------------------------------------
Procedure.i ExtractHeaderBlock(file.s, List CommentsL.s())
  ; ----------------------------------------------------------------------------
  ; Extracts every consecutive comment line from beginning of `file` up to the
  ; first non-comment line encountered. Comment lines are stored as isolated
  ; string in `CommentsL()` list.
  ; Returns the number of total comment lines extracted.   
  ; ----------------------------------------------------------------------------
  Define.i totLines = 0
  Repeat
    line.s = ReadString(0)
    
    If Left(line, 1) <> ";"
      ProcedureReturn totLines
    Else
      AddElement(CommentsL())
      CommentsL() = line
      totLines +1
    EndIf
  ForEver
  
EndProcedure
; ------------------------------------------------------------------------------
Procedure ParseComments(List CommentsL.s(), List RawDataL.KeyValPair() )
  Debug ">>> ParseComments()", #DBGL4
  
  totLines = ListSize( CommentsL() )
  
  lineCnt = 1
  dbgIndent.s = "  | "
  
  ForEach CommentsL()
    lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
    commDelim.s = Left(CommentsL(), 3)
    If commDelim = ";: " Or commDelim = ";{:"  Or commDelim = ";}:"
      ; TODO: capture also ";{:" and ";}:"
      Debug lineNum + "Parse:", #DBGL4
      ;  ===========
      ;- Extract Key
      ;  ===========
      key.s = Trim(StringField(CommentsL(), 2, ":"))
      Debug dbgIndent + "- key found: '" + key +"'", #DBGL4
      ;  =============
      ;- Extract Value
      ;  =============
      valueStart = FindString(CommentsL(), ":", 4)
      value.s = Trim(Mid(CommentsL(), valueStart +1))
      If value = #Empty$
        Debug dbgIndent + "- value found: (empty)", #DBGL4
        newParagraph = #True
      Else
        Debug dbgIndent + "- value found: '" + value +"'", #DBGL4
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
          Debug lineNum + "Detected value carry-on:", #DBGL4
          Debug dbgIndent + "- carry-on value found: '" + valueNew +"'", #DBGL4
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
            value + #EOL2
            newParagraph = #True
          EndIf
          
        Else ;- No carry-on line found (or no more)
             ;  ~~~~~~~~~~~~~~~~~~~~~~
          If carryOn ; (there were carry-on lines)
                     ; Debug final value string
            Debug dbgIndent + "- Assembled value:" + #EOL + #DIV4$, #DBGL4
            Debug value, #DBGL4
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
      Debug lineNum + "Skip", #DBGL4
    EndIf
    lineCnt +1
    Debug #DIV4$, #DBGL4
  Next
  
  
  
  Debug "<<< ParseComments()", #DBGL4
EndProcedure
; ------------------------------------------------------------------------------
Procedure.s BuildCard( List RawDataL.KeyValPair(), fileName.s )
  Debug ">>> BuildCard()", #DBGL4
  
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
    ;  =============
    ;- Capture Links
    ;  =============
    ;  Only capture links if they are the sole content of value string.
    If ExamineRegularExpression(#RE_URL, value)
      While NextRegularExpressionMatch(#RE_URL)
        URL.s = RegularExpressionMatchString(#RE_URL)
        Link.s = ~"<a href=\"" + URL + ~"\">" + URL + "</a>"
        Debug "! URL Match: " + URL, #DBGL4
        Debug "! URL Link: " + Link, #DBGL4
        value = ReplaceString(value, URL, Link, #PB_String_CaseSensitive, 1, 1)
        ;         Debug "! URL Position: " + Str(RegularExpressionMatchPosition(#RE_URL))
        ;         Debug "! URL Length: " + Str(RegularExpressionMatchLength(#RE_URL))
      Wend
    EndIf
    ;  ====================
    ;- Convert EOLs to <br>
    ;  ====================
    value = ReplaceString(value, #EOL2, "<br /><br />") ; <= The optional " /" is for XML compatibility
    Card + value + "</td></tr>" + #EOL
    
  Next
  
  Card + "</tbody></table>" + #EOL +
         "</div></article>" + #EOL2
  
  Debug "<<< BuildCard()", #DBGL4
  ProcedureReturn Card
  
EndProcedure
;} <<< PROCEDURES <<<
;}==============================================================================
