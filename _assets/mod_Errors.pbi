; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                           Errors Tracker Module                            *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_Errors.pbi" v0.0.2 (2018/05/16) | PureBASIC 5.62

; Error management module shared by all CodeArchiv tools.

; modules dependencies:
; - mod_G.pbi

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;- ERRORS HANDLING
;{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Some helpers to handle Errors. There are two types of errors:
;  (1) Fatal-Errors (always abort)
;  (2) Errors       (user is asked if he wants to abort or continue)
;
; Errors and their details are printed to the debug window at the time of their
; occurence, and they are also tracked so that they keen be included in the final
; report at the end.
;}------------------------------------------------------------------------------

; ******************************************************************************
; *                                                                            *
; *                         MODULE'S PUBLIC INTERFACE                          *
; *                                                                            *
; ******************************************************************************
DeclareModule Err
  ; TODO: Clean up public interface and add comments
  
  #Failure = #False
  #Success = #True
  
  ; Define Error-Types which lead to aborting execution:
  Enumeration FatalErrTypes
    #FATAL_ERR_GENERIC
    #FATAL_ERR_INTERNAL
    #FATAL_ERR_FILE_ACCESS
    #FATAL_ERR_PANDOC
  EndEnumeration
  totFatalErrTypes = #PB_Compiler_EnumerationValue -1
  
  ; ==============================================================================
  ;-                        PUBLIC PROCEDURES DECLARATION                         
  ; ==============================================================================
  Declare Abort(ErrorMsg.s, ErrorType = #FATAL_ERR_GENERIC)
  Declare TrackError(ErrMessage.s)
  ; ==============================================================================
  
  Define.s currCat ; Always = crurrent Category path (relative to project root)
  Define.s currRes ; Always = crurrent Resource filename OR empty if none.
  
  Structure FatalErrData
    Title.s     ; Error-Type Title
    Desc.s      ; Error-Type Description
  EndStructure
  
   ;-***************
  
  ; Errors/Warnings as stored as structured entries by the Tracker:
  Structure ErrData
    ErrCat.s        ; <= stores copy of currCat
    ErrRes.s        ; <= stores copy of currRes
    ErrMsg.s        ; <= stores Message
  EndStructure
  
  NewList ErrTrackL.ErrData() ; List to store Error messages and details
  
EndDeclareModule

; ******************************************************************************

Module Err
  
  
  ; Array to associate Error-Types to their messages:
  Dim FatalErrTypeInfo.FatalErrData(totFatalErrTypes)
  
  For i=0 To totFatalErrTypes
    Read.s FatalErrTypeInfo(i)\Title 
    Read.s FatalErrTypeInfo(i)\Desc 
  Next
  
  FatalErrorMessages:
  DataSection
    Data.s "FATAL ERROR", "The application encountered an fatal error."
    Data.s "INTERNAL ERROR", "The application encountered an internal error; if the problem persists contact the author."
    Data.s "FILE ACCESS ERROR", "The application encountered an error while trying to access a project file for I/O operations."
    Data.s "PANDOC ERROR", "An error was encountered while interacting with pandoc."
    ;   Data.s "", ""
  EndDataSection
  
  ; ******************************************************************************
  ; *                                                                            *
  ; *                             PUBLIC PROCEDURES                              *
  ; *                                                                            *
  ; ******************************************************************************
    Procedure Abort(ErrorMsg.s, ErrorType = #FATAL_ERR_GENERIC)
    ; ------------------------------------------------------------------------------
    ; Abort execution by reporting the Error-Type and its default description,
    ; followed by the specific error description. Abort message is both printed to
    ; debug output window and shown in MessageRequester.
    ; ------------------------------------------------------------------------------
    Shared FatalErrTypeInfo()
    
    ErrTypeTitle.s = FatalErrTypeInfo(ErrorType)\Title
    ErrTypeDesc.s  = FatalErrTypeInfo(ErrorType)\Desc
    
    Debug G::#DIV6$ + G::#EOL + G::#DIV5$
    Debug ErrTypeTitle + " — " + ErrTypeDesc + G::#EOL2 + ErrorMsg + G::#EOL
    Debug "Aborting program execution..."
    Debug G::#DIV5$ + G::#EOL + G::#DIV7$
    
    MessageRequester(ErrTypeTitle, ErrTypeDesc + G::#EOL2 + ErrorMsg + G::#EOL2 +
                                   "Aborting execution...", #PB_MessageRequester_Error)
    
    ; TODO: Show Warnings resume before aborting
    End 1
    
  EndProcedure
  
  Procedure TrackError(ErrMessage.s)
    ; ------------------------------------------------------------------------------
    ; Handle Errors and their messages.
    ; 1) Print error info to debug windows at time of occurence
    ;    (if curr DebugLevel or setttings allow it)
    ; 2) Store error info for the final resume.
    ; ------------------------------------------------------------------------------  
    Shared ErrTrackL()
    Shared currCat, currRes
    ; =======================================
    ; Show Error message at time of occurence
    ; =======================================
    Debug G::#DIV6$ + G::#EOL + G::#DIV5$
    Debug "WARNING!!! While processing: " + currCat + currRes + G::#EOL + G::#DIV4$ + G::#EOL +
          ErrMessage
    Debug G::#DIV5$ + G::#EOL + G::#DIV7$
    ; ====================================
    ; Store Error details for final report
    ; ====================================
    AddElement( ErrTrackL() )
    ErrTrackL()\ErrCat = currCat
    ErrTrackL()\ErrRes = currRes
    ErrTrackL()\ErrMsg = ErrMessage
    
  EndProcedure
  
EndModule
