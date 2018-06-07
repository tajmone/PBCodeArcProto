; ******************************************************************************
; *                                                                            *
; *                             HTML Pages Creator                             *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "HTMLPagesCreator.pb" v0.1.7 (2018/06/07) | PureBasic 5.62 | MIT License
; ------------------------------------------------------------------------------
; Scans the project's files and folders and automatically generates HTML5 pages
; for browsing the project online (via GitHub Pages website) or offline.
; An "index.html" is built for each category, using the folder's "README.md"
; as introduction text, and a resume card is built for each resource in the
; category (via header comments parsing)
;{ -- TODOs LIST »»»------------------------------------------------------------
; TODO: 
; =============
; DEBUG OUTPUT:
; =============
; TODO: DEBUG LEVEL 0 should show only Project stats and final report
; TODO: Polish debug messages in Comments Parser (according to Debug Level)
; ===============
; ERRORS TRACKER:
; ===============
; TODO: Error/Warning Message Requester should only be shown once, and if users
;       decides to carry on, any further non fatal error should be handled without
;       message requesters.
;       Checks should be implements via a boolean var at:
;        - STEP2 "Project Integrity"
;        - RaiseWarning() Proc
;       Furthermore, settings should offer a way to set IGNORE ERRORS.
; ===================
; OPTIONS & SETTINGS:
; ===================
; TODO: DRY-RUN option in Settings: runs through all the steps without writing
;       to disk, just to check if real use would result in any errors.
; ====================
; GENERAL SOURCE CODE:
; ====================
; TODO: Consistent Terminology:
; implement more precise and consistent terminolgy in var and procs naming,
; documentation and comments:
;  [ ] Category » SubCategory
;  [ ] Resource: can mean a single-file resource or a multi-file resource.
;                But I need a further term to indicate the latter (resource
;                folder; multi-file resource?)
;  [x] Errors: The only meaningful distinction is now between:
;                - Fatal Errors (always abort)
;                - Errors       (ask user if he wants to continue)
;} -- TODOs LIST «««------------------------------------------------------------

;{ CHANGELOG
;  =========
;  For the full changelog, see "HTMLPagesCreator_changelog.txt"
;
; v0.1.7 (2018/06/07)
;    - Set DBG Level to 0 for cleaner testing.
; v0.1.6 (2018/06/07)
;    - Use "mod_CodeArchiv.pbi"
;      - Finally the CodeArchiv module is being integrated into the app, so we
;        start to remove code dealing with Archiv structure and use the module's
;        data and procedures instead.
;      - Now Steps 1 & 2 ("build categories list" and "integrity checks") have 
;        been merged into a single step that relies on Arc::ScanFolder() to gather
;        info about the Archiv and check its integrity:
;        - If any errors are found, a résumé is displayed and the users is asked if
;          he wishes to continue or abort. (just like before, but the code is simpler)
;      - All references to Categories Lists now point to `Arc::` instead of using
;        local lists.
;    - Remove 1 STEP: Steps 1 & 2 are now a single Step.
; v0.1.5 (2018/05/24)
;    - Replaced all occurences of
;      - PROJ_ROOT$ -> G::CodeArchivPath
;      - ASSETS$    -> G::AssetsPath
; v0.1.4 (2018/05/24)
;    - Included modules are now in "pb-inc" subfolder.
;    - Refer to G::CodeArchivPath for determining project root.
;  v0.1.3 (2018/05/21)
;    - #CodeInfoFile -> G::#CodeInfoFile
;      This constant is needed by any module dealing with the CodeArchiv!
;  v0.1.2 (2018/05/16)
;    - Error Tracking moved to Errors Mod (Err::) "mod_Errors.pbi"
;  v0.1.1 (2018/05/16)
;    - Move horiz divider str constants to G mod (#DIV1$, etc.).
;    - Add and Include "mod_Errors.pbi" (Err::). Currently the module does nothing.
;  v0.1.0 (2018/05/16)
;    - START MODULARAZATION: v0.1.x will mark the transition from a single source
;      app to a module-based app, so that parts of the code can be reused by other
;      tools also. Once modularization of the full sourcecode is achieved will
;      bump to Alpha version 0.2.x.
;    - NEW MODULE: "mod_G.pbi" (G::) — this global module will now hold common
;      data shared by all modules in this app and other tools:
;      - Cross-platforms constants moved to this module (#EOL, etc.), now to use
;        them the module's namespace must be added (G::#EOL, G::#DSEP, etc).
;}
; ==============================================================================
;-                                   SETTINGS                                   
;{==============================================================================
; FIXME: The whole DebugLevel approach has to be changed.
#DBG_LEVEL = 0  ; Details Range 0—4:
                ;  - 0 : No extra info, just the basic feedback.
                ;  - 1 : (currently unused) 
                ;  - 2 : Extra details on Main code 
                ;  - 3 : Expose core procedure's internals: their steps, positive
                ;        findings and results.
                ;  - 4 : Also expose core procedure's ingnored details (misses,
                ;        skipped/ignored items, etc.)
DebugLevel #DBG_LEVEL

; Comments Parser settings
; ========================

#PURGE_EMPTY_KEYS = #True ; If #True, extracted keys with empty value are purged
                          ; from HTML Resume Card. If #False, they are kept.

; Pandoc settings
; ===============
#PANDOC_TEMPLATE = "template.html5" ; pandoc template
#PANDOC_FORMAT_IN = "markdown_github+yaml_metadata_block+raw_attribute"

;}==============================================================================
;-                                    SETUP                                     
;{==============================================================================

; ------------------------------------------------------------------------------
;-                      INCLUDE MODULES AND EXTERNAL FILES                      
; ------------------------------------------------------------------------------
XIncludeFile "pb-inc/mod_G.pbi"          ; G::     => Global Module
XIncludeFile "pb-inc/mod_CodeArchiv.pbi" ; Arc::   => CodeArchiv Module
XIncludeFile "pb-inc/mod_Errors.pbi"     ; Err::   => Errors Tracker

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


#TOT_STEPS = "3"
Macro StepHeading(Text)
  StepNum +1
  Debug G::#DIV1$ + G::#EOL + "STEP "+Str(StepNum)+"/"+#TOT_STEPS+" | "+Text+ G::#EOL + G::#DIV1$
EndMacro

Procedure.s FixLineEndings(StrToFix$)
  ; Fix newline chars (CRLF/LF) according to OS.
  ; ------------------------------------------------------------------------------
  FixedStr$ = ReplaceString(StrToFix$, G::#EOL_WRONG, G::#EOL)
  ProcedureReturn FixedStr$
EndProcedure

Procedure.s QuoteText(text$)
  ; Convert string to quoted text by adding " | " at the beginning of each line.
  ; ------------------------------------------------------------------------------
  text$ = FixLineEndings(text$)
  text$ = " | " + ReplaceString(text$, G::#EOL, G::#EOL + " | ")
  ProcedureReturn text$
EndProcedure

;- ««« ERROR HANDLING WAS HERE

;- RegEx
Enumeration G::RegExsIDs ; <= Global Enums
  #RE_URL
EndEnumeration

#RE_URL$ = "^(https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?)$"

If Not CreateRegularExpression(#RE_URL, #RE_URL$)
  ; NOTE: Error tested!
  ErrMSG$ = "Error while trying to create the following RegEx:" + G::#EOL2 + #RE_URL$ + G::#EOL2 +
            "The Regular Expression library returned the following error:" + G::#EOL +
            QuoteText( RegularExpressionError() )
  Err::Abort(ErrMSG$, Err::#FATAL_ERR_INTERNAL)
EndIf
;}

;}==============================================================================
;-                                  INITIALIZE                                  
;{==============================================================================
Debug G::#DIV2$ + G::#EOL + "HTMLPagesCreator" + G::#EOL + G::#DIV2$

SetCurrentDirectory( G::CodeArchivPath )

Debug "Debug Level: " + Str(#DBG_LEVEL)
Debug "Project's Root Path: '" + G::CodeArchivPath + "'", #DBGL2
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
Debug ~"Scanning the CodeArchiv to build the lists of categories and resources, and to\n"+
      ~"check the project's structural integrity.\n"

Err = Arc::ScanProject()

; ====================
; Show CodeArchiv Info
; ====================
Debug G::#DIV2$ + G::#EOL + "CodeArchiv Info" +  G::#EOL + G::#DIV2$
Debug "Project statistics:"
Debug Arc::ShowStats()
; TODO: Show Proj Tree...

; =====================
; Eval Integrity Checks
; =====================
Debug G::#DIV2$ + G::#EOL + "CodeArchiv Integrity Cheks" +  G::#EOL + G::#DIV2$
If Err
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; CodeArchiv Integrity Checks Failed
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Debug "Some errors were decteted while checking the integrity of CodeArchiv "+
        "project structure!"
  Debug "Please confirm if you wish to continue..."
  If MessageRequester("WARNING CONFIRMATION", 
                      ~"Some warnings were decteted during project integrity check.\n"+
                      "Do you wish to continue anyhow?", 
                      #PB_MessageRequester_YesNo | 
                      #PB_MessageRequester_Warning) = #PB_MessageRequester_No
    Debug "Aborting..."
    End 1
  EndIf
Else
  ; --------------------------------------
  ; All CodeArchiv Integrity Checks Passed
  ; --------------------------------------
  Debug "All integrity checks passed, the CodeArchiv is good to go."
EndIf

; End ; DELME: Premature End for Testing

;}==============================================================================
;- 2. Process Categories
;{==============================================================================
StepHeading("Process Categories")

; ===================================
; Warnings/Errors Tracking References
; ===================================
; TODO: Clean-Up Comments
; From here onward, the following `Err::` vars are used by the Errors module
; to store references to the problems encountered (for the final report):
; (1) `currCat` -- holds the path of the category currently being processed
;                  (empty if it's Root). Path is relative to the project's root.
; (2) `currRes` -- holds the filename of the resource currently being processed
;                  (with "CodeInfo.txt" resources, also stores the subfolder).
;
; The Errors tracker will interpret an empty `currRes` string as indicating that
; the error refers to the Category itself (eg: an empty category), rather than 
; to a specific resource file. For this reason, it's important that:
; -- When beginning to process a resource, `Err::currRes` must be immeditaely 
;    set to hold its filename;
; -- After a resource has been processed, `Err::currRes` must be immeditaely set
;    to an empty string.
; -----------------------------------
Err::currCat = #Empty$ ; Always = current Category path (relative to proj. root)
Err::currRes = #Empty$ ; Always = current Resource filename OR empty if none.

;  =========================
;- Load Common YAML Metadata
;{ =========================
If ReadFile(0, G::AssetsPath + "meta.yaml")
  While Eof(0) = 0
    YAML_META$ + ReadString(0) + G::#EOL
  Wend
  CloseFile(0)
Else
  Err::Abort("Couldn't read '_assets/meta.yaml' file!", Err::#FATAL_ERR_FILE_ACCESS) ;- ABORT: missing "meta.yaml"
EndIf

; Debug G::#DIV4$ + G::#EOL + "YAML_META$:" + G::#EOL + YAML_META$ + G::#DIV4$ ; DELME

;} ==========================
;- Iterate Through Categories
;  ==========================
cntCat = 1
ForEach Arc::CategoriesL()
  
  catPath.s = Arc::CategoriesL()\Path
  Err::currCat = catPath
  ; TODO: Use a macro to print category header? (looks cleaner)
  Debug G::#DIV2$ + G::#EOL + "CATEGORY " + Str(cntCat) + "/" + Str(totCategories +1) +
        " | ./" + catPath + G::#EOL + G::#DIV2$
  Debug "Category name: '" + Arc::CategoriesL()\Name + "'", #DBGL2
  Debug "Category path: '" + catPath + "'", #DBGL2
  
  ; TODO: Add Proc to fix dir sep "/" into "\" for Win Path
  ;      (Not stritcly required, but might be useful if path splitting operations
  ;       or other similar path manipulation need to be done).
  Debug "Current working dir: " + G::CodeArchivPath + catPath, #DBGL2
  SetCurrentDirectory(G::CodeArchivPath + catPath)
  ; ~~~~~~~~~~~~~
  
  ;  ====================
  ;- Build path2root$ var
  ;  ====================
  path2root$ = ""
  pathLevels = CountString(catPath, "/")
  For i = 1 To pathLevels
    path2root$ + "../" ; <= Use "/" as URL path separator
  Next
  
  YAML_PATH2ROOT$ = "ROOT: " + path2root$ + G::#EOL
  
  Debug "path2root$: '" + path2root$ + "'", #DBGL2
  ; ===================
  ;- Build Bread Crumbs
  ;{===================
  ; Breadcrumbs are passed to pandoc as structured YAML variables:
  ; ------------------------------------------------------------------------------
  ; breadcrumbs:
  ; - text: Gadget
  ;   link: ../index.html
  ; - text: HyperLinkGadget
  ;   link: index.html                                                                              
  ; ------------------------------------------------------------------------------
  ; The "Home" entry is handled by the template; only path segments up to current
  ; category are handled here. Inside pandoc template, they will be accessible as:
  ;   $breadcrumbs.text$
  ;   $breadcrumbs.link$
  ; ------------------------------------------------------------------------------
  YAML_BREADCRUMBS$ = "breadcrumbs:" + G::#EOL
  
  For i = 1 To pathLevels
    crumb.s = StringField(catPath, i, "/")
    relPath.s = #Empty$
    For n = pathLevels To i+1 Step -1
      relPath + "../"
    Next    
    YAML_BREADCRUMBS$ + "- text: " + crumb + G::#EOL +
                        "  link: " + relPath + "index.html" + G::#EOL
  Next
  
  Debug "BREADCRUMBS (YAML):" + G::#EOL + G::#DIV4$ + G::#EOL + YAML_BREADCRUMBS$ + G::#EOL + G::#DIV4$ ; FIXME: Debug ouput YAML BREADCRUMBS
  
  ;} =============================
  ;- Build Sidebar Navigation Menu
  ;{ =============================
  ; Navigation Menu, 2 Levels-Deep. Like with Breadcrumbs, the navigation menu is
  ; passed to pandoc as YAML stuctured vars:
  ; ------------------------------------------------------------------------------
  ; navmenu:
  ; - text: Gadget
  ;   link: ../../Gadget/index.html
  ;   active: true
  ;   submenu:
  ;   - text: HyperLinkGadget
  ;     link: ../../Gadget/HyperLinkGadget/index.html
  ;     active: true
  ; ------------------------------------------------------------------------------
  YAML_NAVMENU$ = "navmenu:" + G::#EOL
  
  Define.s linkPath, linkText, baseLinkPath
  
  ; Clamp Menu to 2 Levels
  If pathLevels > 2
    subPaths = 2
  Else
    subPaths = pathLevels
  EndIf
  
  ; TODO: Cleanup this part:
  Debug "pathLevels: " + Str(pathLevels) ; DELME
  Debug "subPaths: " + Str(subPaths)     ; DELME
  pathSeg1.s = StringField(catPath, 1, "/")
  Debug "pathSeg1: " + pathSeg1 ; DELME
  pathSeg2.s = StringField(catPath, 2, "/")
  Debug "pathSeg2: " + pathSeg2 ; DELME
  
  ; -----------------------
  ; Root Categories Entries
  ; -----------------------
  ForEach Arc::RootCategoriesL()
    linkPath = Arc::RootCategoriesL()
    linkText = linkPath
    
    YAML_NAVMENU$ + "- text: " + linkText + G::#EOL +
                    "  link: " + path2root$ + linkPath + "/index.html" + G::#EOL
    
    ; Check if curr menu entry is part of the category path:
    If subPaths And StringField(linkPath, 1, "/") = pathSeg1
      YAML_NAVMENU$ + "  active: true" + G::#EOL
      ; -----------------------
      ; SubLevel 1 Categories Entries
      ; -----------------------
      PushListPosition( Arc::CategoriesL() ) ; <= Store curr pos in CategoriesL()
      
      ; Find Curr Cat in Cats List:
      ForEach Arc::CategoriesL()
        If Arc::CategoriesL()\Path = pathSeg1 + "/"
          baseLinkPath = linkPath + "/"
          
          ; Check if Curr Cat has SubCats:
          If ListSize( Arc::CategoriesL()\SubCategoriesL() )
            YAML_NAVMENU$ + "  submenu:" + G::#EOL
            
            ; Iterate SubCategories of Curr Cat...
            ForEach Arc::CategoriesL()\SubCategoriesL()
              
              linkPath = baseLinkPath + Arc::CategoriesL()\SubCategoriesL()
              linkText = Arc::CategoriesL()\SubCategoriesL()
              
              YAML_NAVMENU$ + "  - text: " + linkText + G::#EOL +
                              "    link: " + path2root$ + linkPath + "/index.html" + G::#EOL            
              
              ; Check if curr menu entry is part of the category path:
              If StringField(linkPath, 2, "/") = pathSeg2
                YAML_NAVMENU$ + "    active: true" + G::#EOL
              EndIf
              
            Next ; <= SubCategoriesL() iteration
          EndIf
        EndIf
      Next
      
      PopListPosition( Arc::CategoriesL() ) ; <= Restore curr pos in CategoriesL()  
    EndIf                                   ; <<< END :: SubLevel 1 Categories Entries <<<
    
    SIDEBAR$ + "</li>" + G::#EOL ; Close Menu entry tag (Root Level)
  Next                           ; <= RootCategoriesL() iteration
  
  Debug "YAML_NAVMENU$:" + G::#EOL + G::#DIV4$ + G::#EOL + YAML_NAVMENU$ + G::#EOL + G::#DIV4$ ; FIXME: Debug ouput SIDEBAR
  
  ;   Continue ; DELME !!!! Skipp actually building pages
  
  ;} ===============
  ;- Get README File
  ;{ ===============
  Err::currRes = "README.md"
  README$ = #Empty$
  
  Select FileSize("README.md")
      ; ~~~~~~~~~~~~~~~~~~~~
      ; README File Problems
      ; ~~~~~~~~~~~~~~~~~~~~
      ; Don't abort, just warn
      ; (user was already warned about these and chose to continue!)
      ; NOTE: All three error cases tested!
    Case 0 ; File is 0 Kb
           ; ~~~~~~~~~~~~
      Err::TrackError("README.md has size 0 Kb.")
    Case -1 ; File not found
            ; ~~~~~~~~~~~~~~
      Err::TrackError("Missing README file.")
    Case -2 ; File is a directory
            ; ~~~~~~~~~~~~~~~~~~~~
      Err::TrackError("README.md is a directory.")
    Default
      ; ========================
      ; Get README File Contents
      ; ========================
      If ReadFile(0, "README.md", #PB_UTF8)
        While Eof(0) = 0
          README$ + ReadString(0) + G::#EOL
        Wend
        CloseFile(0)
        ;       Debug "README extracted contents:" + G::#EOL + G::#DIV4$ ; DELME
        ;       Debug README$ + G::#DIV4$
      Else
        ; ~~~~~~~~~~~~~~~~~~~~~~~~
        ; Can't Access README File
        ; ~~~~~~~~~~~~~~~~~~~~~~~~
        ; FIXME: Track as Warning? (this is not a fatal error!)
        Err::Abort("Couldn't read the README file: '"+ catPath +"README.md'", Err::#FATAL_ERR_FILE_ACCESS) ;- ABORT: Can't open README
      EndIf
  EndSelect
  Err::currRes = #Empty$
  ;} =========================
  ;- Build SubCategories links
  ;{ =========================
  SubCatLinks.s = #Empty$
  With Arc::CategoriesL()
    If ListSize( \SubCategoriesL() )
      SubCatLinks = G::#EOL2 + "---" + G::#EOL2
      SubCatLinks + "# Subcategories" +  G::#EOL2
      ForEach  \SubCategoriesL()
        cat$ = \SubCategoriesL()
        SubCatLinks + "- [" + cat$ + "](./"+ cat$ +"/index.html)" + G::#EOL
      Next
    Else
      Debug "No subcategories." ; FIXME: Debug output NO SUBCATEGORIES
    EndIf
  EndWith
  
  Debug "SubCatLinks:" + G::#EOL + G::#DIV4$ + G::#EOL + SubCatLinks + G::#EOL + G::#DIV4$ ; FIXME: Debug output SBUCATEGORIES LINKS
  
  ;} =========================
  ;- Build YAML Vars Block
  ;  =========================
  ;  Template Variables are added to MD_Page string which is fed to pandoc via STDIN.
  ;  TODO: YAML vars:
  ;  - [x] Breadcrumbs
  ;  - [ ] Sidbar
  ;  - [ ] HTML page contents
  
  YAML_VARS$ = G::#EOL2 + "---" + G::#EOL + 
               YAML_PATH2ROOT$ + G::#EOL +
               YAML_BREADCRUMBS$ + G::#EOL +
               YAML_NAVMENU$ + G::#EOL + 
               "..." + G::#EOL2
  
  Debug "YAML_VARS$:" + G::#EOL + G::#DIV4$ + G::#EOL + YAML_VARS$ + G::#EOL + G::#DIV4$ ; FIXME: Debug ouput YAML_VARS$
  
  ; ===================
  ;- Build Resume Cards
  ;{===================
  Declare ParseFileComments(resourcefile.s)
  With Arc::CategoriesL()
    totResources = ListSize( \FilesToParseL() )
    If totResources ; if Category contains Resources...
      
      CARDS$ = "~~~{=html5}" + G::#EOL ; <= Raw content via panodc "raw_attribute" Extension
      Debug "Create Items Cards ("+ Str(totResources) +")"
      cntRes = 1
      
      ForEach \FilesToParseL()
        file.s = \FilesToParseL()
        Err::currRes = file
        Debug G::#DIV3$ + G::#EOL + "RESOURCE " + Str(cntRes) + "/" + Str(totResources +1) +
              " | ./" + catPath + file + G::#EOL + G::#DIV3$
        currCardHTML.s = #Empty$ ; <= Shared in Parsing procedures!
        If ParseFileComments(file)
          CARDS$ + currCardHTML
          ; Temporary Debug
          Debug "EXTRACTED CARD:" + G::#EOL + G::#DIV4$ + G::#EOL + currCardHTML + G::#EOL + G::#DIV4$ ; FIXME: Debug output EXTRACTED CARD
          cntRes +1
        Else
          ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          ; Resume Card Creation Failure
          ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          Debug "!!! Card creation for this resource failed !!!" ; FIXME: Debug output RESUME CARD FAILURE
        EndIf
      Next
      Err::currRes = #Empty$
      CARDS$ + "~~~" ; <= end Raw Content fenced block
    Else  
      ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ; Current Category doesn't have any Resources
      ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      Debug "!!! Current Category has no Resources !!!" ; FIXME: Debug output CATEGORY IS EMPTY
                                                        ; TODO: issue a warning is Category is not Root?
    EndIf    
  EndWith
  
  ;} ====================
  ;- Convert Page to HTML
  ;{ ====================
  ;  Currently only partially implemented:
  ;    [x] README.md
  ;    [x] Bread Crumbs
  ;    [x] Sidbebar Menu (2 levels depth)
  ;    [x] SubCategories Links
  ;    [ ] Items Resume-Card
  ;    [ ] METADATA:
  ;        [ ] Create Title template var (for <title>)
  ;        [x] Append "common.yaml" metadata file
  ;            [x] $header-title$
  ;            [x] $header-subtitle$
  ;            [x] $description$
  ;            [x] $keywords$
  
  Err::currRes = "index.html" ; <= Any errors here will have to be reported as pertaining
                              ;    the output HTML doc because they could be caused by a
                              ;    variety of factors in pandoc (options, one of the strings
                              ;    that are fed via STDIN, etc.)   
  Declare PandocConvert(options.s)
  
  MD_Page.s = README$ + G::#EOL2 + SubCatLinks + G::#EOL2 + CARDS$ +
              G::#EOL2 + YAML_META$ + YAML_VARS$
  
  pandocOpts.s = "-f "+ #PANDOC_FORMAT_IN +
                 " --template=" + G::AssetsPath + #PANDOC_TEMPLATE +
                 "  -o index.html "
  
  
  Define PandocRunErr ; (bool) success/failure in invoking pandoc
  Define PandocExCode ; copy of pandoc exit code
  
  If Not PandocConvert(pandocOpts.s)
    ; Something went wrong with pandoc invocation...
    If PandocRunErr
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc invocation failed
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; NOTE: Tested!
      Err::Abort("Failed to invoke/run pandoc! Please, check that pandoc is correctly setup.",
                 Err::#FATAL_ERR_PANDOC)
    ElseIf PandocExCode
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc exited with Error
      ; ~~~~~~~~~~~~~~~~~~~~~~~~
      ; NOTE: Tested!
      Err::Abort("Pandoc exited with error (" + Str(PandocExCode) + "):" + G::#EOL +
                 QuoteText( PandocErr$ ), Err::#FATAL_ERR_PANDOC)
    Else
      ; ~~~~~~~~~~~~~~~~~~~~~~~~~~
      ; Pandoc returned Warning(s)
      ; ~~~~~~~~~~~~~~~~~~~~~~~~~~
      ; There could be more than just one warning...
      ; --------------------------------------------
      #WarnField$ = "[WARNING] " ; <= Precedes every warning
      totPandocWarnings = CountString(PandocErr$, #WarnField$)
      For i=1 To totPandocWarnings
        extrWarn.s = #WarnField$ + StringField(PandocErr$, i+1, #WarnField$) 
        Warn$ = ~"Pandoc reported the following warnings:\n" + QuoteText( extrWarn )
        Err::TrackError(Warn$)
      Next
    EndIf
  EndIf
  Err::currRes = #Empty$
  ; ~~~~~~~~~~~~~
  cntCat +1
  Debug G::#DIV2$
Next ; <= ForEach CategoriesL()

;}


;}==============================================================================
;- 3. Final Report And Quit
;{==============================================================================
StepHeading("Final Report")

totWarn = ListSize( Err::ErrTrackL() )
If totWarn = 0
  ; =======================
  ; No Problems Encountered
  ; =======================
  Debug "Everything went smooth."
  Goto SaveLog
EndIf

;  =====================
;- Iterate Problems List
;  =====================
Debug "Problems encountered: " + Str(totWarn)
cntWarn = 1
With Err::ErrTrackL()
  ForEach Err::ErrTrackL()
    Debug G::#DIV2$ + G::#EOL +
          "PROBLEM " + Str(cntWarn) + "/" + Str(totWarn) + " | ./" +
          \ErrCat + \ErrRes + G::#EOL + G::#DIV4$
    Debug \ErrMsg    
    cntWarn +1
  Next
EndWith
Debug G::#DIV2$


; ShowVariableViewer()
; Repeat
;   ; Infinte Loop to allow Debugger Inspections
; ForEver

;  =================================
;- Log Debug Window to File and Quit
;  =================================
SaveLog:
SaveDebugOutput(G::AssetsPath + "session.log")
; TODO: Add Exit Code (Err Level) via some variable.
;       Even if it's not a console app, it could be invoked from scripts leveraging
;       the PB Compiler or compiled to binary (no log will be shown in this case).
End ;}- <<< Main Ends Here <<<

;}==============================================================================
;-                                  PROCEDURES                                  
;{==============================================================================


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;-> PANDOC RELATED PROCEDURES
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Procedure PandocConvert(options.s)    
  Debug ">>>>>>>>>> PandocConvert() >>>>>>>>>>"  ; DELME
  
  Shared PandocRunErr, PandocExCode, PandocErr$, PandocSTDOUT$
  
  Shared MD_Page
  
  PandocRunErr = #False
  PandocErr$ = ""
  PandocSTDOUT$ = ""
  ; ------------------------------------------------------------------------------
  ;                                 Invoke Pandoc                                 
  ; ------------------------------------------------------------------------------
  #PANDOC_PROC_FLAGS = #PB_Program_Open  | #PB_Program_Write | #PB_Program_Read |
                       #PB_Program_Error | #PB_Program_UTF8
  currDir.s = GetCurrentDirectory()
  Pandoc = RunProgram("pandoc", options, currDir, #PANDOC_PROC_FLAGS)
  
  Debug "> PANDOC CURR DIR: " + currDir ; FIXME: Debug output PANDOC curr dir
  Debug "> PANDOC OPTS: " + options     ; FIXME: Debug output PANDOC options
  
  If Not Pandoc
    ; ------------------------------------------------------------------------------
    ;                               Somethig Wrong...                               
    ; ------------------------------------------------------------------------------
    PandocRunErr = #True
    ProcedureReturn Err::#Failure
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
      PandocSTDOUT$ + ReadProgramString(Pandoc) + G::#EOL
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
    ProcedureReturn Err::#Failure
  Else
    ProcedureReturn Err::#Success
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



Procedure ParseFileComments(file.s)
  ; ------------------------------------------------------------------------------
  ; Parse key-value pairs in resource file's comments header block.
  ; Returns #Success (=1) on success, or #Failure (=0) in case of errors.
  ; Errors and Warnings details are handled locally.
  ; ------------------------------------------------------------------------------
  Shared currCardHTML
  
  ;{ check if Resource file exists
  Select FileSize(file.s)
    Case  0 ; File is 0 Kb
            ; ~~~~~~~~~~~~
      Err::TrackError("Resource file has size 0 Kb.")
      ProcedureReturn Err::#Failure
    Case -1 ; File not found
            ; ~~~~~~~~~~~~~~
      Err::TrackError("Resource file not found.")
      ProcedureReturn Err::#Failure
    Case -2 ; File is a directory
            ; ~~~~~~~~~~~~~~~~~~~~
      Err::TrackError("Resource is a directory instead of file.")
      ProcedureReturn Err::#Failure
  EndSelect ;}
  
  ;{ open file
  If Not ReadFile(0, file, #PB_UTF8)
    Err::TrackError("Unable to open resource file for reading.")
    ProcedureReturn Err::#Failure
    
  EndIf
  ; Skip BOM
  ; TODO: FILE PARSE: Check enconding and if not UTF8 use it in read operations?
  ReadStringFormat(0) ;}
  
  NewList CommentsL.s()
  If Not ExtractHeaderBlock(file, CommentsL())
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ; No Comments Header Block Found
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Err::TrackError("No Header-Comments block found in resource.")
    ProcedureReturn Err::#Failure
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
  If ParseComments(CommentsL(), RawDataL())
    ; NOTE: instead of returning HTML string, handle it in BuildCard() via Shared currCardHTML
    currCardHTML = BuildCard( RawDataL(), file )    
    ; TODO: Handle Empty Cards Error
    ProcedureReturn Err::#Success
  Else
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ; No Keys Found in Comments Parsing
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Err::TrackError("No key-value pairs where found in resource.")
    ProcedureReturn Err::#Failure
  EndIf
  
EndProcedure
; ------------------------------------------------------------------------------
Procedure.i ExtractHeaderBlock(file.s, List CommentsL.s())
  ; ----------------------------------------------------------------------------
  ; Extracts every consecutive comment line from beginning of `file` up to the
  ; first non-comment line encountered. Comment lines are stored as isolated
  ; string in `CommentsL()` list.
  ; Returns the number of total comment lines extracted (or zero if none).   
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

Procedure ParseComments(List CommentsL.s(), List RawDataL.KeyValPair() )
  ; ----------------------------------------------------------------------------
  ; Parse the List of extracted comment-lines and extrapolate key-value pairs.
  ; Keys with empty values are preserved! FIXME: Drop empty keys
  ; Returns the number of total keys extracted (or zero if none).   
  ; ----------------------------------------------------------------------------
  Debug ">>> ParseComments()", #DBGL4
  
  totLines = ListSize( CommentsL() )
  
  lineCnt = 1
  dbgIndent.s = "  | "
  
  ForEach CommentsL()
    lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
    commDelim.s = Left(CommentsL(), 3)
    If commDelim = ";: " Or commDelim = ";{:"  Or commDelim = ";}:"
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
            value + G::#EOL2
            newParagraph = #True
          EndIf
          
        Else ;- No carry-on line found (or no more)
             ;  ~~~~~~~~~~~~~~~~~~~~~~
          If carryOn ; (there were carry-on lines)
                     ; Debug final value string
            Debug dbgIndent + "- Assembled value:" + G::#EOL + G::#DIV4$, #DBGL4
            Debug value, #DBGL4
          EndIf
          ;  ===========================
          ;- Add <key> & <value> to list
          ;  ===========================
          If Not ( value = #Empty$ And #PURGE_EMPTY_KEYS ); <= customizable setting
            AddElement(RawDataL())
            RawDataL()\key = key
            RawDataL()\val = value
          Else
            ; Skip Empty Key
            ; ~~~~~~~~~~~~~~
            ; TODO: Should debug this differently according to current DBG Level
            ;             Debug "~ Purged empty key: " + key, #DBGL3           
          EndIf
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
    Debug G::#DIV4$, #DBGL4
  Next
  
  Debug "<<< ParseComments()", #DBGL4
  ProcedureReturn ListSize( RawDataL() )
EndProcedure
; ------------------------------------------------------------------------------
Procedure.s BuildCard( List RawDataL.KeyValPair(), fileName.s )
  Debug ">>> BuildCard()", #DBGL4
  
  ; TODO: HTML CARD - Add link to fileName
  ; TODO: HTML CARD - If file is "CodeInfo.txt" just add folder path
  
  Card.s = "<article class='message is-link'>" + G::#EOL +
           "<div class='message-header'>" + G::#EOL +
           "<p>" + fileName + "</p>" + G::#EOL +
           "</div>" + G::#EOL +
           "<div class='message-body is-paddingless'>" + G::#EOL +
           "<table class='res-card'><tbody>" + G::#EOL  
  
  ; TODO: HTML CARD - Insert <p> tags?
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
        ;         Debug "! URL Position: " + Str(RegularExpressionMatchPosition(#RE_URL)) ; DELME
        ;         Debug "! URL Length: " + Str(RegularExpressionMatchLength(#RE_URL)) ; DELME
      Wend
    EndIf
    ;  ====================
    ;- Convert EOLs to <br>
    ;  ====================
    value = ReplaceString(value, G::#EOL2, "<br /><br />") ; <= The optional " /" is for XML compatibility
    Card + value + "</td></tr>" + G::#EOL
    
  Next
  
  Card + "</tbody></table>" + G::#EOL +
         "</div></article>" + G::#EOL2
  
  Debug "<<< BuildCard()", #DBGL4
  ProcedureReturn Card
  
EndProcedure
;} <<< PROCEDURES <<<
;}==============================================================================
