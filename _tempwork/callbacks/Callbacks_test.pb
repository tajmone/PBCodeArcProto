
; This file tests the possibility of using the same parameter to pass either:
;  -- a Callback Procedure pointer, or
;  -- a negative integer (Enumerated options)

Declare TestProc(callback_param.i)
Declare SampleCallBack()

Enumeration enum_opts 0 Step -1
  #Do_Nothing
  #OptOne
  #OptTwo
  #OptThree
EndEnumeration

TestProc(#Do_Nothing)
TestProc(#OptTwo)
TestProc(@SampleCallBack())

Debug "Test completed without errors."
End

; ==============================================================================
;                                   PROCEDURES                                  
; ==============================================================================

Procedure TestProc(callback_param.i)
  Debug LSet("", 20, "=")
  Debug "TestProc() Invoked with param:"
  
  If callback_param <= 0
    ; ----------------------------------
    ; Parameter not a Procedure pointer!
    ; ----------------------------------
    Select callback_param
      Case #Do_Nothing
        Debug "0: Do Nothing!"
      Case #OptOne
        Debug "-1: Option Number One."
      Case #OptTwo
        Debug "-2: Option Number Two."
      Case #OptThree
        Debug "-3: Option Number Theww."
      Default
        Debug "UNKNOWN OPTION: " + Str(callback_param)
    EndSelect
  Else  
    ; ---------------------------------
    ; Parameter is a Procedure pointer!
    ; ---------------------------------
    hex_pointer$ = "0x" + RSet(Hex(callback_param), SizeOf(callback_param)*2, "0")
    Debug "A Procedure pointer: " + Str(callback_param) + " (hex: " + hex_pointer$ + ")"
    
    CallFunctionFast(callback_param)
  EndIf
  
  Debug "Leaving TestProc()..."
  Debug LSet("", 20, "=")
EndProcedure


Procedure SampleCallBack()
  Debug LSet("", 34, "-")
  Debug "Hello, I'm the CallBack procedure!"
  Debug LSet("", 34, "-")
EndProcedure