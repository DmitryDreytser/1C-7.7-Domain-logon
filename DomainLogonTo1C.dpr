﻿program DomainLogonTo1C;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  Windows,
  SysUtils,
  CompDoc,
  Classes,
  LCLIntf, LCLType,Forms, Interfaces, Messages,
  Unit1 in 'Unit1.pas',
  jwawinuser;

//{$R *.res}

Function GetUserFromWindows: string;
Var
  UserName    : string;
  UserNameLen : Dword;
Begin
  UserNameLen := 255;
  SetLength(userName, UserNameLen);
  If GetUserName(PChar(UserName), UserNameLen) Then
    Result := Copy(UserName,1,UserNameLen - 1)
  Else
  Result := '';
End;

Function GetUsersList(const basedir: string ; const DUserName : string; FullUserName: string) : TStringList;
var
 RootStorage : TRootStorage;
 streams, UserNames, UserRules, PageList, HashList: TStringList;

 storagestream, pagestream: TStorageStream;
 NameOfRoot: string;
 UserName,UserRule,StringOfStorage,PageName, UserHash: string;
 buffer,pageBuffer : array[0..500000] of byte;
 n,i,j,k,PageProperty: integer;

begin
  NameOfRoot := basedir + 'usrdef\users.usr';
  UserNames := tStringList.Create;
  UserRules := tStringList.Create;
  PageList  := tStringList.Create;
  HashList  := tStringList.Create;
  GetUsersList:=tStringList.Create;


    if FileExists(NameOfRoot) and FileIsCompoundDoc(NameOfRoot) then
    begin
    RootStorage := TRootStorage.Create(NameOfRoot, amRead, smDenyNone, tmTransacted, false);

  streams   := TStringList.Create;
  try
    RootStorage.ListStreams(streams);
    if streams.Count > 0 then
        begin
          storagestream := TStorageStream.Create('Container.Contents',RootStorage, amRead, false);
          //MessageBox(0,PChar(IntToStr(storagestream.Size)),'Ошибка',0);
          //SetLength(buffer, storagestream.Size);
          storagestream.Read(buffer,storagestream.Size);
          PageProperty:=0;
          for i:=22 to storagestream.Size - 1 do
          begin
             IF Chr(buffer[i]) = '{' then PageProperty := 1;

             CAse PageProperty of
             1:
                 Case Chr(buffer[i]) of
                  ',': PageProperty:= PageProperty + 1;
                 End;
             2:
                 Case Chr(buffer[i]) of
                  ',': PageProperty:= PageProperty + 1;
                  '"': begin end;
                  Else PageName := PageName + Chr(buffer[i]);
                 End;
             3:
                 Case Chr(buffer[i]) of
                  ',': PageProperty:= PageProperty + 1;
                  '"': begin end;
                  Else UserName := UserName + Chr(buffer[i]);
                 End;
             4:
                    Case Chr(buffer[i]) of
                      '}': Begin
                           PageProperty:= 0;
                           End;
                      '"': begin end;
                    End;
             0: BEgin
                //MessageBox(0,PChar(UserName),'Ошибка',0);
                If (pos(dUserName,UserName) <> 0) OR (pos(FullUserName,UserName) <> 0) then //
                begin
                   UserNames.Add(UserName);
                   PageList.Add(PageName);
                End;
                PageName:='';
                UserName:='';
                End;
             end;

          end;
          storagestream.Destroy;
            For i:= 0 to UserNames.Count - 1 do Begin
                   pagestream := TStorageStream.Create(PageList[i],RootStorage, amRead, false);
                //   SetLength(pageBuffer, storagestream.Size);
                   pagestream.Read(pageBuffer,storagestream.Size);
                   k := 8 + pageBuffer[8] + 1;
                   k := 8;

//                   For n:=0 to pageBuffer[0] do UserHash:=UserHash + Chr(pageBuffer[n]);
//                   MessageBox(0,PChar('Хэш ' + UserHash),'Ошибка',0);

                   for n:=1 to 8 do
                    begin
                      StringOfStorage:='';
                        for j:=k+1 to k+pageBuffer[k] do
                        if pageBuffer[j]>0 then StringOfStorage:=StringOfStorage+chr(pageBuffer[j]);
                        IF n = 8 Then UserRule:= StringOfStorage;
                        IF n = 1 Then UserHash:= StringOfStorage;
                      k:=k+pageBuffer[k]+1;
                    end;
                    UserRules.Add(UserRule);
                    HashList.Add(UserHash);
                     Form1.ComboBox1.Items.Add(UserRule);
                    pagestream.Destroy;
            end;
    end;
  finally
    streams.Free;
  end;
    RootStorage.Free;
  end;
           If UserRules.Count > 1 Then
           Begin
             Form1.ComboBox1.ItemIndex:=0;
             Form1.ShowModal;
             If Unit1.SelectedRule = '' Then GetUsersList.Clear
               Else Begin
                  i:=0;
                  UserRules.Find(Unit1.SelectedRule,i);
                  GetUsersList.Add(UserNames[i]);
                  GetUsersList.Add(HashList[i]);
               End;
           End
           Else If UserRules.Count = 0 Then Begin
                  //GetUsersList:='';
                  MessageBoxW(0,PWChar('Пользователя с именем ' + DUserName + ' нет в списке пользователей.'),'Ошибка',0);
           End
           Else IF UserRules.Count = 1 then begin
                  GetUsersList.Add(UserNames[0]);
                  GetUsersList.Add(HashList[0]);
           end;

end;

Var
  hProc, PID, numberRead : DWORD;
  hWnd,hWndChild  : THandle; // Хэндл окна
  DUserName, UserName: String;
  FullUserName:String;
  iPBuf: DWORD;
  SI: STARTUPINFOA;
  PI: PROCESS_INFORMATION;
  UserHash:AnsiString;
  DbPath :array [0..255] of Char;
  Buf: byte;
  ExePath:String;
  UserParamList:TStringList;
  //i:integer;

{$R *.res}


begin
  Application.Initialize;
    DUserName := GetUserFromWindows(); // Взяли доменное имя пользователя
  If ParamCount > 0 Then ExePath:=ParamStr(1)
  Else ExePath:= '1cv7s.exe';


  IF NOT CreateProcess(nil,PChar(ExePath),nil,nil,False,0,nil,nil,SI,PI) Then begin
       MessageBoxW(0,PWChar('Не найден исполняемый файл 1С. ' + ExePath),'Ошибка',0);
       Exit;
     end;
  hProc:= PI.hProcess;
  While GetGuiResources(hProc,GR_USEROBJECTS) = 0 do begin //Цикл ожидания зарузки процесса 1С
    Sleep(20); //Если не добавить Sleep будет загрузка процессора под 80%
  end;
  PID := 0;
  hWND:= 0;
  if hProc <> 0 then // условие проверки подключения к процессу
  try
    While PID <> PI.dwProcessId do Begin //Цмкл ожидания окна авторизации
      hWnd:=findwindowW('#32770',PWCHAR('Авторизация  доступа')); //Находим окно с нужным заголовком
      IF hWND <> 0 Then GetWindowThreadProcessId(hWnd, @Pid);  //Берем PID процесса окна
      If GetGuiResources(hProc,GR_USEROBJECTS) = 0 Then Exit;  //Окно выбора баз закрыли
      Sleep(5); //Если не добавить Sleep будет загрузка процессора под 80%
    End;
    //Exit;

    showwindow(hWND,sw_hide);   //скрыли окно авторизации
    SuspendThread(PI.hThread); // Заморозили поток чтобы пользователь не авторизовался пока мы собриаем список пользователей
//    Для того, чтобы получить путь к выбранной базе нужно внутри процесса 1С пройти по двум ссылкам.
//    Модуль 1Cv7s.exe загружается по адресу 400000h. Ссылки на переменную искал при помощи CheatEngine
//    362CC -> +$4 ->
//    Т.е. сначало нужно прочитать значение по адресу 4362СС. К этому значени добавить 4.
//    Взять его как следующий адрес и прочитать еще одно значение.
//    Взять его как следующий адрес и прочить по этому адресу строку длиной 255 байт
    ReadProcessMemory(hProc, Pointer($004362CC), @iPBuf, SizeOf(iPBuf), numberRead); // чтение из памяти адреса
    ReadProcessMemory(hProc, Pointer(iPBuf + 4), @iPBuf, SizeOf(iPBuf), numberRead); // чтение из памяти следующего адреса
    ReadProcessMemory(hProc, Pointer(iPBuf), @DbPath, SizeOf(DbPath), numberRead);   // чтение из памяти строки пути к базе
    Application.CreateForm(TForm1, Form1);
    UserName :='';
    FullUserName:=StringReplace(FullUserName,' ','',[rfReplaceAll]);
    UserParamList := GetUsersList(DbPath, DUserName, DUserName);
    UserName:=UserParamList[0];
    UserHash:=UserParamList[1];
    iF UserParamList.Count = 0 Then Begin
      TerminateProcess(hProc,1);
      CloseHandle(PI.hProcess); { *Преобразовано из CloseHandle* }
      CloseHandle(PI.hThread); { *Преобразовано из CloseHandle* }
      exit;
    End;
    //26029691  50  Push EAX           2602969C
    //26029692  51  Push ECX
    //26029693  FF15 24B90326  CALL DWORD PTR DS:[<&MSVCRT._mbscmp>]    ; \_mbscmp

    //Патчим код библиотеки UserDef.dll, для того чтобы пароль сравнивался сам с собой, т.к. пароль вводить не будем.
    //Тонкое место т.к. userdef.dll может оказаться загруженной по другому адресу.
    Buf:=$51;
    WriteProcessMemory(hProc, Pointer($26029691) { *Преобразовано из Ptr* }, @Buf,1,numberRead);
    //Sleep(20);
    //26029691  51  Push ECX
    //26029692  51  Push ECX
    //26029693  FF15 24B90326  CALL DWORD PTR DS:[<&MSVCRT._mbscmp>]    ; \_mbscmp
    ResumeThread(PI.hThread);  // Разморозили поток

    hWndChild := FindWindowEx(HWnd, 0,'ComboBox','');
    SendMessage(hWndChild,CB_SETCURSEL,SendMessage(hWndChild,cb_FindString,-1,Integer(UserName)),0);
    hWndChild := FindWindowEx(HWnd, 0,'Button','OK');
    SendMessage(hWndChild, BM_CLICK,0,0);
    Sleep(5000);

    //CloseHandle(PI.hProcess); { *Преобразовано из CloseHandle* }
    //CloseHandle(PI.hThread); { *Преобразовано из CloseHandle* }
    exit;

    //PID := 0;
    //
    //While PID <> PI.dwProcessId do Begin //Цмкл ожидания окна 1С
    //  hWnd:=findwindow('#32770',''); //Находим окно с нужным заголовком
    //  IF hWND <> 0 Then GetWindowThreadProcessId(hWnd, @Pid);  //Берем PID процесса окна
    //  If GetGuiResources(hProc,GR_USEROBJECTS) = 0 Then Exit;  //Окно выбора баз закрыли
    //  Sleep(5); //Если не добавить Sleep будет загрузка процессора под 80%
    //End;
    //
    //MessageBoxW(0,PWChar(String(UserHash)),'Ошибка',0);
    //SuspendThread(PI.hThread);
    //For i:=0 to Length(UserHash) do bUserHash[i]:= UserHash[i];
    //WriteProcessMemory(hProc, Pointer($05D7E5A8), @bUserHash, SizeOf(UserHash), numberRead);
    //ResumeThread(PI.hThread);
  finally
    Begin
     CloseHandle(PI.hProcess); { *Преобразовано из CloseHandle* }
     CloseHandle(PI.hThread); { *Преобразовано из CloseHandle* }
    End;
  End;
exit;
end.
