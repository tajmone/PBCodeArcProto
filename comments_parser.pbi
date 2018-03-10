; ******************************************************************************
; *                                                                            *
; *                           Header Comments Parser                           *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "comments_parser.pb" v.0.0.4 (2018/03/10) | PureBasic 5.62
; ------------------------------------------------------------------------------

;{ Define New-Line Sequence to OS native EOL
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #EOL$ = #CRLF$
CompilerElse
  #EOL$ = #LF$
CompilerEndIf ;}

Structure KeyValPair
  key.s
  val.s
EndStructure

;{ Procs Declaration
; IncludeFile "parser.pbhgen.pbi" ; <= PBHGEN-X
Declare ParseFile(file.s)
Declare ExtractHeaderBlock(file.s, List CommentsL.s())
Declare ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())
;}

; ------------------------------------------------------------------------------
Procedure ParseFile(file.s)
  
  ;{ check file exists
  Select FileSize(file.s)
    Case -1
      Debug "File not found: '" + file + "'"
      ProcedureReturn #False
    Case -2
      Debug "File is a directory: '" + file + "'"
      ProcedureReturn #False
  EndSelect ;}
  
  ;{ open file
  If Not ReadFile(0, file, #PB_UTF8)
    Debug "Can't open file: '" + file + "'"
    ProcedureReturn #False
  EndIf
  ; Skip BOM
  ; TODO: Check enconding and if not UTF8 use it in read operations?
  ReadStringFormat(0) ;}
  
  NewList CommentsL.s()
  ExtractHeaderBlock(file, CommentsL())
  CloseFile(0)
  
  ;{ Debug Header Comments
  ;  =====================
  Debug "Header Block:"
  Debug LSet("--+", 80, "-")
  cnt=1
  ForEach CommentsL()
    Debug RSet(Str(cnt), 2, "0") + "| "+ CommentsL()
    cnt+1
  Next
  Debug LSet("--+", 80, "-")
  
  NewList RawDataL.KeyValPair()
  ParseComments(CommentsL(), RawDataL())
  
EndProcedure
; ------------------------------------------------------------------------------
Procedure ExtractHeaderBlock(file.s, List CommentsL.s())
  Debug ">>> ExtractHeaderBlock("+file+", List CommentsL.s())"
  
  lineNum = 1
  
  Repeat
    
    line.s = ReadString(0)
    
    If Left(line, 1) <> ";"
      Debug "non comment line found at line " + Str(lineNum)
      Break
    Else
      AddElement(CommentsL())
      CommentsL() = line
      lineNum +1
    EndIf
    
  ForEver
  
  Debug "Total comments lines read: " + Str(lineNum -1)
  
  Debug "<<< ExtractHeaderBlock("+file+", List CommentsL.s())"
EndProcedure
; ------------------------------------------------------------------------------
Procedure ParseComments(List CommentsL.s(), List RawDataL.KeyValPair() )
  Debug ">>> ParseComments()"
  
  lineCnt = 1
  dbgIndent.s = "  | "
  
  ForEach CommentsL()
    lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
    commDelim.s = Left(CommentsL(), 3)
    If commDelim = ";: " Or commDelim = ";{:"  Or commDelim = ";}:"
      ; TODO: capture also ";{:" and ";}:"
      Debug lineNum + "Parse:"
      ;  ===========
      ;- Extract Key
      ;  ===========
      key.s = Trim(StringField(CommentsL(), 2, ":"))
        Debug dbgIndent + "- key found: '" + key +"'"
      ;  =============
      ;- Extract Value
      ;  =============
      valueStart = FindString(CommentsL(), ":", 4)
      value.s = Trim(Mid(CommentsL(), valueStart +1))
      If value = #Empty$
        Debug dbgIndent + "- value found: (empty)"
      Else
        Debug dbgIndent + "- value found: '" + value +"'"
      EndIf
      ;  =======================
      ;- Look for Carry-On Value
      ;  =======================
      carryOn = #False
      Repeat
        
        NextElement(CommentsL())
        lineCnt +1
        
        commDelim.s = Left(CommentsL(), 3)
        If Left(commDelim, 2) = ";." Or commDelim = ";{."  Or commDelim = ";}."
          valueNew.s = Mid(CommentsL(), 4)
          lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
          Debug lineNum + "Detected value carry-on:"
          If Not carryOn ; (ie, it's 1st carry-on line)
            ; Establish base indentation
            baseIndent = 0
            While Mid(valueNew, baseIndent +1, 1) = " "
              baseIndent +1
            Wend
            Debug dbgIndent + "- Base Indentantion established: " + Str(baseIndent)
          EndIf
          valueNew = RTrim(Mid(valueNew, baseIndent +1))
          Debug dbgIndent + "- carry-on value found: '" + valueNew +"'"
          ;  ------------------------------
          ;- Append Carry-On Value to Value
          ;  ------------------------------
          If Not carryOn ; (ie, it's 1st carry-on line)
            ; If value definition starts on carry-on, don't insert EOL
            If value <> #Empty$          
              value + #EOL$ + valueNew
            Else
              value = valueNew
            EndIf
            carryOn = #True
          Else
            value + #EOL$ + valueNew
          EndIf
        Else ; No more carry-on lines found
          If carryOn
            ; Debug final value string
            Debug dbgIndent + "- Assembled value:"
            Debug LSet("", 80, "-")
            Debug value
          EndIf
          ; Roll-back List Element and line counter...
          PreviousElement(CommentsL())
          lineCnt -1
          Break
        EndIf
        
      ForEver
    Else
      Debug lineNum + "Skip"
    EndIf
    lineCnt +1
    Debug LSet("", 80, "-")
  Next
  
  
  
  Debug "<<< ParseComments()"
EndProcedure