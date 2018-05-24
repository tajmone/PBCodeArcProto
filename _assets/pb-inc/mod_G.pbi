; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                               Global Module                                *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_G.pbi" v0.0.6 (2018/05/24) | PureBASIC 5.62 | MIT License

; Stores Data shared by any tool dealing with CodeArchiv and its resources.

; Since it might be also used by tools targetting single resources, it shouldn't
; store data relating to the CodeArchiv structure (categories, etc.) but only to
; the strictly necessary common code parts.

; modules dependencies: none.

; ******************************************************************************
; *                                                                            *
; *                         MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule G
  
  ; ============================================================================
  ;                           CROSS PLATFORM SETTINGS                           
  ; ============================================================================
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
  
  ; ============================================================================
  ;                       CROSS-MODULE REGEX ENUMERATIONS                       
  ; ============================================================================
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
  ; ============================================================================
  ;                           PUBLIC VARS & CONSTANTS                           
  ; ============================================================================
  #CodeInfoFile = "CodeInfo.txt" ; found in multi-file subfoldered resources
  
  Define.s CodeArchivPath ; Abs path to CodeArchiv's Root. (str set by this mod)
  #AssetsFolder = "_assets" + #DSEP

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
  ; ----------------------------------------------------------------------------
  ;                            Define CodeArchiv Path                           
  ; ----------------------------------------------------------------------------
  ; We assume that all modules are are in the "_assets/pb-inc/" folder, and that
  ; the main apps including the modules are in "_assets/". Therefore the Archiv's
  ; root should always be one level up relatively to the main app importing this
  ; module.
  ;   Some modules in this folder can also be run on their own (for testing), in
  ; which case they would be the main code including this module. Thus we also
  ; check for the presence of "pb-inc" at the end of CurrentDirectory, in which
  ; case the CodeArchiv root will be two levels up:
  If FindString( ReverseString( GetCurrentDirectory() ), "cni-bp")
    ; mod_G is being imported by another module:
    SetCurrentDirectory("../../")
  Else
    ; we assume mod_G is being imported by a tool in "_assets/":
    SetCurrentDirectory("../")
  EndIf
  ; But if the importing app is located in another position, then G::CodeArchivPath
  ; will not be corretct and the app will have to either:
  ;   1. SetCurrentDirectory to "_assets/" BEFORE importing mod_G
  ;   2. Manually override G::CodeArchivPath AFTER importing mod_G
  ;    
  CodeArchivPath = GetCurrentDirectory()
  
  MessageRequester("CodeArchivPath", CodeArchivPath)
;   End
  
  
EndModule
