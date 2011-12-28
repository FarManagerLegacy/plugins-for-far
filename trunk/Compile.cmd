@echo off
set lite=
if exist NoBackup\Delphi7\dcc32.exe set lite=-l & echo *** Delphi7 Lite Compiler ***
if not exist "%1\%1.dpr" echo Project "%1\%1.dpr" not found & goto :eof
pushd %1
echo *** Project %1 ***
perl -w %~dp0compile7.pl %*
popd
