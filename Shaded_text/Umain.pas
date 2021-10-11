unit Umain;

interface

uses
  Windows, Dialogs, ComCtrls, StdCtrls, Buttons, ExtCtrls, Controls, Forms,
  Graphics, Classes, SysUtils;

type
  TForm1 = class(TForm)
    imgFond: TImage;
    Panel1: TPanel;
    FontDialog1: TFontDialog;
    edtTexte: TLabeledEdit;
    btnPolice: TBitBtn;
    imgPreVisuel: TImage;
    Label2: TLabel;
    edtOmbreX: TEdit;
    UpDown1: TUpDown;
    edtOmbreY: TEdit;
    UpDown2: TUpDown;
    Label1: TLabel;
    Label3: TLabel;
    procedure imgFondMouseUp(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    procedure PreVisualiser(Sender: TObject);
    procedure btnPoliceClick(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function GetShadowColor( BaseColor: TColor ): TColor; //MADE BY CIREC => UNDER UNLIMITED GUARANTEE ! ;)
     var rgbtResult: TRGBQuad ABSOLUTE Result;
begin
  Result := ColorToRGB( BaseColor );
  with rgbtResult do begin
    //if (rgbRed <= $34) and (rgbGreen <= $34) and (rgbBlue <= $34) then begin
      //Result := clWhite;                // Pas très joli dans le cas présent.
      //Exit;
    //end;
    if rgbRed   > 63 then Dec( rgbRed, 64 )
                     else rgbRed   := 0;
    if rgbGreen > 63 then Dec( rgbGreen, 64 )
                     else rgbGreen := 0;
    if rgbBlue  > 63 then Dec( rgbBlue, 64 )
                     else rgbBlue  := 0;
  end;
end;

procedure TForm1.PreVisualiser(Sender: TObject);
      var Bmp : TBitmap;
begin
  if Form1.edtTexte.Text = '' then exit;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font := Form1.FontDialog1.Font;
    Bmp.Height      := Bmp.Canvas.TextHeight( Form1.edtTexte.Text );
    Bmp.Width       := Bmp.Canvas.TextWidth ( Form1.edtTexte.Text ) + Bmp.Height div 2; //Plus large pour police en italique.
    Bmp.Canvas.TextOut( 0, 0 , Form1.edtTexte.Text );
    Form1.imgPreVisuel.Picture.Bitmap.Assign( Bmp );
  finally Bmp.Free; end;
end;

procedure ShadedTextOut( const Fond   : TBitmap;
                               Texte  : String;
                               Police : TFont;
                               X,Y,
                               DX,DY  : Integer //Décalage de l'ombre.
                                     );
     type pColArray = ^TColArray;
          TColArray = Array[0..1439] of TColor;
      var MasqueAND : TBitmap;
          MasqueOR  : TBitmap;
          BmpDest   : TBitmap;
          Ht,Lg     : Integer;
          Pixels    : pColArray;
          NbrePix   : Integer;
begin
  if Texte  = ''  then exit;
  if Fond   = nil then exit;
  if Police = nil then exit;

  MasqueAND := TBitmap.Create;
  MasqueOR  := TBitmap.Create;
  BmpDest   := TBitmap.Create;
  try
    MasqueAND.Canvas.Brush.Color := clBlack;
    MasqueAND.Canvas.Font        := Police;
    MasqueAND.Canvas.Font.Color  := clWhite;
    Ht := DY + MasqueAND.Canvas.TextHeight( Texte );
    Lg := DX + MasqueAND.Canvas.TextWidth ( Texte ) + Ht div 2; // Plus large pour police en italique.
    if Lg mod 4 <> 0 then Lg := Lg + ( 4 - Lg mod 4 );         // Doit être divisible par 4 pour un seul Scanline.
    MasqueAND.Width  := Lg;
    MasqueAND.Height := Ht;
    MasqueAND.Canvas.TextOut( DX, DY, Texte );

    MasqueOR.PixelFormat := pf32Bit; //Pour travailler avec TColor.
    MasqueOR.Width       := Lg;
    MasqueOR.Height      := Ht;
    MasqueOR.Canvas.CopyRect(MasqueOR.Canvas.ClipRect, // MasqueOR contiendra le fond de l'image d'origine...
                             Fond.Canvas,
                             Rect(X,Y,X+Lg,Y+Ht));

    BmpDest.Assign(MasqueOR);                          //...ainsi que BmpDest.

    {On copie le MasqueAND sur le masqueOR avec l'opérateur AND.}
    BitBlt(MasqueOR.Canvas.Handle,0,0,Lg,Ht,MasqueAND.Canvas.Handle,0,0,SRCAND);

    {Ombrage du Bmp de destination.}
    Pixels := MasqueOR.ScanLine[Ht-1];
    for NbrePix := 1 to Lg*Ht do
        if Pixels[NbrePix] <> clBlack then Pixels[NbrePix] := GetShadowColor(Pixels[NbrePix]);
    BitBlt(MasqueAND.Canvas.Handle,0,0,Lg,Ht,MasqueAND.Canvas.Handle,0,0,DSTINVERT	); //Inversion des couleurs pour obtenir un nouveau masque.
    {Méthode Raster classique en 2 étapes.}
    BitBlt(BmpDest.Canvas.Handle,0,0,Lg,Ht,MasqueAND.Canvas.Handle,0,0,SRCAND);  //Copie de MasqueAND sur BmpDest avec l'opérateur AND.
    BitBlt(BmpDest.Canvas.Handle,0,0,Lg,Ht,MasqueOR.Canvas.Handle,0,0,SRCPAINT); //Copie de MasqueOR sur BmpDest avec l'opérateur OR.

    {L'ombre est dessinée. Maintenant, dessin du texte couleur par la méthode classique.}
    MasqueAND.Canvas.Brush.Color := clWhite;
    MasqueAND.Canvas.FillRect(MasqueAND.Canvas.ClipRect); //Repaint en blanc.
    MasqueAND.Canvas.Font.Color := clBlack;
    MasqueAND.Canvas.TextOut(0,0,Texte); // MasqueAND = texte noir sur fond blanc.

    MasqueOR.Canvas.Brush.Color := clBlack;
    MasqueOR.Canvas.FillRect(MasqueOR.Canvas.ClipRect); //Repaint en noir.
    MasqueOR.Canvas.Font := Police;
    MasqueOR.Canvas.TextOut(0,0,Texte); // MasqueOR = texte couleur sur fond noir.

    BitBlt(BmpDest.Canvas.Handle,0,0,Lg,Ht,MasqueAND.Canvas.Handle,0,0,SRCAND);  // Méthode Raster classique...
    BitBlt(BmpDest.Canvas.Handle,0,0,Lg,Ht,MasqueOR.Canvas.Handle,0,0,SRCPAINT); // ... en 2 étapes.

    Fond.Canvas.CopyRect(Rect(X,Y,X+Lg,Y+Ht),BmpDest.Canvas,BmpDest.Canvas.ClipRect); // On replace le tout sur l'image d'origine.
  finally
    BmpDest.Free;
    MasqueOR.Free;
    MasqueAND.free;
  end;
end;  

procedure TForm1.imgFondMouseUp(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
      var Dx,Dy : Integer;
          Img   : TBitmap;
          S     : String;
begin
  Img := (Sender as TImage).Picture.Bitmap;
  S   := edtTexte.Text;
  Dx  := StrToInt(edtOmbreX.text);
  Dy  := StrToInt(edtOmbreY.text);
  ShadedTextOut( Img, S, FontDialog1.Font, X ,Y ,Dx ,Dy );
end;

procedure TForm1.btnPoliceClick(Sender: TObject);
begin
  if FontDialog1.Execute then PreVisualiser(Sender);
end;

end.
