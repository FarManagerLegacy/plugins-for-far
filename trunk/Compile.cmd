@echo off
for /r %%i in (*.dpr) do (
  pushd %%~dpi
  perl -w %~dp0Compile7.pl %1
  popd
)
