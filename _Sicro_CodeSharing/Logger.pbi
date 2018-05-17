; by Sicro 2018 (2018/05/18)

DeclareModule Logger
  
  EnableExplicit
  
  Enumeration
    #OutputType_Debug
    #OutputType_File
    #OutputType_ListGadget
    #OutputType_Callback
  EndEnumeration
  
  Declare Create(LoggerName$, OutputType, OutputObject = 0)
  Declare Delete(LoggerName$)
  Declare SetLevel(LoggerName$, Level)
  Declare AddLog(LoggerName$, Text$, Level = 0)
  
EndDeclareModule

Module Logger
  
  Structure LoggerStruc
    OutputType.i   ; Look at the enumeration above to see what values are possible
    OutputObject.i ; It is used to specify which file, gadget or callback procedure to use.
    Level.i        ; It is set with the `SetLevel()` function and specifies the level up to which the logs are to be output.
  EndStructure
  
  Prototype CallbackPrototype(LoggerName$, Text$)
  
  Global NewMap Logger.LoggerStruc()
  
  Procedure Create(LoggerName$, LoggerOutputType, LoggerOutputObject = 0)
    
    If AddMapElement(Logger(), LoggerName$)
      Logger()\OutputType   = LoggerOutputType
      Logger()\OutputObject = LoggerOutputObject
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
    
  EndProcedure
  
  Procedure Delete(LoggerName$)
    ProcedureReturn DeleteMapElement(Logger(), LoggerName$)
  EndProcedure
  
  Procedure SetLevel(LoggerName$, Level)
    
    If FindMapElement(Logger(), LoggerName$)
      Logger()\Level = Level
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
    
  EndProcedure
  
  Procedure AddLog(LoggerName$, Text$, Level = 0)
    
    If FindMapElement(Logger(), LoggerName$)
      
      ; Logger level must be equal or above the parameter level
      If Logger()\Level <> 0 And Logger()\Level < Level
        ProcedureReturn #False
      EndIf
      
      Select Logger()\OutputType
        Case #OutputType_Debug
          Debug "LoggerName: " + LoggerName$ + " | Text: " + Text$
          ProcedureReturn #True
          
        Case #OutputType_File
          If IsFile(Logger()\OutputObject)
            WriteStringN(Logger()\OutputObject, "LoggerName: " + LoggerName$ + " | Text: " + Text$)
            ProcedureReturn #True
          EndIf
          
        Case #OutputType_ListGadget
          If IsGadget(Logger()\OutputObject)
            AddGadgetItem(Logger()\OutputObject, -1, "LoggerName: " + LoggerName$ + " | Text: " + Text$)
            ProcedureReturn #True
          EndIf
          
        Case #OutputType_Callback
          If Logger()\OutputObject <> 0
            Protected Callback.CallbackPrototype = Logger()\OutputObject
            Callback(LoggerName$, Text$)
            ProcedureReturn #True
          EndIf
          
      EndSelect
      
    EndIf
    
    ProcedureReturn #False
    
  EndProcedure
  
EndModule

; ------------------------------
;- Examples of use of the module
; ------------------------------
CompilerIf #PB_Compiler_IsMainFile
  
  EnableExplicit
  
  ; ---------------------------------
  ;-> Logger uses normal debug output
  ; ---------------------------------
  
  Logger::Create("myDebugLogger", Logger::#OutputType_Debug)
  Logger::SetLevel("myDebugLogger", 1) ; DebugLogger shows only logs with a level up to 1
  Logger::AddLog("myDebugLogger", "Test with level 0")
  Logger::AddLog("myDebugLogger", "Test with level 1", 1)
  Logger::AddLog("myDebugLogger", "Test with level 2", 2)
  Logger::AddLog("myDebugLogger", "Test with level 3", 3)
  
  ; ------------------------------------------
  ;-> Logger forwards the output to a callback
  ; ------------------------------------------
  
  Procedure LoggerCallback(LoggerName$, Text$)
    
    Debug "[LoggerCallback] LoggerName: " + LoggerName$ + " | Text: " + Text$
    
  EndProcedure
  
  Logger::Create("myCallbackLogger", Logger::#OutputType_Callback, @LoggerCallback())
  Logger::SetLevel("myCallbackLogger", 2) ; DebugLogger shows only logs with a level up to 2
  Logger::AddLog("myCallbackLogger", "Test with level 0")
  Logger::AddLog("myCallbackLogger", "Test with level 1", 1)
  Logger::AddLog("myCallbackLogger", "Test with level 2", 2)
  Logger::AddLog("myCallbackLogger", "Test with level 3", 3)
  
  ; -----------------------------------
  ;-> Logger uses a file for the output
  ; -----------------------------------
  
  Define File = CreateFile(#PB_Any, GetTemporaryDirectory() + "FileLogger.txt")
  If File
    Logger::Create("myFileLogger", Logger::#OutputType_File, File)
    Logger::AddLog("myFileLogger", "Test with level 0")
    Logger::AddLog("myFileLogger", "Test with level 1", 1)
    Logger::AddLog("myFileLogger", "Test with level 2", 2)
    CloseFile(File)
  Else
    Debug "ERROR: FileLogger can't be created!"
  EndIf
  
  ; --------------------------------------------------------------------------
  ;-> Logger uses gadgets for the output (gadget must support AddGadgetItem())
  ; --------------------------------------------------------------------------
  
  Define Window = OpenWindow(#PB_Any, #PB_Ignore, #PB_Ignore, 500, 500, "ListGadgetLogger", #PB_Window_SystemMenu)
  If Window
    ListViewGadget(0, 0, 0,                        WindowWidth(Window), WindowHeight(Window) / 2)
    EditorGadget(  1, 0, WindowHeight(Window) / 2, WindowWidth(Window), WindowHeight(Window) / 2)
    
    Logger::Create("myListViewGadgetLogger", Logger::#OutputType_ListGadget, 0)
    Logger::AddLog("myListViewGadgetLogger", "Test with level 0")
    Logger::AddLog("myListViewGadgetLogger", "Test with level 1", 1)
    Logger::AddLog("myListViewGadgetLogger", "Test with level 2", 2)
    
    Logger::Create("myEditorGadgetLogger", Logger::#OutputType_ListGadget, 1)
    Logger::AddLog("myEditorGadgetLogger", "Test with level 0")
    Logger::AddLog("myEditorGadgetLogger", "Test with level 1", 1)
    Logger::AddLog("myEditorGadgetLogger", "Test with level 2", 2)
    
    Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
  Else
    Debug "ERROR: ListGadgetLogger can't be created!"
  EndIf
  
CompilerEndIf