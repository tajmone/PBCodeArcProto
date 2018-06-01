; -------------------------------------------------------------------
;- DeclareModule
; -------------------------------------------------------------------

DeclareModule Logger
  
  EnableExplicit
  
  ; -----------------------------------------------------------------
  ;-> Enumerations
  ; -----------------------------------------------------------------
  
  Enumeration LogLevelEnum
    ; The order of the list is important and goes from important to
    ; less important, but more detailed information.
    #LogLevel_Error
    #LogLevel_Warn
    #LogLevel_Info
    #LogLevel_Debug
  EndEnumeration
  
  Enumeration DeviceTypeEnum
    #DeviceType_Callback
    #DeviceType_Debug
    #DeviceType_File
    #DeviceType_ListGadget
  EndEnumeration
  
  ; -----------------------------------------------------------------
  ;-> Declaration Of Procedures
  ; -----------------------------------------------------------------
  
  Declare Create(LoggerName$)
  Declare AddDevice(LoggerName$, DeviceType, LogLevel, Device = 0)
  Declare AddLog(LoggerName$, LogMessage$, LogLevel)
  
EndDeclareModule

; -------------------------------------------------------------------
;- Module
; -------------------------------------------------------------------

Module Logger
  
  ; -----------------------------------------------------------------
  ;-> Structures
  ; -----------------------------------------------------------------
  
  Structure DeviceStruc
    DeviceType.i
    Device.i
    LogLevel.i
  EndStructure
  
  Structure LoggerStruc
    List Device.DeviceStruc()
  EndStructure
  
  ; -----------------------------------------------------------------
  ;-> Prototypes
  ; -----------------------------------------------------------------
  
  Prototype CallbackPrototype(LogMessage$)
  
  ; -----------------------------------------------------------------
  ;-> Global Maps
  ; -----------------------------------------------------------------
  
  Global NewMap Logger.LoggerStruc()
  
  ; -----------------------------------------------------------------
  ;-> Procedures
  ; -----------------------------------------------------------------
  
  Procedure Create(LoggerName$)
    
    ; Try to add a new logger to the logger map
    If FindMapElement(Logger(), LoggerName$) Or Not AddMapElement(Logger(), LoggerName$)
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  ; -----------------------------------------------------------------
  
  Procedure AddDevice(LoggerName$, DeviceType, LogLevel, Device = 0)
    
    ; Try to select the logger and add a new device to it
    If Not FindMapElement(Logger(), LoggerName$) Or Not AddElement(Logger()\Device())
      ProcedureReturn #False
    EndIf
    
    ; Set the parameters of the new device
    Logger()\Device()\DeviceType = DeviceType
    Logger()\Device()\Device     = Device
    Logger()\Device()\LogLevel   = LogLevel
    
    ProcedureReturn #True
    
  EndProcedure
  
  ; -----------------------------------------------------------------
  
  Procedure AddLog(LoggerName$, LogMessage$, LogLevel)
    
    ; Try to select the logger
    If Not FindMapElement(Logger(), LoggerName$)
      ProcedureReturn #False
    EndIf
    
    ; Iterate through all devices of the logger
    ForEach Logger()\Device()
      
      ; Logger level must be equal or above the parameter level
      If Logger()\Device()\LogLevel < LogLevel
        Continue
      EndIf
      
      ; Process the device type
      Select Logger()\Device()\DeviceType
        
        Case #DeviceType_Callback
          Protected Callback.CallbackPrototype = Logger()\Device()\Device
          Callback(LogMessage$)
          
        Case #DeviceType_Debug
          Debug LogMessage$
          
        Case #DeviceType_File
          WriteStringN(Logger()\Device()\Device, LogMessage$)
          
        Case #DeviceType_ListGadget
          AddGadgetItem(Logger()\Device()\Device, -1, LogMessage$)
          
      EndSelect
      
    Next
    
    ProcedureReturn #True
    
  EndProcedure
  
EndModule

; -------------------------------------------------------------------
;- Examples of use of the module
; -------------------------------------------------------------------
CompilerIf #PB_Compiler_IsMainFile
  
  EnableExplicit
  
  ; -----------------------------------------------------------------
  ;-> Logger uses normal debug output
  ; -----------------------------------------------------------------
  
  Logger::Create("Logger1")
  Logger::AddDevice("Logger1", Logger::#DeviceType_Debug, Logger::#LogLevel_Warn)
  Logger::AddLog("Logger1", "Error: Test", Logger::#LogLevel_Error)
  Logger::AddLog("Logger1", "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog("Logger1", "Warn: Test", Logger::#LogLevel_Warn)
  Logger::AddLog("Logger1", "Info: Test", Logger::#LogLevel_Info)
  
  ; -----------------------------------------------------------------
  ;-> Logger forwards the output to a callback
  ; -----------------------------------------------------------------
  
  Procedure LoggerCallback(LogMessage$)
    
    Debug "Callback: " + LogMessage$
    
  EndProcedure
  
  Logger::Create("Logger2")
  Logger::AddDevice("Logger2", Logger::#DeviceType_Callback, Logger::#LogLevel_Info, @LoggerCallback())
  Logger::AddLog("Logger2", "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog("Logger2", "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog("Logger2", "Warn: Test", Logger::#LogLevel_Warn)
  Logger::AddLog("Logger2", "Error: Test", Logger::#LogLevel_Error)
  
  ; -----------------------------------------------------------------
  ;-> Logger uses a file for the output
  ; -----------------------------------------------------------------
  
  Define File = CreateFile(#PB_Any, GetTemporaryDirectory() + "FileLogger.txt")
  If File
    Logger::Create("Logger3")
    Logger::AddDevice("Logger3", Logger::#DeviceType_File, Logger::#LogLevel_Debug, File)
    Logger::AddLog("Logger3", "Error: Test", Logger::#LogLevel_Error)
    Logger::AddLog("Logger3", "Info: Test", Logger::#LogLevel_Info)
    Logger::AddLog("Logger3", "Warn: Test", Logger::#LogLevel_Warn)
    CloseFile(File)
  Else
    Debug "ERROR: FileLogger.txt can't be created!"
  EndIf
  
  ; -----------------------------------------------------------------
  ;-> Logger uses gadgets for the output
  ; -----------------------------------------------------------------
  
  Define Window = OpenWindow(#PB_Any, #PB_Ignore, #PB_Ignore, 800, 500, "ListGadgetLogger", #PB_Window_SystemMenu)
  If Window
    ListViewGadget(0, 0, 0,                        WindowWidth(Window), WindowHeight(Window) / 2)
    EditorGadget(  1, 0, WindowHeight(Window) / 2, WindowWidth(Window), WindowHeight(Window) / 2)
    
    Logger::Create("Logger4")
    Logger::AddDevice("Logger4", Logger::#DeviceType_ListGadget, Logger::#LogLevel_Info, 0)
    Logger::AddDevice("Logger4", Logger::#DeviceType_ListGadget, Logger::#LogLevel_Warn, 1)
    Logger::AddLog("Logger4", "Info: Test", Logger::#LogLevel_Info)
    Logger::AddLog("Logger4", "Warn: Test", Logger::#LogLevel_Warn)
    Logger::AddLog("Logger4", "Warn: Test", Logger::#LogLevel_Debug)
    Logger::AddLog("Logger4", "Error: Test", Logger::#LogLevel_Error)
    Logger::AddLog("Logger4", "Warn: Test", Logger::#LogLevel_Warn)
    Logger::AddLog("Logger4", "Info: Test", Logger::#LogLevel_Info)
    
    Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
  Else
    Debug "ERROR: ListGadgetLogger can't be created!"
  EndIf
  
CompilerEndIf