{
  Autor: Amarildo Lacerda
  Data: 28/01/2016
  Alteraçoes: 
      28/01/16 - Primeira versão publicada
}

unit System.uJson;

interface

{.$I Delphi.inc }

{$IFDEF UNICODE}
{$DEFINE XE}
{$ENDIF}

uses System.JSON,RegularExpressions, {RTTI, TypInfo, DBXJson,} DBXJsonReflect;

type


   TJsonType = (jtUnknown, jtObject, jtArray, jtString, jtTrue,
       jtFalse, jtNumber, jtDate, jtDateTime, jtBytes);


  TObjectHelper = class Helper for TObject
    public
     class function FromJson(AJson:String) : TObject;static;
     function Close:TObject;
     function asJson:string;
  end;

  TJSONObjectHelper = class helper for TJSONObject
  private

  public
   {$ifdef VER270}
    function ToJSON:string;
   {$endif}
    class function GetTypeAsString(AType: TJsonType): string; static;
    class function GetJsonType(AJsonValue: TJsonValue): TJsonType; static;
    class function Stringify(so: TJSONObject): string;
    class function Parse(const dados: string): TJSONObject;
    function V(chave: String): variant;
    function S(chave: string): string;
    function I(chave: string): integer;
    function O(chave: string): TJSONObject;overload;
    function O(index:integer): TJsonObject;overload;
    function F(chave: string): Extended;
    function B(chave: string): boolean;
    function A(chave: string): TJSONArray;
    function AsArray: TJSONArray;
    function Contains(chave:string):boolean;
    function asObject:TObject;
    class function FromObject<T>(AObject: T): TJSONObject;overload;
//    class function FromObject(AObject: Pointer): TJSONObject;overload;
    class function FromRecord<T>(rec:T):TJSONObject;
  end;

  TJSONArrayHelper = class helper for TJSONArray
  public
    function Length: integer;
  end;

  TJSONValueHelper = class helper for TJsonValue
  public
   {$ifdef VER270}
    function ToJSON:string;
   {$endif}
    function AsArray:TJsonArray;
    function AsPair:TJsonPair;
    function Datatype:TJsonType;
    function asObject:TJsonObject;
  end;

  TJSONPairHelper = class helper for TJSONPair
  public
     function asObject:TJsonObject;
  end;

  IJson = TJSONObject;
  IJSONArray = TJSONArray;

  TJson = TJSONObject;


function ReadJsonString(const dados: string; chave: string): string;
function ReadJsonInteger(const dados: string; chave: string): integer;
function ReadJsonFloat(const dados: string; chave: string): Extended;
// function ReadJsonObject(const dados: string): IJson;
function JSONstringify(so: IJson): string;
function JSONParse(const dados: string): IJson;



function ISODateTimeToString(ADateTime: TDateTime): string;
function ISODateToString(ADate: TDateTime): string;
function ISOTimeToString(ATime: TTime): string;

function ISOStrToDateTime(DateTimeAsString: string): TDateTime;
function ISOStrToDate(DateAsString: string): TDate;
function ISOStrToTime(TimeAsString: string): TTime;



implementation

uses sysUtils, db, System.Rtti, System.TypInfo, System.DateUtils;

var
  LJson: TJson;


 class function TJSONObjectHelper.GetTypeAsString(AType: TJsonType): string;
 begin
  case AType of
     jtUnknown: result := 'Unknown';
    jtString: result := 'String';
     jtTrue,
     jtFalse: result := 'Boolean';
     jtNumber: result := 'Extended';
     jtDate: result := 'TDate';
     jtDateTime: result := 'TDateTime';
     jtBytes: result := 'Byte';
   end;
 end;


 class function TJSONObjectHelper.GetJsonType(AJsonValue: TJsonValue): TJsonType;
   var
     LJsonString: TJSONString;
   begin
     if AJsonValue is TJSONObject then
       result := jtObject
     else
       if AJsonValue is TJSONArray then
         result := jtArray
       else
         if (AJsonValue is TJSONNumber) then
           result := jtNumber
         else
           if AJsonValue is TJSONTrue then
             result := jtTrue
           else
             if  AJsonValue is TJSONFalse then
               result := jtFalse
             else
               if AJsonValue is TJSONString then
               begin
                 LJsonString := (AJsonValue as TJSONString);
                 if TRegEx.IsMatch(LJsonString.Value, '^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])(T| )(2[0-3]|[01][0-9]):?([0-5][0-9]):?([0-5][0-9])$') then
                   result := jtDateTime
                 else
                   if TRegEx.IsMatch(LJsonString.Value, '^([0-9]{4})(-?)(1[0-2]|0[1-9])\2(3[01]|0[1-9]|[12][0-9])$') then
                     result := jtDate
                   else
                     result := jtString
               end
               else
                 result := jtUnknown;
   end;



function JSONParse(const dados: string): IJson;
begin
  result := TJSONObject.ParseJSONValue(dados) as IJson;
end;

function JSONstringify(so: IJson): string;
begin
  result := so.ToJSON;
end;

function ReadJsonFloat(const dados: string; chave: string): Extended;
var
  i: IJson;
begin
  i := JSONParse(dados);
  try
    i.TryGetValue<Extended>(chave, result);
  finally
    i.Free;
  end;
end;

function ReadJsonString(const dados: string; chave: string): string;
var
  j: TJson;
  i: IJson;
  v: variant;
begin
  j := JSONParse(dados);
  // usar variavel local para não gerar conflito com Multi_threaded application
  try
    j.TryGetValue<variant>(chave, v);
    result := v;
    { case VarTypeToDataType of
      varString: Result := I.S[chave];
      varInt64: Result := IntToStr(I.I[chave]);
      varDouble,varCurrency: Result := FloatToStr(I.F[chave]);
      varBoolean: Result := BoolToStr(  I.B[chave] );
      varDate: Result := DateToStr(I.D[chave]);
      else
      result :=  I.V[chave];
      end; }
  finally
    j.Free;
  end;
end;

(* function ReadJsonObject(const dados: string; chave: string): IJson;
  var
  j: TJson;
  begin
  result := JSONParse(dados);
  { // usar variavel local para não gerar conflito com Multi_threaded application
  try
  result := j.parse(dados);
  finally
  j.Free;
  end;}
  end;
*)
function ReadJsonInteger(const dados: string; chave: string): integer;
var
  j: TJson;
  i: IJson;
begin
  j := JSONParse(dados);
  // usar variavel local para não gerar conflito com Multi_threaded application
  try
    j.TryGetValue<integer>(chave, result);
  finally
    j.Free;
  end;
end;

{$IFNDEF MULTI_THREADED}

function JSON: TJson;
begin
  if not assigned(LJson) then
    LJson := TJson.Create;
  result := LJson;
end;

procedure JSONFree;
begin
  if assigned(LJson) then
    FreeAndNil(LJson);
end;
{$ENDIF}
{ TJSONObjectHelper }

function TJSONObjectHelper.A(chave: string): TJSONArray;
begin
  TryGetValue<TJSONArray>(chave,result);
end;

function TJSONObjectHelper.AsArray: TJSONArray;
begin
  result := TJSONObject.ParseJSONValue(self.ToJSON) as TJSONArray;
end;

function TJSONObjectHelper.B(chave: string): boolean;
begin
   tryGetValue<boolean>(chave,result);
end;

function TJSONObjectHelper.Contains(chave: string): boolean;
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := FindValue(chave);
  Result := LJSONValue <> nil;
end;

function TJSONObjectHelper.F(chave: string): Extended;
begin
  tryGetValue<extended>(chave,result);
end;

function TJSONObjectHelper.i(chave: string): integer;
begin
  TryGetValue<integer>(chave, result);
end;

function TJSONObjectHelper.O(index: integer): TJsonObject;
var pair:TJSONPair;
begin
   result := TJsonObject( get(index) );
end;

function TJSONObjectHelper.O(chave: string): TJSONObject;
begin
  TryGetValue<TJSONObject>(chave, result);
end;

class function TJSONObjectHelper.Parse(const dados: string): TJSONObject;
begin
  result := TJSONObject.ParseJSONValue(dados) as TJSONObject;
end;


class function TJSONObjectHelper.FromRecord<T>(rec: T): TJSONObject;
var
  m:TJSONMarshal;
  js:TJSONValue;
begin
{  m := TJSONMarshal.Create;
  try
  js := m.Marshal(AObject);
  result := js as TJSONObject;
  finally
    m.Free;
  end;
  }
   result := TJSONObject.FromObject<T>(rec);
end;

class function TJSONObjectHelper.FromObject<T>(AObject: T): TJSONObject;
var typ:TRttiType;
    ctx : TRttiContext;
    field : TRttiField;
    tk:TTypeKind;
    P:Pointer;
    key:String;
    FRecord  : TRttiRecordType;
    FMethod: TRttiMethod;
begin
   result := TJsonObject.Create;
   ctx := TRttiContext.Create;
   typ := ctx.GetType( TypeInfo(T) );
   P := @AObject;
   for field in typ.GetFields do
     begin
        key := field.Name.ToLower;
        if not (field.Visibility in [mvPublic, mvPublished]) then continue;
        tk := field.FieldType.TypeKind;
        case tk of
          tkRecord:
             begin
{                 FRecord := ctx.GetType(field.GetValue(P).TypeInfo).AsRecord ;
                 FMethod := FRecord.GetMethod('asJson');
                 if assigned(FMethod) then
                 begin
                    result.AddPair(key,fMethod.asJson );
                 end;}
             end;
          tkInteger : result.AddPair(key,TJSONNumber.Create( field.GetValue(P).AsInteger ));
          tkFloat :
          begin
           if sametext(field.FieldType.Name ,'TDateTime') then
             result.AddPair(TJSONPair.Create(key, ISODateTimeToString( field.GetValue(P).asExtended )))
           else
           if sametext(field.FieldType.Name ,'TDate') then
             result.AddPair(TJSONPair.Create(key, IsoDateToString( field.GetValue(P).asExtended)))
           else
           if sametext(field.FieldType.Name ,'TTime') then
             result.AddPair(TJSONPair.Create(key, isoTimeToString( field.GetValue(P).AsExtended) ))
           else
           if sametext(field.FieldType.Name ,'TTimeStamp') then
             result.AddPair(TJSONPair.Create(key, ISODateTimeToString( field.GetValue(P).asExtended)))
           else
             result.AddPair(key,TJSONNumber.Create( field.GetValue(P).AsExtended ));
          end
        else
           result.AddPair(TJsonPair.Create(key,field.getValue(P).ToString));
        end;
     end;
end;

function TJSONObjectHelper.s(chave: string): string;
begin
  TryGetValue<string>(chave, result);
end;

class function TJSONObjectHelper.Stringify(so: TJSONObject): string;
begin
  result := so.ToJSON;
end;

function TJSONObjectHelper.v(chave: String): variant;
var
  v: string;
begin
  TryGetValue<string>(chave, v);
  result := v;
end;

function TJSONObjectHelper.asObject:TObject;
var m:TJSONunMarshal;
begin
    m:=TJSONunMarshal.create;
    try
    result := m.Unmarshal( self);
    finally
      m.Free;
    end;
end;

{$ifdef VER270}
    function TJSONObjectHelper.ToJSON:string;
    begin
       result := ToString;
    end;
   {$endif}


{ TJSONArrayHelper }

function TJSONArrayHelper.Length: integer;
begin
  result := Count;
end;

{ TJSONValueHelper }
{$ifdef VER270}
function TJSONValueHelper.ToJSON: string;
begin
    result := ToString;
end;
{$endif}

{ TJSONValueHelper }

function TJSONValueHelper.AsArray: TJsonArray;
begin
    result := self as TJsonArray;
end;

function TJSONValueHelper.asObject: TJsonObject;
begin
   result := self as TJsonObject;
end;

function TJSONValueHelper.AsPair: TJsonPair;
begin
   result := TJSONPair(self);
end;

function TJSONValueHelper.Datatype: TJsonType;
begin
   result := TJSONObject.GetJsonType(self);
end;

{ TJSONPairHelper }

function TJSONPairHelper.asObject: TJsonObject;
begin
   result := (self.JsonValue) as  TJsonObject;
end;

{ TObjectHelper }

function TObjectHelper.asJson: string;
var J:TJSONValue;
    m:TJSONMarshal;
begin
    m:=TJSONMarshal.create;
    try
      j := m.Marshal(self) ;
      result := j.ToJSON;
    finally
      m.Free;
    end;
end;

function TObjectHelper.Close: TObject;
begin
    result := TObject.FromJson(asJson);
end;

class function TObjectHelper.FromJson(AJson:String) : TObject;
var m:TJSONUnMarshal;
    v:TJSONObject;
begin
   m:=TJSONUnMarshal.create;
   try
      v := TJsonObject.Parse(AJson);
      result := m.Unmarshal(v);
   finally
      m.Free;
   end;
end;


function ISOTimeToString(ATime: TTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', ATime, fs);
end;

function ISODateToString(ADate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', ADate);
end;

function ISODateTimeToString(ADateTime: TDateTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADateTime, fs);
end;

function ISOStrToDateTime(DateTimeAsString: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(DateTimeAsString, 1, 4)),
    StrToInt(Copy(DateTimeAsString, 6, 2)), StrToInt(Copy(DateTimeAsString, 9, 2)),
    StrToInt(Copy(DateTimeAsString, 12, 2)), StrToInt(Copy(DateTimeAsString, 15, 2)),
    StrToInt(Copy(DateTimeAsString, 18, 2)), 0);
end;

function ISOStrToTime(TimeAsString: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(TimeAsString, 1, 2)), StrToInt(Copy(TimeAsString, 4, 2)),
    StrToInt(Copy(TimeAsString, 7, 2)), 0);
end;

function ISOStrToDate(DateAsString: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(DateAsString, 1, 4)), StrToInt(Copy(DateAsString, 6, 2)),
    StrToInt(Copy(DateAsString, 9, 2)));
  // , StrToInt
  // (Copy(DateAsString, 12, 2)), StrToInt(Copy(DateAsString, 15, 2)),
  // StrToInt(Copy(DateAsString, 18, 2)), 0);
end;


// function ISODateToStr(const ADate: TDate): String;
// begin
// Result := FormatDateTime('YYYY-MM-DD', ADate);
// end;
//
// function ISOTimeToStr(const ATime: TTime): String;
// begin
// Result := FormatDateTime('HH:nn:ss', ATime);
// end;


initialization

finalization

{$ifndef MULTI_THREADED}
JSONFree;
{$endif}

end.