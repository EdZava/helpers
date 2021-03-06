unit uMenuItemSimple;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  plugin.Interf, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses plugin.Service, plugin.MenuItem, plugin.Control;

procedure TForm1.Button1Click(Sender: TObject);
begin
  close;
end;


initialization

RegisterPlugin(TPluginMenuItemService.Create(TForm1,'',1, 'Menu base de sample'));
RegisterPlugin(TPluginControlService.create(TForm1,1,0,'my control embbedded'));


finalization

end.
