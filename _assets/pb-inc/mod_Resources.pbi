; ******************************************************************************
; *                                                                            *
; *                        PureBasic CodeArchiv Rebirth                        *
; *                                                                            *
; *                        CodeArchiv Resources Module                         *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "mod_Resources.pbi" v0.0.1 (2018/06/07) | PureBASIC 5.62 | MIT License

; Resources management module shared by all CodeArchiv tools.

; modules dependencies:
; - mod_G.pbi

;- TODO LIST -------------------------------------------------------------------
;{ =========
; [ ] Integrate the code from "HTMLPagesCreator.pb" that deals with parsing
;     resources comments headers.
;     [ ] 
; [ ] Integrate functionality from Sicro's old "CodesChecker.pb":
;     [ ] Check code syntax via the compiler syntax checker (--check --thread).
;     [ ] Check for presence of `CompilerIf #PB_Compiler_IsMainFile` block in
;         include file resources (*.pbi).
;     [ ] Check for settings at the end of source file.
;     [ ] 
; [ ] Integrate functionality from Sicro's old "CodesCleaner.pb":
;     [ ] Remove any settings at the end of source file.
;     [ ] 
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
  
EndDeclareModule

Module Res
  ; ============================================================================
  ;                        PRIVATE PROCEDURES DECLARATION                       
  ; ============================================================================
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PUBLIC PROCEDURES                             *
  ; *                                                                          *
  ; ****************************************************************************
  
  ; ****************************************************************************
  ; *                                                                          *
  ; *                            PRIVATE PROCEDURES                            *
  ; *                                                                          *
  ; ****************************************************************************
  
EndModule


;-  CHANGELOG ------------------------------------------------------------------
;{  =========
;
; v0.0.1 (2018/06/07)
;   - Created module boilerplate (no fucntionality).
;}


