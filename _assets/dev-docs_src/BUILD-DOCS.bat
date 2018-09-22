:: "BUILD-DOCS.bat" v2.0.1 (2018/09/23) by Tristano Ajmone
:: -----------------------------------------------------------------------------
:: This script is released into public domain via the Unlicense:
::     http://unlicense.org/
:: -----------------------------------------------------------------------------
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
ECHO.
:: Preserve current folder:
SET "_STARTFOLD=%~dp0"
CD ../
:: Set some required vars
SET "_BASEDIR=%CD%\"
ECHO ==============================================================================
ECHO                       Running Doxter on PB Sources ...                        
ECHO ==============================================================================
:: NOTE: We can't use this loop until all PB sources are Doxter compliant!
:: -----------------------------------------------------
:: FOR /R %%i IN (*.pb, *.pbi) DO (
::     SET "_TMPPATH=%%i"
::     SET "_SHORTPATH=\_assets\!_TMPPATH:%_BASEDIR%=!"
::     ECHO Processing: !_SHORTPATH!
::     CALL doxter %%i > nul
:: )
:: -----------------------------------------------------

:: For now we'll run Doxter against manually selected files:
CALL :doxterize Doxter.pb

ECHO.
ECHO ==============================================================================
ECHO                   Converting CodeArchiv Dev Docs to HTML ...                  
ECHO ==============================================================================
:: The _PATH2ROOT var provides relative paths for assets (Highlight.js, etc.)
SET _PATH2ROOT=

:: Process current folder
CALL :processDir %CD%

:: Process subfolders
SET "_PATH2ROOT=../"
FOR /D %%f IN (*) DO (
  PUSHD %%f
  CALL :processDir
  POPD
)

:: Restore original script invocation folder:
CD %_STARTFOLD%
EXIT /B

:: =============================================================================
:: func:                       Process With Doxter
:: =============================================================================
:doxterize

SET "_TMPPATH=%1"
SET "_SHORTPATH=\_assets\!_TMPPATH:%_BASEDIR%=!"
ECHO Processing: !_SHORTPATH!
CALL doxter %1 > nul
EXIT /B
:: =============================================================================
:: func:                          Process Folder                                
:: =============================================================================
:processDir

FOR %%i IN (*.asciidoc) DO (
    SET "_TMPPATH=%%i"
    SET "_SHORTPATH=\_assets\!_TMPPATH:%_BASEDIR%=!"
    ECHO Converting: !_SHORTPATH!
    CALL :conv2adoc %%i
)
EXIT /B
:: =============================================================================
:: func:                        Convert to AsciiDoc
:: =============================================================================
:conv2adoc
CALL asciidoctor^
  -S unsafe^
  -a data-uri^
  -a icons=font^
  -a toc=left^
  -a experimental^
  -a source-highlighter=highlightjs^
  -a highlightjsdir=!_PATH2ROOT!hjs^
  --base-dir %CD%^
  --verbose^
  %1
EXIT /B

:: EOF
