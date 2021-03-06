﻿; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                             CodeArchiv Module                              *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_CodeArchiv.pbi" v0.0.9 (2018/05/30) | PureBASIC 5.62 | MIT License
; ------------------------------------------------------------------------------
; CodeArchiv's Categories and Resources data and functionality API.
; Shared by any CodeArchiv tools requiring to operate on the whole project.
; ------------------------------------------------------------------------------
; modules dependencies:
XIncludeFile "mod_G.pbi"
XIncludeFile "../../_Sicro_CodeSharing/mod_Logger.pbi"
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
;  - [x] Expose interal data statistics via a structured var.
;        (this will also make Shared usage simpler in the module).
;  - [ ] ScanFolder()'s Debug output must be either:
;        - [ ] removed from code (probably not needed anyhow), or
;        - [ ] captured in a string and stored somewhere, and only shown on 
;              demand -- but this should be handled by logger module.
;  - [ ] Add ITERATION procedures that take a procedure pointer as parameter and
;        allow to:
;        - [ ] Call that procedure during each Category iteration
;        - [ ] Call the procedure on iterations of curr Category's resources
;              (extra param to optionally restrict call to some res types)
;        - [x] Call the procedure on iteration of every resource (regardless of
;              categogires). 
;              - [ ] Also allow opt param To restric res types.
;  - [ ] ScanFolder():
;        - [x] While building Categories list, also build a Resources List.
;        - [ ] Implement handling of ExamineDirectory() error.
;        - [ ] Add a static Error status var that be used to track if any errors
;              were encountered during recursive scanning of folders. Possibly,
;              this should also be returned as a Bool value when exiting from the
;              top level Procedure call (so it can be used as an exit code).
;  - [x] mod_G -- Add Resource Types Enum (maybe also Binary Enum, so that iterators
;        and other Procedures could use them as flags to filter resource types to
;        include in iterations).
;  - [ ] Add public procedures:
;        - [ ] ShowTree() -- return a str with Proj tree (Categories and Resources).
;        - [ ] ShowStats() -- return a resume str of Categories and Resources.
;        - [ ] ShowCategoriesL() -- returns a str with list of all Categories.
;        - [ ] ShowResourcesL() -- returns a str with list of all Resources.
;  - [x] Add Resources list: structured data containing resource name, path and
;        type. This will allow to build resources iterators which are independent
;        of categories, and therefore quicker in accessing the res files.
;}

; ******************************************************************************
; *                                                                            *
; *                         MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule Arc
  ; ============================================================================
  ;                               TEMPORARY STUFF                               
  ; ============================================================================
  ; These have been moved here to simplify readapting the code, but they should
  ; be remove from the final module...
  ; ----------------------------------------------------------------------------
  #DBG_LEVEL = 4
  Debug Logger::AddDevice("", Logger::#DeviceType_Debug, #DBG_LEVEL)
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
    IsReady.i             ; Boolean for querying the module's status
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
    List SubCategoriesL.s() ; Name/Link List to SubCategories
    List FilesToParseL.s()  ; List of files to parse (including "<subf>/CodeInfo.txt")
  EndStructure
  NewList CategoriesL.Category()
  
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
  Declare ScanProject()
  Declare Reset()
  Declare ResourcesIteratorCallback( *CallbackProc )
EndDeclareModule

Module Arc
  ; ============================================================================
  ;                        PRIVATE PROCEDURES DECLARATION                       
  ; ============================================================================
  Declare ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PUBLIC PROCEDURES                             *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure ScanProject()
    Logger::AddLog("", ">>> ScanProject()", #DBGL1) ; DELME >>> ScanProject()
    
    ; ==========================================================================
    ; Scan the CodeArchiv project and build List of Categories and Resources.
    ; ==========================================================================
    
    Reset()
    Shared IsInit ; <~ UNUSED!!!
    Shared CategoriesL(), ResourcesL()
    Shared info
    
    ; Preserve Current Directory
    ; --------------------------
    ; (make no assumption on what the tool invoking this module might be doing):
    PrevCurrDir.s = GetCurrentDirectory()
    SetCurrentDirectory(G::CodeArchivPath)
    Logger::AddLog("", ":: CurrDir: " + PrevCurrDir, #DBGL1) ; DELME DBG Preserve Current Directory
    
    Logger::AddLog("", "Scanning project to build list of categories and resources:", #DBGL1)
    
    ;     NewList CategoriesL.Category()
    AddElement( CategoriesL() )
    CategoriesL()\Path = "" ; Root folder
    
    ; TODO: ScanFolder() should return 1 if errors were encountered!
    ScanFolder(CategoriesL())
    
    ; TODO: The following debug info should become the str output of a dedicated
    ;       public Procedure --- eg: Arc::stats()
    Logger::AddLog("", "- Categories found: "+ Str(info\totCategories) + " (excluding root folder)", #DBGL1)
    Logger::AddLog("", "  - Root Categories: "+ Str(info\totRootCategories), #DBGL1)
    Logger::AddLog("", "- Resources found: "+ Str(info\totResources), #DBGL1)
    Logger::AddLog("", "  - PB Source resources: "+ Str(info\totResT_PBSrc), #DBGL1)
    Logger::AddLog("", "  - PB Include-file resources: "+ Str(info\totResT_PBInc), #DBGL1)
    Logger::AddLog("", "  - Folder resources: "+ Str(info\totResT_Folder), #DBGL1)
    
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
    
    ; Sort CategoriesL()
    endIndex = ListSize( CategoriesL() ) -1
    SortStructuredList(CategoriesL(), #ListSortFlags, OffsetOf(Category\Name),
                       #PB_String, 1, endIndex) ; <= exclude index 0 from sorting!
    ForEach CategoriesL()                       ; Sort sub-lists...
      SortList(CategoriesL()\FilesToParseL(), #ListSortFlags)
      SortList(CategoriesL()\SubCategoriesL(), #ListSortFlags)
    Next
    ;  ==========================
    ;- Build Root Categories List (for sidebar navigation)
    ;  ==========================
    FirstElement( CategoriesL() )
    NewList RootCategoriesL.s()
    CopyList( CategoriesL()\SubCategoriesL(), RootCategoriesL() )
    
    CompilerIf #DBG_LEVEL >= #DBGL2
      Logger::AddLog("", "Root Categories:", #DBGL1)
      cnt = 1
      ForEach RootCategoriesL()
        Logger::AddLog("", RSet(Str(cnt), 3, " ") + ". '" + RootCategoriesL() + "'", #DBGL1)
        cnt +1
      Next
    CompilerEndIf
    
    
    ; Restore Previous Current Directory
    ; ----------------------------------
    SetCurrentDirectory(PrevCurrDir)
    
    
    Logger::AddLog("", "<<< ScanProject()", #DBGL1)
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
  
  Procedure ResourcesIteratorCallback( *CallbackProc )
    ; TODO: If CallCFunctionFast() returns non-zero abort iteration...
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
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PRIVATE PROCEDURES                            *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure ScanFolder(List CategoriesL.Category(), PathSuffix.s = "")
    ;     Debug ">>> ScanFolder()" ; DELME
    ; ==========================================================================
    ; Recursively scan project folders and build the List of Categories.
    ; ==========================================================================
    ; TODO: Debug info of this procedure should be either removed or stored in
    ;       a string for optional use; else I could use a constant to check if
    ;       it should be shown or not.
    Shared CategoriesL(), ResourcesL()
    Shared info
    
    Static recCnt ; recursion level counter (at the end of each Archiv scan will
                  ; always be back to the original value of '0'; no need to reset)
    
    Static *currCat = #NUL ; This pointer is used internally to track the current
                           ; Category, used to store a pointer to the hosting cat
                           ; of a resource in ResourcesL().
    
    For i=1 To recCnt
      Ind$ + " |" ; <- for DBG purposes (proj tree)
    Next
    recCnt +1
    
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
            Logger::AddLog("", entryDBG$, #DBGL3)
          Else
            ; Ignore other PB extensions (*.pbp|*.pbf)
            Logger::AddLog("", entryDBG$ + "(ignore file)", #DBGL4)
          EndIf
          
        Else ; EntryType is Directory
          
          ; Folder-Ignore patterns
          ; ----------------------
          If entryName = "." Or entryName = ".." Or 
             entryName = ".git" Or
             Left(entryName, 1) = "_"
            Logger::AddLog("", entryDBG$ + "- /" + entryName + "/  (ignore folder)", #DBGL4)
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
            Logger::AddLog("", entryDBG$ + "- " + fName, #DBGL3)
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
            Logger::AddLog("", entryDBG$ + "+ /" + entryName + "/", #DBGL3)
            ; -------------------------
            ; Recurse into Sub-Category
            ; -------------------------
            entryPath.s = PathSuffix + entryName + "/"
            *prevCurrCat = *currCat                 ; <- preserve *currCat before recursion
            PushListPosition( CategoriesL() )
            *currCat = AddElement( CategoriesL() )
            CategoriesL()\name = entryName
            CategoriesL()\Path = entryPath
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
          ;       failure, but it must; moreover, I must work out how to
          ;       handle it in a way that suits all possible uses of this
          ;       module. Should it interface this failure with mod_Error?
    
    recCnt -1
    Logger::AddLog("", Ind$, #DBGL3) ; adds separation after sub-folders ends
    
    ;     Debug "<<< ScanFolder()" ; DELME
  EndProcedure
  
EndModule

; ******************************************************************************
; *                                                                            *
; *                         STANDALONE EXECUTION CODE                          *
; *                                                                            *
; ******************************************************************************
; The following CompilerIf code block will be executed only if this file is run
; by itself (as opposed to being included into another sourcefile).
; ------------------------------------------------------------------------------
CompilerIf #PB_Compiler_IsMainFile
  Logger::AddLog("", "Testing CodeAcrhiv Module...", Arc::#DBGL1)
  
  ; Let's set as Curr Dir the TEMP directory, to show that the module is still
  ; able to properly scan the CodeArchiv, regardless of what the Curr Dir is:
  SetCurrentDirectory( GetTemporaryDirectory() )
  
  ; Let's also store a copy of the new Curr Dir, to check later on that the
  ; module has restored it:
  TestCurrDir.s = GetCurrentDirectory()
  
  Arc::ScanProject()
  
  ; Scan again the Archiv, to ensure that all vars are properly reset...
  ; ====================================================================
  Logger::AddLog("", LSet("", 80, "="), Arc::#DBGL1)
  Logger::AddLog("", "Scan project again...", Arc::#DBGL1)
  Arc::ScanProject()
  
  ; Now let's verify that the module has restored our Curr Dir after scanning:
  If GetCurrentDirectory() <> TestCurrDir
    Logger::AddLog("", "ERROR: The module didn't restore our initial Curr Directory!!!", Arc::#DBGL1)
  Else
    Logger::AddLog("", "The module has correctly preserved our initial Curr Directory.", Arc::#DBGL1)
  EndIf
  
  ; TEST RESOURCES LIST
  ; ===================
  Logger::AddLog("", LSet("", 80, "="), Arc::#DBGL1)
  Logger::AddLog("", "All resources:", Arc::#DBGL1)
  ForEach Arc::ResourcesL()
    Logger::AddLog("", " - " + Arc::ResourcesL()\Path, Arc::#DBGL1)
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
  
  Logger::AddLog("", G::#DIV1$, Arc::#DBGL1)
  Logger::AddLog("", "Resources Iterator Example" + #LF$ + G::#DIV1$, Arc::#DBGL1)
  Logger::AddLog("", ~"We'll use Arc::ResourcesIteratorCallback() to iterate through every resource in\n"+
                     ~"the CodeArchiv and acces info about the current resource and its host category.\n", Arc::#DBGL1)
  #tmpResType$ = "     Resource Type: "
  
  Procedure ResIterTest()
    Static cnt
    cnt +1
    Logger::AddLog("", LSet(" ", 3 - Len(Str(cnt))) + Str(cnt) + ". " + Arc::Current\Resource\File, Arc::#DBGL1)
    Logger::AddLog("", LSet("     ", Len(Arc::Current\Resource\File) +5, "-"), Arc::#DBGL1)
    
    Logger::AddLog("", "     Resource Path (relative to Archiv Root): " + Arc::Current\Resource\Path, Arc::#DBGL1)
    
    Select Arc::Current\Resource\Type
      Case G::#ResT_PBSrc
        Logger::AddLog("", #tmpResType$ + "PureBasic source file", Arc::#DBGL1)
      Case G::#ResT_PBInc 
        Logger::AddLog("", #tmpResType$ + "PureBasic include file", Arc::#DBGL1)
      Case G::#ResT_Folder
        Logger::AddLog("", #tmpResType$ + "Folder resource", Arc::#DBGL1)
      Default
        Logger::AddLog("", #tmpResType$ + "(unknown)", Arc::#DBGL1)
    EndSelect
    
    ; Although we're iterating resources without going through categories, full
    ; info on the Category of the current resource is available to us because
    ; Arc::Current\Category represents the host category of current resource:
    Logger::AddLog("", "     Host category info:", Arc::#DBGL1)
    Logger::AddLog("", "       * Category Path: " + Arc::Current\Category\Path, Arc::#DBGL1)
    Logger::AddLog("", "       * Total resources in category: " + ListSize( Arc::Current\Category\FilesToParseL() ), Arc::#DBGL1)
    Logger::AddLog("", "       * Total subcategories: " + ListSize( Arc::Current\Category\SubCategoriesL() ) + G::#EOL, Arc::#DBGL1)
  EndProcedure
  
  Arc::ResourcesIteratorCallback( @ResIterTest() )
  
  ; ------------------------------------------------------------------------------
  ; Ex (b) -- Aborting a Resources Iteration
  ; ------------------------------------------------------------------------------
  ; Now, an example of aborting an iterator: we'll iterate through all resources
  ; until the first Res of type Folder is encountered.
  Logger::AddLog("", G::#DIV1$, Arc::#DBGL1)
  Logger::AddLog("", "Resources Iterator Abort Example" + #LF$ + G::#DIV1$, Arc::#DBGL1)
  Logger::AddLog("", ~"Iterate all Archiv resources and abort iteration at first Folder resource...\n", Arc::#DBGL1)
  
  
  
  Procedure ResIterUntilFolder()
    Static cnt
    
    cnt +1
    Logger::AddLog("", LSet(" ", 3 - Len(Str(cnt))) + Str(cnt) + ". " + Arc::Current\Resource\File, Arc::#DBGL1)
    If Arc::Current\Resource\Type = G::#ResT_Folder
      Logger::AddLog("", LSet("     ", Len(Arc::Current\Resource\File) +5, "-"), Arc::#DBGL1)
      Logger::AddLog("", ~"\n     *** ABORTING ITERATION ***\n", Arc::#DBGL1)
      ProcedureReturn 1 ; <- Abort iteration cycle!
    EndIf
  EndProcedure
  
  Arc::ResourcesIteratorCallback( @ResIterUntilFolder() )
  
  
  
  ; TEMP DEBUGGING
  ; ==============
  ShowVariableViewer()
  Repeat
    ; loop forever to keep Variable Viewer open...
  ForEver
  
CompilerEndIf

;{ CHANGELOG
;  =========
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
