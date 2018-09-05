; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                        CodeArchiv Resources Module                         *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_Resources.pbi" v0.0.2 (2018/07/09) | PureBASIC 5.62 | MIT License

; Resources management module shared by all CodeArchiv tools.

; modules dependencies:
; - mod_G.pbi

;- TODO LIST -------------------------------------------------------------------
;{ =========
; [ ] Integrate the code from "HTMLPagesCreator.pb" that deals with parsing
;     resources comments headers:
;     [ ] 
; [ ] Integrate functionality from Sicro's old "CodesChecker.pb":
;     [ ] Check code syntax via the compiler syntax checker (--check --thread).
;     [ ] Check for presence of `CompilerIf #PB_Compiler_IsMainFile` block in
;         include file resources (*.pbi).
;     [ ] Check for settings at the end of source file.
;     [ ] 
; [ ] Integrate functionality from Sicro's old "CodesCleaner.pb":
;     [ ] Remove any settings at the end of source file.
; [ ] New functionality:
;     [ ] Check that filename is cross-platform valid -- use CheckFilename()

;}

; ******************************************************************************
; *                                                                            *
; *                         MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule Res
  ; ============================================================================
  ;                        PUBLIC PROCEDURES DECLARATION                        
  ; ============================================================================
  Declare CheckAllResources()
EndDeclareModule

Module Res
  ; ============================================================================
  ;                        PRIVATE PROCEDURES DECLARATION                       
  ; ============================================================================
  Declare IterResChek()
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PUBLIC PROCEDURES                             *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure CheckAllResources()
    Debug ">>> CheckAllResources()"
    ; --------------------------------------------------------------------------
    ; Iterate through all resources in the CodeArchiv and carry out the required
    ; sanitation checks.
    ; NOTE: Currently doesn't carry out any checks at all!
    ; --------------------------------------------------------------------------
    ; TODO: [ ] Check that mod Archive is initialized (that project has been
    ;           scanned). If not? should it abort with error or initialize it?
    Arc::ResourcesIteratorCallback( @IterResChek() )
    
    Debug "<<< CheckAllResources()"
  EndProcedure
  
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PRIVATE PROCEDURES                            *
  ; *                                                                          *
  ; ****************************************************************************
  Procedure IterResChek()
    ;     Debug "     >>> IterResChek()"
    ; --------------------------------------------------------------------------
    ; Carries out all checks on the currently iterated resource.
    ; NOTE: Currently doesn't carry out any checks at all!
    ; --------------------------------------------------------------------------
    #tmpResType$ = "     Resource Type: "
    
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
    
    ;     Debug "     <<< IterResChek()"
  EndProcedure
  
EndModule


;-  CHANGELOG ------------------------------------------------------------------
;{  =========
;
; v0.0.2 (2018/07/09)
;   - Add skeleton code for checking all resources in the CodeArchiv:
;     - CheckAllResources() [ public proc  ]
;     - IterResChek()       [ private proc ]
; 
; v0.0.1 (2018/06/07)
;   - Created module boilerplate (no functionality).
;}


