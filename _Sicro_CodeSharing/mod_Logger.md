# mod_Logger.pbi

	Result = Logger::Create(LoggerName$)
	
- **Description**

	Creates a new logger.
	
	---
	
- **Parameters**

	- `LoggerName$`
	
		Any string can be specified that will later be used to access the logger.
		
	---
	
- **Return value**

	- `#True` on success
	
	- `#False` on error
	
	---
	
- **Remarks**

	An unnamed logger (`LoggerName$ = ""`) exists automatically and doesn't need to be created before.
	
---

	Result = Logger::AddDevice(LoggerName$, DeviceType, LogLevel [, Device])
	
- **Description**

	Adds a new log output device to the logger.
	
	---
	
- **Parameters**

	- `LoggerName$`
	
		It is used to specify the logger.
		
		---
		
	- `DeviceType`
	
		It can be one of the following values:
		
		- `Logger::#DeviceType_Callback`
		
		- `Logger::#DeviceType_Debug`
		
		- `Logger::#DeviceType_File`
		
		- `Logger::#DeviceType_ListGadget`
		
		---
		
	- `LogLevel`
	
		It can be one of the following values:
		
		- `Logger::#LogLevel_Error`
		
		- `Logger::#LogLevel_Warn`
		
		- `Logger::#LogLevel_Info`
		
		- `Logger::#LogLevel_Debug`
		
		---
		
	- `Device` (optional)
	
		It is only required for the following device types:
		
		- `Logger::#DeviceType_Callback`
		
			- `Device` must be the adresse of the callback procedure
			
					Procedure LoggerCallback(LogMessage$)
					
					EndProcedure
					
		- `Logger::#DeviceType_File`
		
			- `Device` must be the file number
			
		- `Logger::#DeviceType_ListGadget`
		
			- `Device` must be the gadget number
			
	---
	
- **Return value**

	- `#True` on success
	
	- `#False` on error
	
---

	Result = Logger::AddLog(LoggerName$, LogMessage$, LogLevel)
	
- **Description**

	Adds a new log message to the logger.
	
	---
	
- **Parameters**

	- `LoggerName$`
	
		It is used to specify the logger.
		
		---
		
	- `LogMessage$`
	
		It is used to specify the log message.
		
		---
		
	- `LogLevel`
	
		It can be one of the following values:
		
		- `Logger::#LogLevel_Error`
		
		- `Logger::#LogLevel_Warn`
		
		- `Logger::#LogLevel_Info`
		
		- `Logger::#LogLevel_Debug`
		
	---
	
- **Return value**

	- `#True` on success
	
	- `#False` on error
	
	---
	
- **Remarks**

	If the function returns `#True`, this only means that the logger with the name specified with `LoggerName$` was found and not that the output was successful.
