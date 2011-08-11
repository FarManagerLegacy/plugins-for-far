@echo off
set compile=Compile7.pl
if exist NoBackup\Delphi7\dcc32.exe set compile=Compile7l.pl & echo *** Delphi7 Lite Compiler ***
if '%1' == 'UNICODE' ( echo *** Unicode Version *** ) else ( echo *** Ansi Version *** )
for /r %%i in (*.dpr) do (
  pushd %%~dpi
  echo *** Project %%~ni ***
  perl -w %~dp0%compile% %1
  popd
)
