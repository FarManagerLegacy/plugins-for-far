@echo off
set compile=Compile7.pl
if exist NoBackup\Delphi7\dcc32.exe set compile=Compile7l.pl & echo Delphi7 Lite Compiler
for /r %%i in (*.dpr) do (
  pushd %%~dpi
  perl -w %~dp0%compile% %1
  popd
)
