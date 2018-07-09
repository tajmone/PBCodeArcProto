; ******************************************************************************
; *                                                                            *
; *                              Check Resources                               *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "CheckResources.pb" v0.0.1 (2018/07/09) | PureBasic 5.62 | MIT License
; ------------------------------------------------------------------------------
; Carries out integrity checks on all CodeArchiv resources.
; Mainly created to test "mod_Resources.pbi" during its creation.
; ------------------------------------------------------------------------------

;}==============================================================================
;-                                    SETUP                                     
;{==============================================================================

; ------------------------------------------------------------------------------
;-                      INCLUDE MODULES AND EXTERNAL FILES                      
; ------------------------------------------------------------------------------
XIncludeFile "pb-inc/mod_G.pbi"          ; G::     => Global Module
XIncludeFile "pb-inc/mod_CodeArchiv.pbi" ; Arc::   => CodeArchiv Module
XIncludeFile "pb-inc/mod_Resources.pbi"  ; Res::   => Resources Module
                                         ; XIncludeFile "pb-inc/mod_Errors.pbi"     ; Err::   => Errors Tracker

;}==============================================================================
;                                      MAIN                                     
;{==============================================================================

err = Arc::ScanProject()

If err
  Debug "ScanProject() reported " + Str(err) + " errors!"
EndIf
Debug "These are the contents of Arc::info\IntegrityReport:" + G::#EOL + 
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + G::#EOL + 
      Arc::info\IntegrityReport +
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + G::#EOL


Res::CheckAllResources()

;}
;- TODO LIST -------------------------------------------------------------------
;{ =========
; TODO: [ ] 
;           
;}
;- CHANGELOG -------------------------------------------------------------------
;{ =========
;
; v0.0.1 (2018/07/09)
;   - Created app skeleton, just scans the Archiv and invokes Res::CheckAllResources()
;}
