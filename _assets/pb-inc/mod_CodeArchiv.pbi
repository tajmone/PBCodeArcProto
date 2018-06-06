; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                             CodeArchiv Module                              *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_CodeArchiv.pbi" v0.0.14 (2018/06/06) | PureBASIC 5.62 | MIT License
; ------------------------------------------------------------------------------
; CodeArchiv's Categories and Resources data and functionality API.
; Shared by any CodeArchiv tools requiring to operate on the whole project.
; ------------------------------------------------------------------------------
; modules dependencies:
XIncludeFile "mod_G.pbi"
;{------------------------------------------------------------------------------
; NOTE: Currently being developed on its own before integration into the current
;       HTMLPageConvert (or maybe into the new GUI version of it).
;       Toward the end of the file, a `CompilerIf #PB_Compiler_IsMainFile` block
;       is provided for standalone test execution.
; ------------------------------------------------------------------------------
; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;                                STATUS AND TODOS                               
; //////////////////////////////////////////////////////////////////////////////
; STATUS:
;  - Original code adapated to work as standalone Module.
;  - Current status: working draft; temporary code left over from previous main
;    hosting code still needs to be removed.
;
; TODOs:
;  - [ ] Check Project Integrity -- Integrate from "HTMLPagesCreator.pb" the code
;        to check the project's integrity. But I need to decide first if:
;        - [ ] Check Integrity at each ScanProject() execution? or
;        - [ ] leave CheckIntegrity() to be carried out at tool/user discretion.
;        This decision will cascade-affect other procedure too. Also, some status
;        var should be exposed via info (info\IsReady, \Errors, etc.). Iterators
;        and other functionality that deals with the project's structure should
;        not be executed if the Integry Check failed or was not carried out?
;        Also, how is the module going to know if proj files/folder have changed
;        since the last ScanProject() call?
;  - [ ] ScanFolder()'s Debug output must be either:
;        - [ ] removed from code (probably not needed anyhow), or
;        - [ ] captured in a string and stored somewhere, and only shown on 
;              demand -- but this should be handled by logger module.
;  - [ ] Add ITERATION procedures that take a procedure pointer as parameter and
;        allow to:
;        - [x] Call that procedure during each Category iteration
;              - [ ] Also allow opt param to restric categories by Level.
;        - [ ] ??? Call the procedure on iterations of curr Category's resources
;              (extra param to optionally restrict call to some res types)
;        - [x] Call the procedure on iteration of every resource (regardless of
;              categogires). 
;              - [ ] Also allow opt param to restric res types.
;  - [ ] ScanFolder():
;        - [x] While building Categories list, also build a Resources List.
;        - [ ] Implement handling of ExamineDirectory() error.
;        - [ ] Add a static Error status var that be used to track if any errors
;              were encountered during recursive scanning of folders. Possibly,
;              this should also be returned as a Bool value when exiting from the
;              top level Procedure call (so it can be used as an exit code).
;  - [ ] Add public procedures:
;        - [ ] ShowTree() -- return a str with Proj tree (Categories and Resources).
;        - [x] ShowStats() -- return a resume str of Categories and Resources.
;        - [ ] ShowCategoriesL() -- returns a str with list of all Categories.
;        - [x] ShowRootCategoriesL() -- returns a str with list of all Root Categories.
;        - [ ] ShowResourcesL() -- returns a str with list of all Resources.

;}

; ******************************************************************************
; *                                                                            *
;-                          MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule Arc
  ; ============================================================================
  ;                               TEMPORARY STUFF                               
  ; ============================================================================
  ; These have been moved here to simplify readapting the code, but they should
  ; be remove from the final module...
  ; ----------------------------------------------------------------------------
  ; FIXME: Remove left-over code from original source
  #DBG_LEVEL = 4
  DebugLevel #DBG_LEVEL
  ; These constants are just to simplify finding Debug lines in the code by their
  ; DBG Level (no practical use beside that):
  Enumeration DBG_Levels 1
    #DBGL1
    #DBGL2
    #DBGL3
    #DBGL4
  EndEnumeration
  ; ============================================================================
  ;                                 PUBLIC DATA                                 
  ; ============================================================================
  
  ; Arc::info -- Structured var gathering/exposing statistics about the project.
  Structure info
    IsReady.i             ; (Bool) True if no errors were found in scanning.   <~ CURRENTLY UNUSED!
    Errors.i              ; Total errors found in scanning.
    IntegrityReport.s     ; Integrity Checks Report (with Errors details, if any).
    totCategories.i       ; Total Categories count (Root excluded)
    totRootCategories.i   ; Total Top-Level Categories count
    totResources.i        ; Total Resources count
    totResT_PBSrc.i       ; Total Resources of PureBasic Source type
    totResT_PBInc.i       ; Total Resources of PureBasic Include-file type
    totResT_Folder.i      ; Total Resources of Subfolder type
  EndStructure
  
  info.info
  ; ----------------------------------------------------------------------------
  
  ;- Create Categories List
  ;  ======================
  Structure Category
    Name.s                  ; Folder name
    Path.s                  ; Path relative to CodeArchiv root (includes folder name)
    Level.i                 ; 0-2 (Root, Top-Level Category, Subcategory)
    List SubCategoriesL.s() ; Name/Link List to SubCategories
    List FilesToParseL.s()  ; List of files to parse (including "<subf>/CodeInfo.txt")
  EndStructure
  NewList CategoriesL.Category()
  
  NewList RootCategoriesL.s() ; Quick-List of Top-level Categories
  
  ;- Create Resources List
  ;  ======================
  ; NOTE: `\File` string for resources of Folder type will also include the subfolder name
  ;       because in most cases its intended use is relative to the Category path.
  ;       So "<subfolder>/CodeInfo.txt" are considered together as being the resource
  ;       File, because subfoldering is like an extension of the current category.
  Structure Resource
    File.s    ; Filename ( <filename>.pb | <filename>.pbi | "<subfolder>/CodeInfo.txt" )
    Path.s    ; Path relative to CodeArchiv root (includes filename)
    Type.i    ; ( G::#ResT_PBSrc | G::#ResT_PBInc | G::#ResT_Folder )
    *Category.Category ; pointer to its parent category
  EndStructure
  NewList ResourcesL.Resource()
  
  ;- Current Resource/Category
  ;  =========================
  ; This structured public var stores info on the current Category/Resource being
  ; iterated through by the iterating procedures.
  Structure Current
    Category.Category
    Resource.Resource
  EndStructure
  Current.Current
  
  ; ============================================================================
  ;                        PUBLIC PROCEDURES DECLARATION                        
  ; ============================================================================
  Declare    ScanProject()
  Declare    CheckIntegrity()
  Declare    Reset()
  Declare    CategoriesIteratorCallback( *CallbackProc )
  Declare    ResourcesIteratorCallback( *CallbackProc )
  Declare.s  ShowStats()
  Declare.s  ShowRootCategories()
EndDeclareModule

Module Arc
  ; ============================================================================
  ;                        PRIVATE PROCEDURES DECLARATION                       
  ; ============================================================================
  Declare ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
  
  ; ****************************************************************************
  ; *                                                                          *
  ;-                             PUBLIC PROCEDURES                             *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure ScanProject()
    Debug ">>> ScanProject()" ; DELME >>> ScanProject()
    
    ; ==========================================================================
    ; Scan the CodeArchiv project and build List of Categories and Resources.
    ; ==========================================================================
    
    Reset()
    Shared IsInit ; <~ UNUSED!!!
    Shared CategoriesL(), ResourcesL(), RootCategoriesL()
    Shared info
    
    ; Preserve Current Directory
    ; --------------------------
    ; (make no assumption on what the tool invoking this module might be doing):
    PrevCurrDir.s = GetCurrentDirectory()
    SetCurrentDirectory(G::CodeArchivPath)
    Debug ":: CurrDir: " + PrevCurrDir ; DELME DBG Preserve Current Directory
    
    Debug "Scanning project to build list of categories and resources:"
    
    AddElement( CategoriesL() )
    
    ; TODO: ScanFolder() should return 1 if errors were encountered!
    ScanFolder(CategoriesL())
    
    
    ;  ===========================
    ;- Sort Lists in CategoriesL()
    ;  ===========================
    ;  Different OSs will return files and folders in different order due to API
    ;  differences; therefore we must enforce a standard sorting criteria for each
    ;  category's FilesToParseL() list (affects order of resource cards in page)
    ;  and SubCategoriesL() list (affects order of sidebar navmenu entries and
    ;  subcategory links in page). CategoriesL() is also sorted, to ensure same
    ;  processing order on all OSs, but the first entry must not be moved because
    ;  it's the Root Category and the code expects it to be at index 0.
    ;  ---------------------------------------------------------------------------
    #ListSortFlags = #PB_Sort_Ascending | #PB_Sort_NoCase
    
    endIndex = ListSize( CategoriesL() ) -1
    SortStructuredList(CategoriesL(), #ListSortFlags, OffsetOf(Category\Name),
                       #PB_String, 1, endIndex) ; <= exclude index 0 from sorting!
    ForEach CategoriesL()                       ; Sort sub-lists...
      SortList(CategoriesL()\FilesToParseL(), #ListSortFlags)
      SortList(CategoriesL()\SubCategoriesL(), #ListSortFlags)
    Next
    
    ;  =======================
    ;- Check Project Integrity
    ;  =======================
    Err = CheckIntegrity()
    
    ;  ==========================
    ;- Build Root Categories List (for sidebar navigation)
    ;  ==========================
    FirstElement( CategoriesL() )
    CopyList( CategoriesL()\SubCategoriesL(), RootCategoriesL() )
    
    ; Restore Previous Current Directory
    ; ----------------------------------
    SetCurrentDirectory(PrevCurrDir)
    
    
    Debug "<<< ScanProject()" ; DELME <<< ScanProject()
    
    ProcedureReturn Err ; <- Return Errors found by CheckIntegrity()
    
  EndProcedure
  
  Procedure CheckIntegrity()
    ; ==========================================================================
    ; Check integrity of the CodeArchiv project structure and settings
    ; --------------------------------------------------------------------------
    ;  1. Check that "_assets/meta.yaml" file exists and is not 0 Kb.
    ;  2. Check that every category has a "REAMDE.md" file.
    ;  3. Check that every category contains resources.
    ; --------------------------------------------------------------------------
    ; - Returns the number of errors found (if any).
    ; - Stores in info\Errors the number of errors found.
    ; - Stores in info\IntegrityReport a report on the integrity checks.
    ; ==========================================================================
    ; TODO: Preserve Cat & Res Lists position
    
    ; Preserve Current Directory
    ; --------------------------
    ; (make no assumption on what the tool invoking this module might be doing):
    PrevCurrDir.s = GetCurrentDirectory()
    SetCurrentDirectory(G::CodeArchivPath)
    
    Shared CategoriesL()
    Shared info
    
    errCnt = 0                    ; Errors Counter
    info\IntegrityReport = #Empty$; Reset Err Report
    
    ; Temporary Lists to Store Errors by Groups:
    NewList ErrConfigL.s()    ; Errors List -> Configuration
    NewList ErrReadmeL.s()    ; Errors List -> README Files
    NewList ErrEmptyCatsL.s() ; Errors List -> Empty Categories
    
    ; Configuration Errors (currently only YAML Metadata/Settings File)
    ; ==================================
    ; Check status of YAML Metadata file
    ; ==================================
    ; TODO: test all errors with real scenarios
    FileRef$ = Chr(34) + G::#AssetsFolder + G::#DSEP + G::#YAMLSettingsFile + Chr(34)
    
    SizeResult = FileSize(G::AssetsPath + G::#YAMLSettingsFile)
    If SizeResult <= 0
      errCnt +1      
      Select SizeResult
        Case 0 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
               ; File is 0 Kb
               ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          tmp$ = FileRef$ + " has size 0 Kb!"
        Case -1 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                ; File not found
                ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          tmp$ = "missing " + FileRef$ + "!"
        Case -2 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                ; File is a directory
                ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          tmp$ = FileRef$ + " is a directory!"
      EndSelect
      ; Enlist Error for Report
      AddElement( ErrConfigL() )
      ErrConfigL() = tmp$
    EndIf
    
    ForEach CategoriesL()
      ; ===========================================
      ; Check that every category has a REAMDE file
      ; ===========================================
      README$ =  CategoriesL()\Path+"README.md"
      FileRef$ = Chr(34) + README$ + Chr(34)
      
      SizeResult = FileSize(README$)
      If SizeResult <= 0
        errCnt +1      
        Select SizeResult
          Case 0 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                 ; File is 0 Kb
                 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            tmp$ = FileRef$ + " file size is 0 Kb!"
          Case -1 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  ; File not found
                  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            tmp$ = "missing " + FileRef$ + "!"
          Case -2 ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  ; File is a directory
                  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  ; This shouldn't happen; but just in case...
            tmp$ = FileRef$ + " is directory!"
        EndSelect
        ; Enlist Error for Report
        AddElement( ErrReadmeL() )
        ErrReadmeL() = tmp$
        ; =======================================
        ; Check that every category has resources
        ; =======================================
        If Not ListSize( CategoriesL()\FilesToParseL() ) And
           CategoriesL()\Level <> 0 ; Root Folder can be empty (always is)
          
          errCnt +1
          ; Enlist Error for Report
          AddElement( ErrEmptyCatsL() )
          ErrEmptyCatsL() = ~"Category \"" + CategoriesL()\Path + ~"\" has no resources!"
        EndIf
      EndIf
    Next     
    
    If errCnt
      ; ===========================================
      ; Errors Where Found: Create Errors Report
      ; ===========================================
      
      totErrConfig    = ListSize( ErrConfigL() )
      totErrReadme    = ListSize( ErrReadmeL() )
      totErrEmptyCats = ListSize( ErrEmptyCatsL() )
      
      tmp$ = "Total Errors: " + Str(errCnt) + G::#EOL
      
      If totErrConfig
        ; -----------------------------
        ; Handle Configuration Problems
        ; -----------------------------
        head$ = "Configuration Errors"
        tmp$ + "- " + head$ + ": " + Str(totErrConfig) + G::#EOL
        
        tmp2$ + G::#EOL + head$ + G::#EOL +
                LSet("", Len(head$), "=") + G::#EOL
        cnt = 1
        cntW = Len(Str(totErrConfig)) ; Width of max counter
        
        ForEach ErrConfigL()
          tmp2$ + LSet(Str(cnt), cntW) + ". " + ErrConfigL() + G::#EOL
          cnt +1
        Next
        
      EndIf
      
      If totErrReadme
        ; ----------------------------
        ; Handle README Files Problems
        ; ----------------------------
        head$ = "README File Errors"
        tmp$ + "- " + head$ + ": " + Str(totErrReadme) + G::#EOL
        
        tmp2$ + G::#EOL + head$ + G::#EOL +
                LSet("", Len(head$), "=") + G::#EOL
        cnt = 1
        cntW = Len(Str(totErrReadme)) ; Width of max counter
        
        ForEach ErrReadmeL()
          tmp2$ + LSet(Str(cnt), cntW) + ". " + ErrReadmeL() + G::#EOL
          cnt +1
        Next
        
      EndIf
      
      If totErrEmptyCats
        ; --------------------------------
        ; Handle EMpty Categories Problems
        ; --------------------------------
        head$ = "Empty Categories Errors"
        tmp$ + "- " + head$ + ": " + Str(totErrEmptyCats) + G::#EOL
        
        tmp2$ + G::#EOL + head$ + G::#EOL +
                LSet("", Len(head$), "=") + G::#EOL
        cnt = 1
        cntW = Len(Str(totErrEmptyCats)) ; Width of max counter
        
        ForEach ErrEmptyCatsL()
          tmp2$ + LSet(Str(cnt), cntW) + ". " + ErrEmptyCatsL() + G::#EOL
          cnt +1
        Next
        
      EndIf
      
      ; Store Error Report
      info\IntegrityReport = tmp$ + tmp2$
      
    Else
      ; ===========================================
      ; No Errors Found: Standard Report
      ; ===========================================
      info\IntegrityReport = "The CodeArchiv passed all tests without any errors." + G::#EOL
    EndIf
    
    ; Restore Previous Current Directory
    ; ----------------------------------
    SetCurrentDirectory(PrevCurrDir)
    
    ProcedureReturn errCnt
    
  EndProcedure
  
  Procedure Reset()
    ; ==========================================================================
    ; Reset the Module and dispose of all gathered data.
    ; ==========================================================================
    Shared IsInit ; <~ UNUSED!!!
    Shared CategoriesL()
    ClearList( CategoriesL() )
    
    Shared ResourcesL()
    ClearList( ResourcesL() )
    
    Shared info
    With info
      \IsReady = #False
      \totCategories = 0
      \totRootCategories = 0
      \totResources = 0
      \totResT_PBSrc = 0
      \totResT_PBInc = 0
      \totResT_Folder = 0
    EndWith
    
  EndProcedure
  
  Procedure CategoriesIteratorCallback( *CallbackProc )
    ; ==========================================================================
    ; Iterate Through the CodeArchiv Categories
    ; ==========================================================================
    ; NOTE: This iterator sets Current\Resource to no resources at all.
    ;       Could this be a problem in some situations? Should it instead set it
    ;       to the first resource in the category? or no resource is better?
    ;       After all, the Root category doesn't have any resources. 
    ;       Also, the current category resource are available from the FilesToParseL().
    ; TODO: Implement optional filter for Cat Level
    Shared CategoriesL()
    Shared Current
    
    ; Preserve Curr Cat List Position
    ; -------------------------------
    ; (make no assumption on what the main code/tool is doing)
    PushListPosition( CategoriesL() )
    
    ; Set Current\Resource to None
    ; -----------------------------
    ClearStructure(@Current\Resource, Resource)
    
    ForEach CategoriesL()
      ; Set Arch::Current to the current Category
      Current\Category =  CategoriesL()
      
      If CallCFunctionFast( *CallbackProc )
        Break
      EndIf
    Next
    
    ; Restore Cat List Position
    ; -------------------------
    PopListPosition( CategoriesL() )
    
  EndProcedure
  
  Procedure ResourcesIteratorCallback( *CallbackProc )
    ; ==========================================================================
    ; Iterate Through the CodeArchiv Resources
    ; ==========================================================================
    ; TODO: Implement optional filter for Res Types
    Shared ResourcesL(), CategoriesL()
    Shared Current
    
    ; Preserve Curr Res/Cat Lists Positions
    ; -------------------------------------
    ; (make no assumption on what the main code/tool is doing)
    PushListPosition( CategoriesL() )
    PushListPosition( ResourcesL() )
    
    ForEach ResourcesL()
      ; Set Arch::Current to the current Res and its host Category
      Current\Resource = ResourcesL()
      ChangeCurrentElement( CategoriesL(), Current\Resource\Category ) ; <- pointer!
      Current\Category =  CategoriesL()
      
      If CallCFunctionFast( *CallbackProc )
        Break
      EndIf
    Next
    
    ; Restore Res/Cat Lists Positions
    ; -------------------------------------
    PopListPosition( CategoriesL() )
    PopListPosition( ResourcesL() )
    
  EndProcedure
  
  Procedure.s ShowStats()
    ; ==========================================================================
    ; Return a String With Statistic About the CodeArchiv
    ; ==========================================================================
    Shared info
    TXT$ = "- Total Categories: "+ Str(info\totCategories) + " (+ root)" + G::#EOL +
           "  - Root Categories: "+ Str(info\totRootCategories) + G::#EOL +
           "- Total Resources: "+ Str(info\totResources) + G::#EOL +
           "  - PB Source resources: "+ Str(info\totResT_PBSrc) + G::#EOL +
           "  - PB Include-file resources: "+ Str(info\totResT_PBInc) + G::#EOL +
           "  - Folder resources: "+ Str(info\totResT_Folder) +  G::#EOL
    ProcedureReturn TXT$
    
  EndProcedure
  
  Procedure.s ShowRootCategories()
    ; ==========================================================================
    ; Return a String Listing the Top-Level Categories
    ; ==========================================================================
    ; Ideally, this procedure could take an optional parameter with flags to
    ; enable more details in the output (eg: add a count of total resources in
    ; each root category, and/or count of subcategories, etc.).
    
    Shared RootCategoriesL()
    
    TXT$ = "Root Categories:" + G::#EOL2
    cnt = 1
    ForEach RootCategoriesL()
      TXT$ + RSet(Str(cnt), 3, " ") + ". " + RootCategoriesL() + G::#EOL
      cnt +1
    Next
    
    ProcedureReturn TXT$
    
  EndProcedure
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PRIVATE PROCEDURES                            *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
    ; ==========================================================================
    ; Recursively Scan Archiv folders and build Categories and Resources Lists.
    ; ==========================================================================
    ; TODO: Debug info of this procedure should be either removed or stored in
    ;       a string for optional use; else I could use a constant to check if
    ;       it should be shown or not.
    
    ;     Debug ">>> ScanFolder()" ; DELME
    
    Shared CategoriesL(), ResourcesL()
    Shared info
    
    Static recCnt ; recursion level counter (at the end of each Archiv scan will
                  ; always be back to the original value of '0'; no need to reset)
                  ; It's value is also equal to the Catgory Level.
    
    Static *currCat = #NUL ; This pointer is used internally to track the current
                           ; Category in order to store a pointer to the host Cat
                           ; of a resource in ResourcesL(). Since it's never used
                           ; in Root, the fact that on successive runs it will be
                           ; pointing to the last Category scanned it's not going
                           ; to cause problems.
    
    For i=1 To recCnt
      Ind$ + " |" ; <- for DBG purposes (proj tree)
    Next
    recCnt +1
    
    If ExamineDirectory(recCnt, PathSuffix, "")
      While NextDirectoryEntry(recCnt)
        
        entryName.s = DirectoryEntryName(recCnt)
        entryDBG$ = Ind$ + " |-"
        
        If DirectoryEntryType(recCnt) = #PB_DirectoryEntry_File
          ;  =================
          ;- EntryType is File
          ;  =================
          entryDBG$ + "- " + entryName + "  "
          fExt.s = GetExtensionPart(entryName)
          
          If fExt = "pb" Or fExt = "pbi"
            AddElement( CategoriesL()\FilesToParseL() )
            CategoriesL()\FilesToParseL() = entryName ; relative path
            
            ; Update Resources List:
            AddElement( ResourcesL() )
            ResourcesL()\File = entryName
            ResourcesL()\Path = PathSuffix + entryName
            ResourcesL()\Category = *currCat
            
            ; Update Proj Stats:
            info\totResources +1
            If fExt = "pb"
              info\totResT_PBSrc +1
              ResourcesL()\Type = G::#ResT_PBSrc
            Else
              info\totResT_PBInc +1
              ResourcesL()\Type = G::#ResT_PBInc
            EndIf
            Debug entryDBG$, #DBGL3
          Else
            ; Ignore other PB extensions (*.pbp|*.pbf)
            Debug entryDBG$ + "(ignore file)", #DBGL4
          EndIf
          
        Else
          ;  ======================
          ;- EntryType is Directory
          ;  ======================
          
          ; Folder-Ignore patterns
          ; ----------------------
          If entryName = "." Or entryName = ".." Or 
             entryName = ".git" Or
             Left(entryName, 1) = "_"
            Debug entryDBG$ + "- /" + entryName + "/  (ignore folder)", #DBGL4
            Continue 
          EndIf
          
          If FileSize(PathSuffix + entryName + "/" + G::#CodeInfoFile) >= 0
            ;  ================================          
            ;- SubFolder is Multi-File Sub-Item
            ;  ================================
            AddElement( CategoriesL()\FilesToParseL() )
            fName.s = entryName + "/" + G::#CodeInfoFile ; relative path
            CategoriesL()\FilesToParseL() = fName
            
            ; Update Resources List:
            AddElement( ResourcesL() )
            ResourcesL()\File = fName ; includes res-folder name
            ResourcesL()\Path = PathSuffix + fName
            ResourcesL()\Type = G::#ResT_Folder
            ResourcesL()\Category = *currCat
            
            ; Update Proj Stats:
            info\totResources +1
            info\totResT_Folder +1
            Debug entryDBG$ + "- " + fName, #DBGL3
          Else
            ;  =========================
            ;- SubFolder is Sub-Category
            ;  =========================
            AddElement( CategoriesL()\SubCategoriesL() )
            CategoriesL()\SubCategoriesL() = entryName ; just the folder name
            info\totCategories +1
            If recCnt = 1
              info\totRootCategories +1
            EndIf
            Debug entryDBG$ + "+ /" + entryName + "/", #DBGL3          
            ; -------------------------
            ; Recurse into Sub-Category
            ; -------------------------
            entryPath.s = PathSuffix + entryName + "/"
            *prevCurrCat = *currCat                 ; <- preserve *currCat before recursion
            PushListPosition( CategoriesL() )
            *currCat = AddElement( CategoriesL() )
            With CategoriesL()
              \Name = entryName
              \Path = entryPath
              \Level = recCnt
            EndWith
            ScanFolder(CategoriesL(), entryPath)
            PopListPosition( CategoriesL() )
            *currCat = *prevCurrCat                 ; <- restore *currCat after recursion
          EndIf
        EndIf
        
      Wend
      FinishDirectory(recCnt)
    EndIf ; <= ExamineDirectory(recCnt, PathSuffix, "")
          ; TODO: handle failure of ExamineDirectory() -- ie: returns "0"
          ;       Currently the code doesn't contemplate possibility of
          ;       failure, but it should; moreover, I must work out how to
          ;       handle it in a way that suits all possible uses of this
          ;       module. Should it interface this failure with mod_Error?
    
    recCnt -1
    Debug Ind$, #DBGL3 ; adds separation after sub-folders ends
    
    ;     Debug "<<< ScanFolder()" ; DELME
  EndProcedure
  
EndModule

; ******************************************************************************
; *                                                                            *
;-                          STANDALONE EXECUTION CODE                          *
; *                                                                            *
; ******************************************************************************
; The following CompilerIf code block will be executed only if this file is run
; by itself (as opposed to being included into another sourcefile).
; ------------------------------------------------------------------------------
CompilerIf #PB_Compiler_IsMainFile
  Debug "Testing CodeAcrhiv Module..."
  
  ; Let's set as Curr Dir the TEMP directory, to show that the module is still
  ; able to properly scan the CodeArchiv, regardless of what the Curr Dir is:
  SetCurrentDirectory( GetTemporaryDirectory() )
  
  ; Let's also store a copy of the new Curr Dir, to check later on that the
  ; module has restored it:
  TestCurrDir.s = GetCurrentDirectory()
  
  err = Arc::ScanProject()
  
  If err
    Debug "ScanProject() reported " + Str(err) + " errors!"
  EndIf
  Debug "These are the contents of Arc::info\IntegrityReport:" + G::#EOL + 
        "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + G::#EOL + 
        Arc::info\IntegrityReport +
        "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + G::#EOL
  
  
  
  ; Scan again the Archiv, to ensure that all vars are properly reset...
  ; ====================================================================
  Debug LSet("", 80, "=")
  Debug "Scan project again..."
  Arc::ScanProject()
  
  ; Now let's verify that the module has restored our Curr Dir after scanning:
  If GetCurrentDirectory() <> TestCurrDir
    Debug "ERROR: The module didn't restore our initial Curr Directory!!!"
  Else
    Debug "The module has correctly preserved our initial Curr Directory."
  EndIf
  
  ; ------------------------------------------------------------------------------
  ; Show Statistics
  ; ------------------------------------------------------------------------------
  Debug G::#DIV1$
  Debug "CodeArchiv Info Procedures" + #LF$ + G::#DIV1$
  
  Debug "CodeArchiv statistics résumé via `Arc::ShowStats()`:" + #LF$
  Debug Arc::ShowStats()
  
  Debug "List of Root Categories (Top-level) via `Arc::ShowRootCategories()`:" + #LF$
  Debug Arc::ShowRootCategories()
  
  ; TEST RESOURCES LIST
  ; ===================
  Debug LSet("", 80, "=")
  Debug "All resources:"
  ForEach Arc::ResourcesL()
    Debug " - " + Arc::ResourcesL()\Path
  Next
  
  ; ==============================================================================
  ;                               Iterators Examples                              
  ; ==============================================================================
  ; Here we demonstrate how to use mod CodeArchiv's built-in iterators to execute
  ; custom Procedures calls on every Category or Resource.
  
  ; ------------------------------------------------------------------------------
  ; Ex (a) -- Resources Iterator
  ; ------------------------------------------------------------------------------
  ; Arc::ResourcesIteratorCallback() is a quick way to call a custom Procedure on
  ; every resource in the CodeArchiv. The module will always expose references to
  ; current Resource and Category being iterated, via the Arch::Current structure.
  
  Debug G::#DIV1$
  Debug "Resources Iterator Example" + #LF$ + G::#DIV1$
  Debug ~"We'll use Arc::ResourcesIteratorCallback() to iterate through every resource in\n"+
        ~"the CodeArchiv and acces info about the current resource and its host category.\n"
  
  #tmpResType$ = "     Resource Type: "
  
  Procedure ResIterTest()
    Static cnt
    cnt +1
    Debug LSet(" ", 3 - Len(Str(cnt))) + Str(cnt) + ". " + Arc::Current\Resource\File
    Debug LSet("     ", Len(Arc::Current\Resource\File) +5, "-")
    
    Debug "     Resource Path (relative to Archiv Root): " + Arc::Current\Resource\Path
    
    Select Arc::Current\Resource\Type
      Case G::#ResT_PBSrc
        Debug #tmpResType$ + "PureBasic source file"
      Case G::#ResT_PBInc 
        Debug #tmpResType$ + "PureBasic include file"
      Case G::#ResT_Folder
        Debug #tmpResType$ + "Folder resource"
      Default
        Debug #tmpResType$ + "(unknown)"
    EndSelect
    
    ; Although we're iterating resources without going through categories, full
    ; info on the Category of the current resource is available to us because
    ; Arc::Current\Category represents the host category of current resource:
    Debug "     Host category info:"
    Debug "       * Category Path: " + Arc::Current\Category\Path
    Debug "       * Total resources in category: " + ListSize( Arc::Current\Category\FilesToParseL() )
    Debug "       * Total subcategories: " + ListSize( Arc::Current\Category\SubCategoriesL() ) + G::#EOL
  EndProcedure
  
  Arc::ResourcesIteratorCallback( @ResIterTest() )
  
  ; ------------------------------------------------------------------------------
  ; Ex (b) -- Aborting a Resources Iteration
  ; ------------------------------------------------------------------------------
  ; Now, an example of aborting an iterator: we'll iterate through all resources
  ; until the first Res of type Folder is encountered.
  Debug G::#DIV1$
  Debug "Resources Iterator Abort Example" + #LF$ + G::#DIV1$
  Debug ~"Iterate all Archiv resources and abort iteration at first Folder resource...\n"
  
  
  
  Procedure ResIterUntilFolder()
    Static cnt
    
    cnt +1
    Debug LSet(" ", 3 - Len(Str(cnt))) + Str(cnt) + ". " + Arc::Current\Resource\File
    If Arc::Current\Resource\Type = G::#ResT_Folder
      Debug LSet("     ", Len(Arc::Current\Resource\File) +5, "-")
      Debug ~"\n     *** ABORTING ITERATION ***\n"
      ProcedureReturn 1 ; <- Abort iteration cycle!
    EndIf
  EndProcedure
  
  Arc::ResourcesIteratorCallback( @ResIterUntilFolder() )
  
  ; ------------------------------------------------------------------------------
  ; Ex (a) -- Categories Iterator
  ; ------------------------------------------------------------------------------
  ; Here is an example of how the Categories iterator works.
  Debug G::#DIV1$
  Debug "Categories Iterator Example" + #LF$ + G::#DIV1$
  Debug ~"Iterate all Archiv categories and display some info...\n"
  
  Procedure CatIteratorTest()
    Static cnt
    
    cnt +1
    tmp$ = LSet(" ", 3 - Len(Str(cnt))) + Str(cnt) + ". "
    If Arc::Current\Category\Level = 0
      tmp$ + "(project's root)"
    Else
      tmp$ + ~"\"" + Arc::Current\Category\Path + ~"\" (Level: " + Str(Arc::Current\Category\Level) + ")"
    EndIf
    Debug tmp$
    
  EndProcedure
  
  Arc::CategoriesIteratorCallback( @CatIteratorTest() )
  
  
  ; TEMP DEBUGGING
  ; ==============
  ShowVariableViewer()
  Repeat
    ; loop forever to keep Variable Viewer open...
  ForEver
  
CompilerEndIf

;{ CHANGELOG
;  =========
; v0.0.14 (2018/06/06)
;      - new vars in Arc::info structered var:
;          - Arc::info\Errors
;          - Arc::info\IntegrityReport
;      - New Arc::CheckIntegrity() -- this procedure carries out all the integrity
;        checks on the Archive project:
;          1. Check that "_assets/meta.yaml" file exists and is not 0 Kb.
;          2. Check that every category has a "REAMDE.md" file.
;          3. Check that every category contains resources.
;        Returns the total number of errors found (if any). Also:
;          - Stores in info\Errors the number of errors found.
;          - Stores in info\IntegrityReport a report on the integrity checks.
;      - Arc::ScanProject() always invokes Arc::CheckIntegrity(), and now returns
;        the value returned by CheckIntegrity().
; v0.0.13 (2018/06/02)
;      - Comments clean-up and add useful notes.
; v0.0.12 (2018/06/02)
;     - New Arc::ShowStats() -- returns a résumé str of Categories and Resources.
;     - New Arc::ShowRootCategories() -- returns a str listing Root Categories.
; v0.0.11 (2018/06/02)
;     - New Arc::CategoriesIteratorCallback() -- this procedure iterates through
;       every category of the Archiv and calls *CallbackProc() at each step.
; v0.0.10 (2018/06/02)
;     - new CategoriesL()\Level (int: 0-2) to store the Level of a Category:
;         0 = Root
;         1 = Top-level category
;         2 = Subcategory
;       This is going to be useful for the Categories Iterator, both as a filter to limit
;       the categories on which the callback should be called, as well as a mean to be able
;       to check during resource iteration which level the current res host category belongs to.
; v0.0.9 (2018/05/30)
;     - Arc::ResourcesIteratorCallback() now aborts iteration when its Callback Procedure
;       returns non-zero.
; v0.0.8 (2018/05/30)
;     - New Arc::ResourcesIteratorCallback( *CallbackProc ) -- this procedure iterates through
;       every resource of the Archiv and calls *CallbackProc() at each step.
;     - New Arch::Current public variable (structured): this will always contain info about
;       the current resource and category being iterated.
;     - Demo/Test code block: a full example on how to use the Res iterator.
; v0.0.7 (2018/05/29)
;    - New Arc::ResourcesL() list to store structured data about all resources in Archiv.
;    - ScanFolder() now also populates the ResourcesL() when scanning the Archiv.
; v0.0.6 (2018/05/29)
;    - Rename some info struct vars using shorter names, like those used in mod_G:
;        totResTypePBSource   ->  totResT_PBSrc
;        totResTypePBInclude  ->  totResT_PBInc
;        totResTypeFolder     ->  totResT_Folder
; v0.0.5 (2018/05/29)
;    - Reset info vars at every ScanProject() call.
;    - Add Arc::info\totRootCategories var to store total count of top-level categories.
; v0.0.4 (2018/05/29)
;    - New structered var info (of .info type) to gather all info about the proj
;      (totCategories, etc.). This replaces the previous `totXXX` vars.
;    - New vars to store total count of resources by type:
;        - Arc::info\totResTypePBSource   (PureBasic Source)
;        - Arc::info\totResTypePBInclude  (PureBasic Include-file)
;        - Arc::info\totResTypeFolder     (Subfolder)
;      These should be handy for both internal use and to other modules/tools.
;}
