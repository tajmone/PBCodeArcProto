;{ "detect-folder-changes.pb" v1.0.0 (2018/07/15) | PureBasic 5.62
; ******************************************************************************
; *                                                                            *
; *                       Test Folder Changes Detection                        *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; *                                MIT License                                 *
; *                                                                            *
; ******************************************************************************
; Create a Window with a button that every time it's pressed will get the
; #PB_Date_Modified attribute of the "test" folder and compare it with the
; previously stored value to check if the folder was modified since last click.
;
; Date attributes are shown (and evalued) in a human readable TimeStamp string.
;
; This code is aimed at testing if PB can accurately detect file changes inside
; a directory, becasue it could be useful when refreshing/checking the list of
; categories and resources: it could tell us if there were any changes in a
; category tree, without having to scan it all over again.
;{------------------------------------------------------------------------------
;                             The MIT License (MIT)                             
; ------------------------------------------------------------------------------
; Copyright (c) 2018 Tristano Ajmone, https://github.com/tajmone
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
; THE SOFTWARE.
;}
;}
; ==============================================================================
;                                     Set-Up                                    
;{==============================================================================
Dir$ = "test"
#TSForm$ = "%yyyy-%mm-%dd %hh:%ii:%ss" ; TimeStamp format
currDir.s = GetCurrentDirectory()
; ------------------------------------------------------------------------------
;                             Macros and Procedures                             
; ------------------------------------------------------------------------------
Procedure.s GetFolderTimeStamp()
  ; ----------------------------------------------------------------------------
  ; NOTE: A new ExamineDirectory() command must be used at each check, otherwise 
  ;       DirectoryEntryDate() will keep reporting the Attribute value as it was
  ;       at the time ExamineDirectory() was called!
  ; ----------------------------------------------------------------------------
  Shared currDir, Dir$
  ; =================================
  ; Open folder to get a handle on it
  ; =================================
  If Not ExamineDirectory(0, currDir, Dir$)
    ProcedureReturn
  EndIf
  
  If Not NextDirectoryEntry(0)
    ProcedureReturn
  EndIf
  ; =====================================================
  ; Convert #PB_Date_Modified to human readable TimeStamp
  ; =====================================================
  TimeStamp.s = FormatDate(#TSForm$, DirectoryEntryDate(0, #PB_Date_Modified))
  FinishDirectory(0)
  ProcedureReturn TimeStamp
EndProcedure
; ------------------------------------------------------------------------------
;                                   Initialize                                  
;{------------------------------------------------------------------------------

; =======================================
; If test folder doesn't exist create it:
; =======================================
If FileSize(Dir$) <> -2
  If Not CreateDirectory(Dir$)
    Debug ~"ERROR: Unable to create \"" + Dir$ + ~"\" folder!"
    End 1
  EndIf
EndIf

; ================================
; Get Initial TimeStamp of Folder:
; ================================
CurrDate.s = GetFolderTimeStamp()
PrevDate.s = CurrDate
ErrDate.s  = RSet(#Empty$, Len(CurrDate), "?")
; Debug CurrDate
; Debug PrevDate
;}------------------------------------------------------------------------------
;                                   Build GUI                                   
; ------------------------------------------------------------------------------
Green  = RGB(84, 255, 159)
Red    = RGB(255, 106, 106)
Yellow = RGB(255, 255, 0)
; ================
; Gadget Constants
; ================
Enumeration
  #StatusTxt  ; Change-Status Text
  #PrevLabel  ; Label for Previous Date
  #PrevDate   ; Previous Date TimeStamp
  #CurrLabel  ; Label for Current Date
  #CurrDate   ; Current Date TimeStamp
  #Button     ; Refresh Button
EndEnumeration

#GapY = 30
#TxtH = 20
#LabW = 90
#DateX = 10 + #LabW + 10
#DateW = 190
#StatW = #LabW + 10 + #DateW
#BtnW = 80
#BtnH = 30
#BtnX = (#StatW - #BtnW) / 2

; ================
; Window Constants
; ================
#WinT = "Get Folder's Last Modified Date"
#WinW = #StatW + 20
#WinH = (#GapY * 3) + #BtnH + 20
#WinF = #PB_Window_ScreenCentered | #PB_Window_SystemMenu

; =================================
; Set a Monospaced Font as Default:
; =================================
If LoadFont(0, "Courier New", 12)
  SetGadgetFont(#PB_Default, FontID(0))
EndIf

OpenWindow(0, #PB_Ignore, #PB_Ignore, #WinW, #WinH, #WinT, #WinF)

y = 10
TextGadget(#StatusTxt, 10, y, #StatW, #TxtH, "(click to detect changes)", #PB_Text_Center)
SetGadgetColor(#StatusTxt, #PB_Gadget_BackColor, Yellow)

y + #GapY
TextGadget(#PrevLabel, 10, y, #LabW, #TxtH, "Previous:", #PB_Text_Right)
TextGadget(#PrevDate, #DateX, y, #DateW, #TxtH, PrevDate)

y + #GapY
TextGadget(#CurrLabel, 10, y, #LabW, #TxtH, "Current:", #PB_Text_Right)
TextGadget(#CurrDate, #DateX, y, #DateW, #TxtH, CurrDate)

y + #GapY
ButtonGadget(#Button, #BtnX, y, #BtnW, #BtnH, "CHECK")


;}==============================================================================
;                                   Main Loop                                   
; ==============================================================================
Repeat
  
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_CloseWindow
      Quit = 1
    Case #PB_Event_Gadget
      If EventGadget() = #Button
        ;  =====================================================================
        ;- Refresh Folder Status
        ;  =====================================================================
        newDate.s = GetFolderTimeStamp()
        If newDate = #Empty$
          ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          ; Failed to get folder 'Date_Modified' attribute
          ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          StatusText.s = "ERROR ACCESING FOLDER"
          SetGadgetColor(#StatusTxt, #PB_Gadget_BackColor, Yellow)
          PrevDate = CurrDate
          CurrDateTxt.s = ErrDate.s
        Else
          ; ------------------------------------------
          ; Succeeded to get 'Date_Modified' attribute
          ; ------------------------------------------
          If CurrDate = newDate
            StatusText.s = "no changes detected"
            SetGadgetColor(#StatusTxt, #PB_Gadget_BackColor, Green)
            PrevDate = CurrDate
            CurrDateTxt.s = CurrDate
            PrevDate.s    = PrevDate
          Else
            StatusText.s = "folder was changed"
            SetGadgetColor(#StatusTxt, #PB_Gadget_BackColor, Red)
            PrevDate = CurrDate
            CurrDate = newDate
            CurrDateTxt.s = CurrDate
            PrevDate.s    = PrevDate
          EndIf
        EndIf        
        ;  =====================================================================
        ;- Refresh Gadgets Text
        ;  =====================================================================
        ;  NOTE: The text of CurrDate gadget won't reflect the actual CurrDate
        ;        value when GetFolderTimeStamp() returns an error!
        ;  ---------------------------------------------------------------------
        SetGadgetText(#StatusTxt, StatusText)
        SetGadgetText(#PrevDate,  PrevDate)
        SetGadgetText(#CurrDate,  CurrDateTxt) ; -> not always == CurrDate!
      EndIf
  EndSelect
  
Until Quit = 1

; ==============================================================================
;                                Wrap-Up and Exit                               
; ==============================================================================
End 0
