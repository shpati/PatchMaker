program PatchMaker;

{$APPTYPE CONSOLE}

uses
  SysUtils, System, Classes, StrUtils, Windows;

const
  datafile = 'PatchMaker.txt';
  Block_Size = 4096;

var
  input, temp: string;
  j, k, Buffer_Length: Integer;
  bto, btm: byte;
  i: Int64;
  header: boolean;
  differences: TStringList;
  ofs, mfs: TFileStream;
  Buffer_1: array[0..Block_Size - 1] of Byte;
  Buffer_2: array[0..Block_Size - 1] of Byte;

procedure leave(input: string);
begin
  Writeln('The file ', input, ' does not exist!');
  Writeln;
  Write('Press the Enter key to exit...');
  Readln;
  halt;
end;

begin
  Writeln('PatchMaker v0.99 by Shpati Koleka. MIT License.');
  Writeln;
  differences := TStringList.Create;
  if FileExists(datafile) then
  begin
    differences.LoadFromFile(datafile);
    if differences[0] = '[PatchMaker datafile]' then
    begin
      Writeln('The file ', datafile, ' was found. The program is ready to patch.');
      Writeln;
      Writeln(differences[2]);
      Writeln;
      Writeln('The locations and values (in hex code) to be patched are:');
      for j := 3 to differences.Count - 1 do Writeln(differences[j]);
      Writeln;
      Write('Do you want to patch using the ', datafile, ' datafile? [Default=yes]: ');
      Readln(input);
      Writeln;
      if input = '' then input := 'y';
      if (AnsiLowerCase(input[1]) = 'y') then
      begin
        input := differences[2];
        Delete(input, 1, 20);
        temp := input;
        Write('Enter target filename [Default=', input, ']: ');
        Readln(input);
        if input = '' then input := temp;
        if not FileExists(input) then leave(input);
     // start patching
        ofs := TFileStream.Create(input, fmOpenReadWrite);
        try
          mfs := TFileStream.Create(input + '.bak', fmOpenWrite or fmCreate);
          try
            mfs.CopyFrom(ofs, ofs.Size);
          finally
            mfs.Free;
          end;
          for j := 0 to differences.Count - 1 do
            if differences[j] <> '' then
              if differences[j][1] = '$' then
              begin
                temp := Copy((differences[j]), 1, 9);
                ofs.Position := StrtoInt64(temp);
                temp := Copy(differences[j], 14, 2);
                HextoBin(PAnsiChar(temp), PAnsiChar(temp), 2);
                ofs.Write(temp[1], 1);
              end;
          Writeln;
          Writeln('Done!');
          Writeln;
          Writeln('To restore the initial file use the backup file (*.bak) in the same dir.');
        finally
          ofs.Free;
        end;
     // done patching
        Writeln;
        Write('Press the Enter key to exit...');
        Readln;
        exit;
      end;
    end;
  end;

  differences.Clear;
  Write('Create a new patch file? [Default=yes]: ');
  Readln(input);
  Writeln;
  if input = '' then input := 'y';
  if (AnsiLowerCase(input[1]) <> 'y') then
  begin
    Write('Press the Enter key to exit...');
    Readln;
    exit;
  end;

  repeat
    Write('Enter the name of the initial/unchanged file: ');
    Readln(input);
  until input <> '';

  if not FileExists(input) then leave(input);
  ofs := TFileStream.Create(input, fmOpenRead);
  temp := input;
  Writeln;

  repeat
    Write('Enter the name of the modified/changed  file: ');
    Readln(input);
  until input <> '';

  if not FileExists(input) then leave(input);
  mfs := TFileStream.Create(input, fmOpenRead);
  Writeln;
  if ofs.Size = mfs.Size then
  begin
    header := true;
    i := 0;
    j := 0;
    ofs.Position := 0;
    mfs.Position := 0;
    while ofs.Position < ofs.Size do
    begin
      Buffer_Length := ofs.Read(Buffer_1, Block_Size);
      mfs.Read(Buffer_2, Block_Size);
      if not CompareMem(@Buffer_1, @Buffer_2, Buffer_Length) then
      begin
        if header then
        begin
          differences.Add('[PatchMaker datafile]');
          differences.Add('');
          differences.Add('The target file is: ' + temp);
          differences.Add('');
          differences.Add('Locations In Mod');
          Writeln('Locations In Mod');
          header := false;
        end;
        ofs.Position := i;
        mfs.Position := i;
        k := 0;
        while k < Block_Size do
        begin
          Buffer_Length := ofs.Read(Buffer_1, 1);
          mfs.Read(Buffer_2, 1);
          bto := Buffer_1[0];
          btm := Buffer_2[0];
          if not CompareMem(@Buffer_1, @Buffer_2, Buffer_Length) then
          begin
            differences.Add('$' + InttoHex(i, 8) + ' ' + InttoHex(bto, 2) + ' ' + InttoHex(btm, 2));
            Writeln('$', InttoHex(i, 8), ' ', InttoHex(bto, 2), ' ', InttoHex(btm, 2));
            j := j + 1;
          end;
          k := k + 1;
          i := i + 1;
        end;
        ofs.Position := i;
        mfs.Position := i;
        i := i - Buffer_Length;
      end;
      i := i + Buffer_Length;
    end;
    if j = 0 then Writeln('The files are identical! No patch file is created or modified.');
  end
  else Writeln('The files have different sizes!');

  ofs.Free;
  mfs.Free;
  if differences.Count <> 0 then
  begin
    differences.SaveToFile(datafile);
    Writeln;
    Writeln('The file was saved as ', datafile);
    Writeln;
    Writeln('When PatchMaker.exe finds ', datafile, ' in the same dir it gets ready to patch');
  end;

  differences.Free;
  Writeln;
  Write('Press the Enter key to exit...');
  Readln;
end.

