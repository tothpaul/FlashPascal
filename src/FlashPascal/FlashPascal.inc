{ This file is part of Flash Pascal project. See 'http://flashpascal.sf.net' for more. }

{$DEFINE REG_THIS}  // use Register 1 for this
{$DEFINE REG_PARAM} // use Registers 2..n for parameters
{$DEFINE REG_VARS}  // use Registers n+1...m for local var

{-$DEFINE DEBUGER}
{$DEFINE GARBAGE} // Collect all in memory objects

{-$DEFINE RELEASE}

{$IFDEF RELEASE}
 {$UNDEF DEBUGER}
 {$UNDEF GARBAGE}
{$ENDIF}


{$DEFINE SHELL}    // launch the SWF file after compilation
{$DEFINE PLAYER}   // launch the SWF file with FlashPlayer.exe
{-$DEFINE LOG}      // show parsed source
{-$DEFINE MEMCHECK} // check memory leaks
{-$DEFINE TEST}     // test programs

{$IFNDEF WIN32}{$UNDEF SHELL}{$ENDIF}

