; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                        CodeArchiv Resources Module                         *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_Resources.pbi" v0.0.4 (2018/09/15) | PureBASIC 5.62 | MIT License

; Resources management module shared by all CodeArchiv tools.

; modules dependencies:
; - mod_G.pbi

;- TODO LIST -------------------------------------------------------------------
;{ =========
; [ ] Integrate the code from "HTMLPagesCreator.pb" that deals with parsing
;     resources comments headers:
;     [x] ExtractHeaderBlock()
;     [ ] ParseFileComments()
; [ ] Integrate functionality from Sicro's old "CodesChecker.pb":
;     [ ] Check code syntax via the compiler syntax checker (--check --thread).
;     [ ] Check for presence of `CompilerIf #PB_Compiler_IsMainFile` block in
;         include file resources (*.pbi).
;     [ ] Check for settings at the end of source file.
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
  ; tag::public_datatypes[]
  ; ============================================================================
  ;                              PUBLIC DATA TYPES                              
  ; ============================================================================
  ; tag::public_structures[]
  Structure KeyValPair
    key.s
    val.s
  EndStructure
  ; end::public_structures[]
  ; end::public_datatypes[]
  ; tag::public_data[]
  ; ============================================================================
  ;                           PUBLIC VARS & CONSTANTS
  ; ============================================================================
  NewList HeaderBlockL.s()          ; Extracted Header Block comment lines.
  NewList MetadataRawL.KeyValPair() ; Extracted Header key-val pairs, raw.
  
  CompilerIf Not Defined(PURGE_EMPTY_KEYS, #PB_Constant)
    Debug "#PURGE_EMPTY_KEYS: Not user defined, falling back on default value."
    #PURGE_EMPTY_KEYS = #False
  CompilerEndIf
  
  ; end::public_data[]
  ; tag::public_procedures[]
  ; ============================================================================
  ;                        PUBLIC PROCEDURES DECLARATION                        
  ; ============================================================================
  Declare   CheckAllResources()        ; WIP: Iterate all CodeArchiv resources
                                       ; and carry out sanitation checks.
  
  Declare.i ExtractHeaderBlock(file.s) ; Extract Header Block from resource file
                                       ; and store it in Res::HeaderBlockL().
                                       ; Returns total comment lines extracted.
  
  Declare.i ParseComments(file.s)      ; Parse Res::HeaderBlockL(), extrapolate
                                       ; raw key-value pairs and store them in
                                       ; Res::MetadataRawL().
                                       ; Returns total keys extracted.
  
  ; end::public_procedures[]
EndDeclareModule

Module Res
  ; ==============================================================================
  ;                           Temporary Vars & Constants                          
  ; ==============================================================================
  ; These vars and constants are being used temporarily and they should be removed
  ; later on.
  #DBGL4 = 4 ; Debug Level constant to simplify S&R operations in source code.
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
  
  ; ----------------------------------------------------------------------------
  
  Procedure.i ExtractHeaderBlock(file.s)
    ; --------------------------------------------------------------------------
    ; Extracts every consecutive comment line from beginning of file up to the
    ; first non-comment line encountered. Comment lines are stored as isolated
    ; string in `HeaderBlock()` list.
    ; Returns the number of total comment lines extracted (or zero if none).
    ; --------------------------------------------------------------------------
    ;     Debug ">>> ExtractHeaderBlock()"
    
    Shared HeaderBlockL()
    ClearList(HeaderBlockL())
    
    ; open file
    If Not ReadFile(0, file, #PB_UTF8)
      ;       Err::TrackError("Unable to open resource file for reading.")
      Debug("ERROR: Unable to open resource file for reading.")
      ProcedureReturn -1
    EndIf
    ; Skip BOM
    ReadStringFormat(0) 
    
    
    
    Define.i totLines = 0
    Repeat
      line.s = ReadString(0)
      
      If Left(line, 1) <> ";"
        ;         Debug "<<< ExtractHeaderBlock()"
        CloseFile(0)
        ProcedureReturn totLines ; -> Exit point
      Else
        AddElement(HeaderBlockL())
        HeaderBlockL() = line
        totLines +1
      EndIf
    ForEver
    
  EndProcedure
  
  Procedure.i ParseComments(file.s)
    ; ----------------------------------------------------------------------------
    ; Parse the List of extracted comment-lines and extrapolate key-value pairs.
    ; Keys with empty values are preserved! FIXME: Drop empty keys
    ; Returns the number of total keys extracted (Or zero If none).   
    ; ----------------------------------------------------------------------------
    Debug ">>> ParseComments()", #DBGL4
    
    Shared HeaderBlockL(), MetadataRawL()
    ClearList(MetadataRawL())

    totLines = ListSize( HeaderBlockL() )
    
    lineCnt = 1
    dbgIndent.s = "  | "
    
    ForEach HeaderBlockL()
      lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
      commDelim.s = Left(HeaderBlockL(), 3)
      If commDelim = ";: " Or commDelim = ";{:"  Or commDelim = ";}:"
        Debug lineNum + "Parse:", #DBGL4
        ;  ===========
        ;- Extract Key
        ;  ===========
        key.s = Trim(StringField(HeaderBlockL(), 2, ":"))
        Debug dbgIndent + "- key found: '" + key +"'", #DBGL4
        ;  =============
        ;- Extract Value
        ;  =============
        valueStart = FindString(HeaderBlockL(), ":", 4)
        value.s = Trim(Mid(HeaderBlockL(), valueStart +1))
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
          
          NextElement(HeaderBlockL())
          lineCnt +1
          
          commDelim.s = Left(HeaderBlockL(), 3)
          If Left(commDelim, 2) = ";." Or commDelim = ";{."  Or commDelim = ";}."
            
            ;- Carry-on line found
            ;  ~~~~~~~~~~~~~~~~~~~
            carryOn = #True
            valueNew.s = Trim(Mid(HeaderBlockL(), 4))
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
              AddElement(MetadataRawL())
              MetadataRawL()\key = key
              MetadataRawL()\val = value
            Else
              ; Skip Empty Key
              ; ~~~~~~~~~~~~~~
              ; TODO: Should debug this differently according to current DBG Level
              ;             Debug "~ Purged empty key: " + key, #DBGL3           
            EndIf
            ; Roll-back List Element and line counter...
            PreviousElement(HeaderBlockL())
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
    ProcedureReturn ListSize( MetadataRawL() )
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
    
    ; ==============================================================================
    ;                         Extract and Print HeaderBlock                         
    ; ==============================================================================
    Shared HeaderBlockL()
    
    totHeaderLines = ExtractHeaderBlock(G::CodeArchivPath + Arc::Current\Resource\Path)
    If totHeaderLines = -1
      Debug "     ERROR!!! Failed To extract Header Block"
    Else
      Debug "     Resource's Header Block (" + totHeaderLines + " lines):"
      Debug "     " + G::#DIV3$
      ForEach HeaderBlockL()
        Debug "     " + HeaderBlockL()
      Next
      Debug "     " + G::#DIV3$ + G::#EOL
    EndIf 
    ; ==============================================================================
    ;                          Extract HeaderBlock Metadata                         
    ; ==============================================================================
    Shared MetadataRawL()
    
    totEntries = ParseComments(G::CodeArchivPath + Arc::Current\Resource\Path)
    If totEntries <= 0
      Debug "     ERROR!!! No key-vals extracted"
    Else
      Debug "     Resource's Metadata (" + totEntries + " keys):"
      Debug "     " + G::#DIV3$
      i = 1
      pad =  5 + Len(Str(totEntries))
      ForEach MetadataRawL()
        MarginL$ = RSet(Str(i), pad) + ". "
        Debug MarginL$ + MetadataRawL()\key + ": " + MetadataRawL()\val
        i+1
      Next
      Debug "     " + G::#DIV3$
    EndIf 
    
    
    ; ---------------------------
    
    ;     Debug "     <<< IterResChek()"
  EndProcedure
  
EndModule


;-  CHANGELOG ------------------------------------------------------------------
;{  =========
; v0.0.4 (2018/09/15)
;   - Add ParseComments(), taken from "HTMLPagesCreator.pb" and readapted.
;     Store extracted in Res::MetadataRawL(), a List of key-val pairs.
; v0.0.3 (2018/09/15)
;   - Add ExtractHeaderBlock(), taken from "HTMLPagesCreator.pb" and readapted.
;     Store extracted header in Res::HeaderBlockL(), a List of strings.
; v0.0.2 (2018/07/09)
;   - Add skeleton code for checking all resources in the CodeArchiv:
;     - CheckAllResources() [ public proc  ]
;     - IterResChek()       [ private proc ]
; 
; v0.0.1 (2018/06/07)
;   - Created module boilerplate (no functionality).
;}


