{$IFDEF FPC}
  //
{$ELSE}
  //{$DEFINE DK_CLX} // Comment/Uncomment it to compile CLX or not!
  {$IFDEF DKCLX}
    {$IFDEF MSWINDOWS}
      {$DEFINE DELPHI_CLX}
    {$ELSE}
      {$DEFINE KYLIX_CLX}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
