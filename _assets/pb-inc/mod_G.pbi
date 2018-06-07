; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                               Global Module                                *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_G.pbi" v0.0.13 (2018/06/07) | PureBASIC 5.62 | MIT License

; Stores Data shared by any tool dealing with CodeArchiv and its resources.

; Since it might be also used by tools targetting single resources, it shouldn't
; store data relating to the CodeArchiv structure (categories, etc.) but only to
; the strictly necessary common code parts.

; modules dependencies: none.

;{ -- TODOs LIST »»»------------------------------------------------------------
; TODO:
;} -- TODOs LIST «««------------------------------------------------------------

; ******************************************************************************
; *                                                                            *
; *                         MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule G
  ; ============================================================================
  ;                           PUBLIC VARS & CONSTANTS
  ;{============================================================================
  ; The following variables and constants are exposed publicly to be usable by
  ; all modules dealing with the CodeArchiv.
  ; ----------------------------------------------------------------------------
  ; Cross Platform Helpers
  ;{----------------------------------------------------------------------------
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
  ;}----------------------------------------------------------------------------
  ; CodeArchiv Constants
  ; ----------------------------------------------------------------------------
  ; RESOURCE TYPES
  ; ==============
  Enumeration 
    #ResT_PBSrc     ; PB Source        -> *.pb
    #ResT_PBInc     ; PB Include File  -> *.pbi
    #ResT_Folder    ; Folder Resource  -> "CodeInfo.txt"
  EndEnumeration
  
  ; RESOURCE TYPES FLAGS
  ; ====================
  ; Useful as parameter for filtering resource types.
  EnumerationBinary
    #ResTF_PBSrc    ; PB Source        -> *.pb
    #ResTF_PBInc    ; PB Include File  -> *.pbi
    #ResTF_Folder   ; Folder Resource  -> "CodeInfo.txt"    
  EndEnumeration
  #ResTF_Any = #ResTF_PBSrc | #ResTF_PBInc | #ResTF_Folder
  
  ;}----------------------------------------------------------------------------
  ; CodeArchiv Special Files, Folders and Paths
  ; ----------------------------------------------------------------------------
  ; CodeArchiv's special files and folders names are stored here, globally, so
  ; that if the need to change them ever arises it can be handled in a single
  ; place, affecting all tools without any breaks. Some conventions used:
  ; - Paths will always end with a directory separator (#DSEP).
  ; - Folders and files names are case senstivie for cross-platformness' sake.
  ; ----------------------------------------------------------------------------
  #CodeInfoFile  = "CodeInfo.txt" ; <- found in multi-file subfoldered resources
  #AssetsFolder  = "_assets"
  #ModulesFolder = "pb-inc"
  
  ; WebSite Settings Files
  #YAMLSettingsFile  = "meta.yaml"

  ; The following absolute paths will be initialized by the module at inclusion:
  Define.s CodeArchivPath ; Abs path to CodeArchiv's Root.
  Define.s AssetsPath     ; Abs path to Assets folder.

  ;}============================================================================
  ;                       CROSS-MODULE REGEX ENUMERATIONS
  ;{============================================================================
  ; (RegExs IDs are "global" and module independent)
  ; Declare a common RegEx Enumeration Identifier to keep track of the RegExs ID
  ; across modules, otherwise Enums will start over from 0 and overwrite existing
  ; RegExs! Other modules' Enums will take on from here by:
  ;
  ;     Enumeration G::RegExsIDs
  ;
  ; ----------------------------------------------------------------------------
  ; NOTE: This Enumeration must be public! The rest of the modules' RegEx Enums
  ;       don't have to, they can be private to their module...
  ; ----------------------------------------------------------------------------
  Enumeration RegExsIDs
    ; This Enum block it's empty because here we only need to set the Enum ID.
  EndEnumeration
  
  ;}============================================================================
  ;                                     MACROS                                    
  ; ============================================================================
  
  ; ====================
  ; Counter String Macro
  ; ====================
  ; String helper for generating an aligned counter for numbered lists strings.
  ; Requires the following vars to be set:
  ;   - cnt  : (int) counter number.
  ;   - cntW : (int) number of digits of the highest counter.
  ; Converts a numeric counter (cnt) to a string aligned according to the number
  ; of digits of the highest entry (cntW), followed by a trailing dot and space.
  Macro CntStrM
    RSet(Str(cnt), cntW) + ". "
  EndMacro
  
  ; ----------------------------------------------------------------------------
  ;                        Horizontal Dividers Constants
  ; ----------------------------------------------------------------------------
  ; These constants have been moved temporarily here, to simplify splitting code.
  ; They might be moved elsewhere in the future.
  #DIV1$ = "================================================================================"
  #DIV2$ = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  #DIV3$ = "~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~="
  #DIV4$ = "--------------------------------------------------------------------------------"
  #DIV5$ = "********************************************************************************"
  #DIV6$ = "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"
  #DIV7$ = "////////////////////////////////////////////////////////////////////////////////"

EndDeclareModule

Module G
  ; ****************************************************************************
  ; *                                                                          *
  ; *                    MODULE INCLUDE-TIME INITIALIZATION                    *
  ; *                                                                          *
  ; ****************************************************************************
  ; The following initialization will occur at the time and place of the module's
  ; inclusion by main code.
  ; ============================================================================
  ;- 1.   Define Special CodeArchiv Paths
  ;{============================================================================
  ; mod_G makes the following assumptions:
  ;
  ;  - all CodeArchi apps and tools are in the "_assets/" folder.
  ;  - all modules are located in the "_assets/pb-inc/" folder.
  ;  - the main importing code could be either an app or another module being
  ;    test-run on its own.
  ;
  ; Based on the above assumption, it will determine the CodeArchiv's root path
  ; relatively to the Current Directory path; and then define all the public
  ; path vars accordingly. Checks are carried out to ascertain that the root
  ; path is correctly defined, failing which the modules aborts execution.
  ;   But if the importing app is not located in "_assets/" or "_assets/pb-inc/",
  ; then it must help mod_G to get the Archiv path right by manually setting the
  ; current directory to the Archiv root folder BEFORE importing "mod_G.pbi".
  ;   Manually redefining ALL path vars AFTER importing mod_G wouldn't be a viable
  ; solution because future versions of the G module might introduce new path-vars,
  ; and manual fixes would not cover them all, exposing other modules to potential
  ; errors and erratic behavior.
  ;}============================================================================
  ;- 1.1  G::CodeArchivPath (root)
  ;{============================================================================
  ; Usually, the main code importing the module will be a tool in the "_assets/"
  ; folder, and the Archiv root will be one level up.
  ;   Some modules in this folder can also be run on their own (for testing), in
  ; which case they would be the main code including this module. Thus we also
  ; check for the presence of "pb-inc" at the end of CurrentDirectory, in which
  ; case the CodeArchiv root will be two levels up:
  CurrDir.s = GetCurrentDirectory() ; <- always ends with directory separator!
  If Right(CurrDir, Len(#ModulesFolder)+1) = #ModulesFolder + #DSEP
    ; If CurrDir ends with "pb-inc/"...
    ; ---------------------------------------------------------------
    ; mod_G is being imported by another module in "_assets/pb-inc/":
    ; ---------------------------------------------------------------
    SetCurrentDirectory("../../")
  ElseIf Right(CurrDir, Len(#AssetsFolder)+1) = #AssetsFolder + #DSEP
    ; If CurrDir ends with "_assets/"...
    ; ------------------------------------------------
    ; mod_G is being imported by a tool in "_assets/":
    ; ------------------------------------------------
    SetCurrentDirectory("../")
  EndIf
  ; If none of the above was true, we assume that Curr Dir was manually set to
  ; the CodeArchiv's root by the importing code.
  ; ----------------------------------------------------------------------------
  ; Check that we're really in project's root
  ; ----------------------------------------------------------------------------
  ; To be 100% sure that Curr Dir now points to the Archiv's root, we'll check
  ; for the presence of the "_assets" folder.
  If FileSize(#AssetsFolder) <> -2
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ; WARN & ABORT: Unable to determine CodeArchiv Path
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MessageRequester("mod_G Error",
                     ~"mod_G.pbi wasn't able to determine the path of CodeArchiv!\n"+
                     ~"Please, use SetCurrentDirectory() to manually point to "+
                     "the Archiv's root before importing mod_G!",
                     #PB_MessageRequester_Error)
    End 1
  EndIf

  CodeArchivPath = GetCurrentDirectory()

  ; Restore Previous Current Directory
  ; ----------------------------------
  ; (make no assumption on what the tool invoking this module might be doing)
  SetCurrentDirectory(CurrDir)
  ;}============================================================================
  ;- 1.2  G::AssetsPath
  ; ============================================================================
  AssetsPath = CodeArchivPath + #AssetsFolder + #DSEP

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
  MessageRequester("CodeArchivPath", G::CodeArchivPath)
  MessageRequester("AssetsPath", G::AssetsPath)
CompilerEndIf
