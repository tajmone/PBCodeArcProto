; ******************************************************************************
; *                                                                            *
; *                           Header Comments Parser                           *
; *                                                                            *
; *                             by Tristano Ajmone                             *
; *                                                                            *
; ******************************************************************************
; "comments_parser.pb" v0.0.6 (2018/03/11) | PureBasic 5.62
; ------------------------------------------------------------------------------

; ==============================================================================
;                                   CHANGELOG                                   
;{==============================================================================
; v0.0.6 (2018/03/11)
;   - Generate an HTML Resume Card (using <table>):
;     - value strings:
;       - [x] string is XML escaped
;       - [x] EOLs coverted to "<br />"
;       - [ ] Links are not yet handled
;     - Debug Preview:
;       - save it to file as "<filename>.html" for testing purposes
;       - use external CSS "test_files/test.css" for tests styling
; v0.0.5 (2018/03/11)
;   - carry-on values no longer treated as verbatim: every line is trimmed of
;      leading and trailing whitespace, and joined with previous line (a space
;      is inserted as separator). Empty carry-on lines are rendere as a EOL to
;      separate paragraphs.
; v0.0.4 (2018/03/10)
;   - carry-on values are treated as verbatim: a base-indentation is established
;     from first carry-on line and used to left-trim the rest of carry-on lines.
;     This allows to preserve any intended indentation.
;}==============================================================================


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
Declare   ParseFile(file.s)
Declare   ExtractHeaderBlock(file.s, List CommentsL.s())
Declare   ParseComments(List CommentsL.s(), List RawDataL.KeyValPair())
Declare.s BuildCard(List RawDataL.KeyValPair())
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
  Debug LSet("--+", 80, "-") ;}
  
  NewList RawDataL.KeyValPair()
  ParseComments(CommentsL(), RawDataL())
  CardHTML.s = BuildCard( RawDataL() )
  
  ;- Write HTML Card to file (debug purpose)
  ;  =======================
  If CreateFile(0, file + ".html", #PB_UTF8) ; any existing file will be replaced by empty file
    WriteStringN(0, CardHTML)
    CloseFile(0)
  EndIf

  
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
        newParagraph = #True
      Else
        Debug dbgIndent + "- value found: '" + value +"'"
        newParagraph = #False
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
          
          ;- Carry-on line found
          ;  ~~~~~~~~~~~~~~~~~~~
          carryOn = #True
          valueNew.s = Trim(Mid(CommentsL(), 4))
          lineNum.s = RSet(Str(lineCnt), 2, "0") + "| "
          Debug lineNum + "Detected value carry-on:"
          Debug dbgIndent + "- carry-on value found: '" + valueNew +"'"
          ;  ------------------------------
          ;- Append Carry-On Value to Value
          ;  ------------------------------
          If valueNew <> #Empty$
            If newParagraph
              value + valueNew
            Else
              value + " " + valueNew
            EndIf
            newParagraph = #False
          Else
            value + #EOL$ + #EOL$
            newParagraph = #True
          EndIf
          
        Else ;- No carry-on line found (or no more)
             ;  ~~~~~~~~~~~~~~~~~~~~~~
          If carryOn ; (there were carry-on lines)
                     ; Debug final value string
            Debug dbgIndent + "- Assembled value:"
            Debug LSet("", 80, "-")
            Debug value
          EndIf
          ;- Add <key> & <value> to list
          AddElement(RawDataL())
          RawDataL()\key = key
          RawDataL()\val = value
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
; ------------------------------------------------------------------------------
Procedure.s BuildCard( List RawDataL.KeyValPair() )
  Debug ">>> BuildCard()"
  
  ; HTML NOTE: Temporary tags and CSS for testing purposes only!
  Card.s = "<!doctype html><html lang='en'><head><meta charset='utf-8'>" ; DELME: Temporary tags for testing
  Card + "<link rel='stylesheet' href='test.css'>"
  Card + "</head><body>" ; DELME: Temporary tags for testing
  
  Card+ "<table><tbody>"
  
  ; TODO: Insert <p> tags?
  ForEach RawDataL()
    key.s   = EscapeString( RawDataL()\key, #PB_String_EscapeXML )
    Card + "<tr><td>" + key + ":</td><td>"
    
    value.s = EscapeString( RawDataL()\val, #PB_String_EscapeXML )
    ; TODO: Add <br>
    value = ReplaceString(value, #EOL$+#EOL$, "<br /><br />") ; <= The optional " /" is for XML compatibility
    ; TODO: Capture Links
    Card + value + "</td></tr>"    
    
  Next
  
  Card + "</tbody></table>"
  Card + "</body></html>" ; DELME: Temporary tags for testing
  
  Debug "<<< BuildCard()"
  ProcedureReturn Card
  
EndProcedure
