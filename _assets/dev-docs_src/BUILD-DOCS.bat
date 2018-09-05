:: "BUILD-DOCS.bat" v1.0.1 (2018/09/05) by Tristano Ajmone
:: -----------------------------------------------------------------------------
:: This script is released into public domain via the Unlicense:
::     http://unlicense.org/
:: -----------------------------------------------------------------------------
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
ECHO.
ECHO ==============================================================================
ECHO                   Converting CodeArchiv Dev Docs to HTML ...                  
ECHO ==============================================================================
:: Preserve current folder:
SET "_STARTFOLD=%~dp0"
CD ../
:: Set some required vars
SET "_BASEDIR=%CD%\"

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
:: func:                        Convert to AsciiDoc
:: =============================================================================
:conv2adoc

CALL asciidoctor^
  -a data-uri^
  --safe-mode unsafe^
  --verbose^
  %1
EXIT /B

:: EOF
