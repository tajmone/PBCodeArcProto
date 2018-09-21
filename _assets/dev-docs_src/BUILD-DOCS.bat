:: "BUILD-DOCS.bat" v2.0.0 (2018/09/21) by Tristano Ajmone
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
FOR /R %%i IN (*.asciidoc) DO (
    SET "_TMPPATH=%%i"
    SET "_SHORTPATH=\_assets\!_TMPPATH:%_BASEDIR%=!"
    ECHO Converting: !_SHORTPATH!
    CALL :conv2adoc %%i
)
:: Restore original current folder:
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
:: func:                        Convert to AsciiDoc
:: =============================================================================
:conv2adoc

CALL asciidoctor^
  -S unsafe^
  -a data-uri^
  -a icons=font^
  -a toc=left^
  -a experimental^
  %1
EXIT /B

:: EOF
