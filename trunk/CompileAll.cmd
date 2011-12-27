@echo off
set lite=
if exist NoBackup\Delphi7\dcc32.exe set lite=-l & echo *** Delphi7 Lite Compiler ***
echo *** Far %2 Version ***
for /r %%i in (*.dpr) do (
  pushd %%~dpi
  echo *** Project %%~ni ***
  perl -w %~dp0compile7.pl %*
  popd
)