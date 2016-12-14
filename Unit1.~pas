unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, shellapi, ExtCtrls;

type
  TForm1 = class(TForm)
    ComboBox1: TComboBox;
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
  SelectedRule:String;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
    SelectedRule:= ComboBox1.Text;
    Form1.Close;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    SelectedRule:= '';
    Form1.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SelectedRule:= '';
  Form1.Icon.Handle :=  extracticon(hinstance,'1cv7s.exe',0);
end;

end.
