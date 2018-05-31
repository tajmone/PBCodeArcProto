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
  
  Declare Create(LoggerID)
  Declare AddDevice(LoggerID, DeviceType, LogLevel, Device = 0)
  Declare AddLog(LoggerID, LogMessage$, LogLevel)
  
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
  ;-> Global Lists and Arrays
  ; -----------------------------------------------------------------

  Global NewList LoggerRandomIDList.LoggerStruc()
  Global Dim     LoggerConstantIDArray.LoggerStruc(0)
  
  ; -----------------------------------------------------------------
  ;-> Procedures
  ; -----------------------------------------------------------------
  
  Procedure Create(LoggerID)
    
    ; Try to add a new logger to the logger list/array
    
    If LoggerID = #PB_Any ; Auto-generated ID will be created
      
      If Not AddElement(LoggerRandomIDList())
        ProcedureReturn #False
      EndIf
      ProcedureReturn @LoggerRandomIDList()
      
    ElseIf LoggerID > 0 ; Array index "0" always exists and therefore doesn't have to be created
      
      If LoggerID > ArraySize(LoggerConstantIDArray())
        ReDim LoggerConstantIDArray(LoggerID)
      EndIf
      
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  ; -----------------------------------------------------------------
  
  Procedure AddDevice(LoggerID, DeviceType, LogLevel, Device = 0)
    
    If LoggerID => 0 And LoggerID <= ArraySize(LoggerConstantIDArray())
      
      ; Try to select the logger and add a new device to it
      If Not AddElement(LoggerConstantIDArray(LoggerID)\Device())
        ProcedureReturn #False
      EndIf
      
      ; Set the parameters of the new device
      LoggerConstantIDArray(LoggerID)\Device()\DeviceType = DeviceType
      LoggerConstantIDArray(LoggerID)\Device()\Device     = Device
      LoggerConstantIDArray(LoggerID)\Device()\LogLevel   = LogLevel
      
    Else ; Auto-generated ID (#PB_Any)
      
      ; Try to select the logger and add a new device to it
      ChangeCurrentElement(LoggerRandomIDList(), LoggerID)
      If Not AddElement(LoggerRandomIDList()\Device())
        ProcedureReturn #False
      EndIf
      
      ; Set the parameters of the new device
      LoggerRandomIDList()\Device()\DeviceType = DeviceType
      LoggerRandomIDList()\Device()\Device     = Device
      LoggerRandomIDList()\Device()\LogLevel   = LogLevel
      
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  ; -----------------------------------------------------------------
  
  Procedure AddLog(LoggerID, LogMessage$, LogLevel)
    
    Protected Callback.CallbackPrototype
    
    If LoggerID => 0 And LoggerID <= ArraySize(LoggerConstantIDArray())
      
      ; Iterate through all devices of the logger
      ForEach LoggerConstantIDArray(LoggerID)\Device()
        
        ; Logger level must be equal or above the parameter level
        If LoggerConstantIDArray(LoggerID)\Device()\LogLevel < LogLevel
          Continue
        EndIf
        
        ; Process the device type
        Select LoggerConstantIDArray(LoggerID)\Device()\DeviceType
            
          Case #DeviceType_Callback
            Callback = LoggerConstantIDArray(LoggerID)\Device()\Device
            Callback(LogMessage$)
            
          Case #DeviceType_Debug
            Debug LogMessage$
            
          Case #DeviceType_File
            WriteStringN(LoggerConstantIDArray(LoggerID)\Device()\Device, LogMessage$)
            
          Case #DeviceType_ListGadget
            AddGadgetItem(LoggerConstantIDArray(LoggerID)\Device()\Device, -1, LogMessage$)
            
        EndSelect
        
      Next
      
    Else ; Auto-generated ID (#PB_Any)
      
      ChangeCurrentElement(LoggerRandomIDList(), LoggerID)
      
      ; Iterate through all devices of the logger
      ForEach LoggerRandomIDList()\Device()
        
        ; Logger level must be equal or above the parameter level
        If LoggerRandomIDList()\Device()\LogLevel < LogLevel
          Continue
        EndIf
        
        ; Process the device type
        Select LoggerRandomIDList()\Device()\DeviceType
            
          Case #DeviceType_Callback
            Callback = LoggerRandomIDList()\Device()\Device
            Callback(LogMessage$)
            
          Case #DeviceType_Debug
            Debug LogMessage$
            
          Case #DeviceType_File
            WriteStringN(LoggerRandomIDList()\Device()\Device, LogMessage$)
            
          Case #DeviceType_ListGadget
            AddGadgetItem(LoggerRandomIDList()\Device()\Device, -1, LogMessage$)
            
        EndSelect
        
      Next
      
    EndIf
    
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
  
  Logger::Create(0)
  Logger::AddDevice(0, Logger::#DeviceType_Debug, Logger::#LogLevel_Warn)
  Logger::AddLog(0, "Error: Test", Logger::#LogLevel_Error)
  Logger::AddLog(0, "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog(0, "Warn: Test", Logger::#LogLevel_Warn)
  Logger::AddLog(0, "Info: Test", Logger::#LogLevel_Info)
  
  ; ------------------------------------------
  ;-> Logger forwards the output to a callback
  ; ------------------------------------------
  
  Procedure LoggerCallback(LogMessage$)
    
    Debug "Callback: " + LogMessage$
    
  EndProcedure
  
  Logger::Create(1)
  Logger::AddDevice(1, Logger::#DeviceType_Callback, Logger::#LogLevel_Info, @LoggerCallback())
  Logger::AddLog(1, "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog(1, "Info: Test", Logger::#LogLevel_Info)
  Logger::AddLog(1, "Warn: Test", Logger::#LogLevel_Warn)
  Logger::AddLog(1, "Error: Test", Logger::#LogLevel_Error)
  
  ; -----------------------------------------------------------------
  ;-> Logger uses a file for the output
  ; -----------------------------------------------------------------
  
  Define File = CreateFile(#PB_Any, GetTemporaryDirectory() + "FileLogger.txt")
  If File
    Logger::Create(2)
    Logger::AddDevice(2, Logger::#DeviceType_File, Logger::#LogLevel_Debug, File)
    Logger::AddLog(2, "Error: Test", Logger::#LogLevel_Error)
    Logger::AddLog(2, "Info: Test", Logger::#LogLevel_Info)
    Logger::AddLog(2, "Warn: Test", Logger::#LogLevel_Warn)
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
    
    Define myLogger = Logger::Create(#PB_Any)
    Logger::AddDevice(myLogger, Logger::#DeviceType_ListGadget, Logger::#LogLevel_Info, 0)
    Logger::AddDevice(myLogger, Logger::#DeviceType_ListGadget, Logger::#LogLevel_Warn, 1)
    Logger::AddLog(myLogger, "Info: Test", Logger::#LogLevel_Info)
    Logger::AddLog(myLogger, "Warn: Test", Logger::#LogLevel_Warn)
    Logger::AddLog(myLogger, "Warn: Test", Logger::#LogLevel_Debug)
    Logger::AddLog(myLogger, "Error: Test", Logger::#LogLevel_Error)
    Logger::AddLog(myLogger, "Warn: Test", Logger::#LogLevel_Warn)
    Logger::AddLog(myLogger, "Info: Test", Logger::#LogLevel_Info)
    
    Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
  Else
    Debug "ERROR: ListGadgetLogger can't be created!"
  EndIf
  
CompilerEndIf
