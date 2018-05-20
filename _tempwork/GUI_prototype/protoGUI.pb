; ******************************************************************************
; *                                                                            *
; *                       HTMLPagesCreator GUI Prototype                       *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "protoGUI.pb" v0.0.1 (2018/05/20) | PureBasic 5.62 | MIT License

; A prototype of the GUI; currently just testing what it should look like to be
; clean and simple to use.

; NOTE on DialogLib — We won't be using the PB Dialog library here, due to the
;     Linux packages problems with webkitgtk (GTK+ 3) and webkitgtk2 (GTK+ 2)
;     mentioned by Sicro at Issue #10:
;     https://github.com/tajmone/PBCodeArcProto/issues/10#issuecomment-387163857

; ==============================================================================
;                                  GUI Settings                                 
; ==============================================================================
; Some basic constants to easily handle basic settings...
#WinW = 800 ; GUI Width
#WinH = 400 ; GUI Height

#WinF = #PB_Window_SystemMenu     | #PB_Window_MinimizeGadget | ; GUI Flags
        #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered

If Not OpenWindow(0, #PB_Ignore, #PB_Ignore, #WinW, #WinH, "PureBasic Window", #WinF)
  ; --------------------------------
  ; Something went terribly wrong...
  ; --------------------------------
  MessageRequester("ERROR!", "OpenWindow() failed miserably!", #PB_MessageRequester_Error)
  End 1
EndIf

; ==============================================================================
;                                   Main Loop                                   
; ==============================================================================
; Just for testing the GUI look and feel...
Repeat
  Event = WaitWindowEvent()
  
  If Event = #PB_Event_CloseWindow
    CloseGUI = #True
  EndIf
  
Until CloseGUI
