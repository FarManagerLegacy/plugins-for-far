{.$DEFINE Release}
{$IFDEF ANSI}
  {$UNDEF UNICODE}
  {$UNDEF UNICODE_CTRLS}
{$ENDIF}
{$IFDEF UNICODE}
  {$DEFINE UNICODE_CTRLS}
{$ENDIF}
{$DEFINE NOT_USE_RICHEDIT}

{$IFDEF FPC} 
  {Free Pascal compiler}
  //******************************************************************************
  
  //******************************************************************************
{$ELSE}
  {Delphi compiler}
  //******************************************************************************
  {$IFDEF Release}
    {$O+} // Optimizations

    {$R-} // Range checking
    {$Q-} // Overflow

    {$D-} // Debug information
    {$L-} // Local symbols
    {$Y-} // Reference info
    {$C-} // Assertions
  {$ELSE}
    {$O-} // Optimizations

    {$R+} // Range checking
    {$Q+} // Overflow

    {$D+} // Debug information
    {$L+} // Local symbols
    {$YD} // Reference info
    {$C+} // Assertions
  {$ENDIF}
  //******************************************************************************

  {*********************************************************  defines for Delphi 4 }
  {$IFDEF VER120}
    {$DEFINE DELPHI4}
    {$DEFINE D4UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 5 }
  {$IFDEF VER130}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE DELPHI5}
  {$ENDIF}

  {*********************************************************  defines for Delphi 6 }
  {$IFDEF VER140}
    {$DEFINE DELPHI6}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 7 }
  {$IFDEF VER150}
    {$DEFINE DELPHI7}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2005 (Delphi 9) }
  {$IFDEF VER170}
    {$DEFINE DELPHI9}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2006 (Delphi 10) }
  {$IFDEF VER180}
    {$DEFINE DELPHI10}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2007 (Delphi 11) }
  {$IFDEF VER185}
    {$DEFINE DELPHI11}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2007 (Delphi 11) }
  {$IFDEF VER190}
    {$DEFINE DELPHI11}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2009 (Delphi 12) }
  {$IFDEF VER200}
    {$DEFINE DELPHI12}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
    {$DEFINE D12UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi 2010 (Delphi 14) }
  {$IFDEF VER210}
    {$DEFINE DELPHI14}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
    {$DEFINE D12UP}
    {$DEFINE D14UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi XE (Delphi 15) }
  {$IFDEF VER220}
    {$DEFINE DELPHI15}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
    {$DEFINE D12UP}
    {$DEFINE D14UP}
    {$DEFINE D15UP}
  {$ENDIF}

  {*********************************************************  defines for Delphi XE2 (Delphi 16) }
  {$IFDEF VER230}
    {$DEFINE DELPHI16}
    {$DEFINE D4UP}
    {$DEFINE D5UP}
    {$DEFINE D6UP}
    {$DEFINE D7UP}
    {$DEFINE D9UP}
    {$DEFINE D10UP}
    {$DEFINE D11UP}
    {$DEFINE D12UP}
    {$DEFINE D14UP}
    {$DEFINE D15UP}
    {$DEFINE D16UP}
  {$ENDIF}

  {*********************************************************  other defines }
  {$IFDEF D6UP}
    {$WARN UNIT_PLATFORM OFF}
  {$ENDIF}

  {$IFDEF D7UP}
    {$WARN UNSAFE_CODE OFF}
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$ENDIF}

  {$IFDEF WIN32}
    {$DEFINE MSWINDOWS}
    {$DEFINE 32BIT}
  {$ENDIF}

  {$IFDEF WIN32}
    {$DEFINE MSWINDOWS}
    {$DEFINE 32BIT}
  {$ENDIF}
  //******************************************************************************
{$ENDIF}