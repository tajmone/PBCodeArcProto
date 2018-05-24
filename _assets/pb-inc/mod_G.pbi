; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                               Global Module                                *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_G.pbi" v0.0.7 (2018/05/24) | PureBASIC 5.62 | MIT License

; Stores Data shared by any tool dealing with CodeArchiv and its resources.

; Since it might be also used by tools targetting single resources, it shouldn't
; store data relating to the CodeArchiv structure (categories, etc.) but only to
; the strictly necessary common code parts.

; modules dependencies: none.

;{ -- TODOs LIST »»»------------------------------------------------------------
; TODO: Add G::AssetsPath (remember to include ending dir separator).
; TODO: I should make the module abort code execution if it doesn't initialize
;       properly -- Eg, if it doesn't manage to determine Archiv Root path.
; TODO: Add some check if Archiv Root path was calculated correctly -- some files
;       are expected to be in root folder (.gitattributes, settings, etc), I could
;       rely on these to confirm the path was correct.
; TODO: 
;} -- TODOs LIST «««------------------------------------------------------------

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
  ; CodeArchiv's special files and folders names are stored here, globally, so
  ; that if the need to change them ever arises it can be handled in a single
  ; place, affecting all tools without any breaks.
  ; ----------------------------------------------------------------------------
  #CodeInfoFile  = "CodeInfo.txt" ; found in multi-file subfoldered resources
  #AssetsFolder  = "_assets"
  #ModulesFolder = "pb-inc"
  
  ; The following absolute paths will be set by this module at inclusion time:
  Define.s CodeArchivPath ; Abs path to CodeArchiv's Root.
  Define.s AssetsPath     ; Abs path to Assets folder.
  
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
  ;                           Define CodeArchiv Paths                           
  ; ============================================================================
  ; TODO: Should verify that GetCurrentDirectory() returns path ending with dir
  ;       separator on all OS -- or either do the check myself, here.
  ; mod_G makes the following assumptions:
  ;
  ;  - all CodeArchi apps and tools are in the "_assets/" folder.
  ;  - all modules are located in the "_assets/pb-inc/" folder.
  ;  - the main importing code could be either an app or another module being
  ;    test-run on its own.
  ;
  ; Based on the above assumption, it will determine the CodeArchiv's root path
  ; relatively to the Current Directory path; and then define all the public
  ; path vars accordingly.
  ;
  ; But if the importing app is not located in "_assets/" or "_assets/pb-inc/",
  ; then it must help mod_G to get the Archiv path right by manually setting the
  ; current directory to the "_assets/" folder BEFORE importing "mod_G.pbi".
  ;   Alternatively, it could manually redefine ALL path vars AFTER importing
  ; mod_G, but the former solution is preferable because it will ensure that all
  ; vars based on the root path will be set correctly -- in the future, new path
  ; variables might be added to mod_G, and manual fixes might not cover them all,
  ; exposing other modules to potential errors!
  ; ----------------------------------------------------------------------------
  ; Define CodeArchiv Path (root)
  ; ----------------------------------------------------------------------------
  ; Some modules in this folder can also be run on their own (for testing), in
  ; which case they would be the main code including this module. Thus we also
  ; check for the presence of "pb-inc" at the end of CurrentDirectory, in which
  ; case the CodeArchiv root will be two levels up:
  If FindString( ReverseString( GetCurrentDirectory() ),
                 ReverseString(#ModulesFolder) )
    ; mod_G is being imported by another module:
    SetCurrentDirectory("../../")
  Else
    ; we assume mod_G is being imported by a tool in "_assets/":
    SetCurrentDirectory("../")
  EndIf
  ; TODO: Add in ELSE further check that path ends with #AssetsFolder, else the
  ;       module should fail initialization, raise compiler error and abort!

  CodeArchivPath = GetCurrentDirectory()
  ; ----------------------------------------------------------------------------
  ; Define Assets Path
  ; ----------------------------------------------------------------------------
  AssetsPath = CodeArchivPath + #AssetsFolder + #DSEP
  
;   MessageRequester("CodeArchivPath", CodeArchivPath)
;   MessageRequester("AssetsPath", AssetsPath)
;   End
  
EndModule
