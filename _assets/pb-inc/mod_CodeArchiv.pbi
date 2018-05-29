; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                             CodeArchiv Module                              *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_CodeArchiv.pbi" v0.0.6 (2018/05/29) | PureBASIC 5.62 | MIT License
; ------------------------------------------------------------------------------
; CodeArchiv's Categories and Resources data and functionality API.
; Shared by any CodeArchiv tools requiring to operate on the whole project.
; ------------------------------------------------------------------------------
; modules dependencies:
XIncludeFile "mod_G.pbi"
; ------------------------------------------------------------------------------
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
;        - [ ] Call the procedure on iteration of every resource (regardless of
;              categogires). Also allow opt param to restric res types.
;  - [ ] ScanFolder():
;        - [ ] Implement handling of ExamineDirectory() error.
;        - [ ] Add a static Error status var that be used to track if any errors
;              were encountered during recursive scanning of folders. Possibly,
;              this should also be returned as a Bool value when exiting from the
;              top level Procedure call (so it can be used as an exit code).
;  - [x] mod_G -- Add Resource Types Enum (maybe also Binary Enum, so that iterators
;        and other Procedures could use them as flags to filter resource types to
;        include in iterations).
;  - [ ] Add public procedures:
;        - [ ] ShowTree() -- return a str with Proj tree.
;        - [ ] ShowStats() -- return a resume str of Categories and Resources.
;        - [ ] 
;  - [ ] 
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
    Name.s
    Path.s
    List SubCategoriesL.s() ; Name/Link List to SubCategories
    List FilesToParseL.s()  ; List of files to parse (including "<subf>/CodeInfo.txt")
  EndStructure
  NewList CategoriesL.Category()
  
  ; ============================================================================
  ;                        PUBLIC PROCEDURES DECLARATION                        
  ; ============================================================================
  Declare ScanProject()
  Declare Reset()
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
    Debug ">>> ScanProject()" ; DELME >>> ScanProject()
    ; ==========================================================================
    ; Scan the CodeArchiv project and build List of Categories and Resources.
    ; ==========================================================================
    
    Reset()
    Shared IsInit ; <~ UNUSED!!!
    Shared CategoriesL()
    Shared info
    
    ; Preserve Current Directory
    ; --------------------------
    ; (make no assumption on what the tool invoking this module might be doing):
    PrevCurrDir.s = GetCurrentDirectory()
    SetCurrentDirectory(G::CodeArchivPath)
    Debug ":: CurrDir: " + PrevCurrDir ; DELME DBG Preserve Current Directory
    
    Debug "Scanning project to build list of categories and resources:"
    
    ;     NewList CategoriesL.Category()
    AddElement( CategoriesL() )
    CategoriesL()\Path = "" ; Root folder
    
    ; TODO: ScanFolder() should return 1 if errors were encountered!
    ScanFolder(CategoriesL())
    
    ; TODO: The following debug info should become the str output of a dedicated
    ;       public Procedure --- eg: Arc::stats()
    Debug "- Categories found: "+ Str(info\totCategories) + " (excluding root folder)"
    Debug "  - Root Categories: "+ Str(info\totRootCategories)
    Debug "- Resources found: "+ Str(info\totResources) 
    Debug "  - PB Source resources: "+ Str(info\totResT_PBSrc)
    Debug "  - PB Include-file resources: "+ Str(info\totResT_PBInc)
    Debug "  - Folder resources: "+ Str(info\totResT_Folder)
    
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
      Debug "Root Categories:"
      cnt = 1
      ForEach RootCategoriesL()
        Debug RSet(Str(cnt), 3, " ") + ". '" + RootCategoriesL() + "'"
        cnt +1
      Next
    CompilerEndIf
    
    
    ; Restore Previous Current Directory
    ; ----------------------------------
    SetCurrentDirectory(PrevCurrDir)
    
    
    Debug "<<< ScanProject()" ; DELME <<< ScanProject()
  EndProcedure
  
  Procedure Reset()
    ; ==========================================================================
    ; Reset the Module and dispose of all gathered data.
    ; ==========================================================================
    Shared IsInit ; <~ UNUSED!!!
    Shared CategoriesL()
    ClearList( CategoriesL() )
    
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
    Shared CategoriesL()
    Shared info
    
    Static recCnt ; recursion level counter (at the end of each Archiv scan will
                  ; always be back to the original value of '0'; no need to reset)
    
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
            info\totResources +1
            If fExt = "pb"
              info\totResT_PBSrc +1
            Else
              info\totResT_PBInc +1
            EndIf
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
          
          If FileSize(PathSuffix + entryName + "/" + G::#CodeInfoFile) >= 0
            ;  ================================          
            ;- SubFolder is Multi-File Sub-Item
            ;  ================================
            AddElement( CategoriesL()\FilesToParseL() )
            fName.s = entryName + "/" + G::#CodeInfoFile ; relative path
            CategoriesL()\FilesToParseL() = fName
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
    EndIf ; <= ExamineDirectory(recCnt, PathSuffix, "")
          ; TODO: handle failure of ExamineDirectory() -- ie: returns "0"
          ;       Currently the code doesn't contemplate possibility of
          ;       failure, but it must; moreover, I must work out how to
          ;       handle it in a way that suits all possible uses of this
          ;       module. Should it interface this failure with mod_Error?
    
    recCnt -1
    Debug Ind$, #DBGL3 ; adds separation after sub-folders ends
    
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
  Debug "Testing CodeAcrhiv Module..."
  
  ; Let's set as Curr Dir the TEMP directory, to show that the module is still
  ; able to properly scan the CodeArchiv, regardless of what the Curr Dir is:
  SetCurrentDirectory( GetTemporaryDirectory() )
  
  ; Let's also store a copy of the new Curr Dir, to check later on that the
  ; module has restored it:
  TestCurrDir.s = GetCurrentDirectory()
  
  Arc::ScanProject()
  
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
  
CompilerEndIf

;{ CHANGELOG
;  =========
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
