$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class FontProbe {
    [StructLayout(LayoutKind.Sequential)] public struct Size { public int X; public int Y; }
    [StructLayout(LayoutKind.Sequential)] public struct Abc { public int A; public uint B; public int C; }
    [StructLayout(LayoutKind.Sequential)] public struct Fixed { public ushort Fraction; public short Value; }
    [StructLayout(LayoutKind.Sequential)] public struct Matrix { public Fixed M11; public Fixed M12; public Fixed M21; public Fixed M22; }
    [StructLayout(LayoutKind.Sequential)] public struct Glyph { public uint Width; public uint Height; public int X; public int Y; public short AdvanceX; public short AdvanceY; }
    [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] static extern IntPtr CreateFontW(int height,int width,int escapement,int orientation,int weight,uint italic,uint underline,uint strike,uint charset,uint output,uint clip,uint quality,uint pitch,string name);
    [DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr hdc,IntPtr value);
    [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] static extern bool GetTextExtentPoint32W(IntPtr hdc,string text,int length,out Size size);
    [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] static extern bool GetCharABCWidthsW(IntPtr hdc,uint first,uint last,out Abc abc);
    [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] static extern uint GetGlyphOutlineW(IntPtr hdc,uint character,uint format,out Glyph glyph,uint size,IntPtr buffer,ref Matrix matrix);
    [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr value);
    [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr hdc);
    public static string Measure(string name,int height,string text,int width=0) {
        var dc=CreateCompatibleDC(IntPtr.Zero);
        var font=CreateFontW(height,width,0,0,400,0,0,0,1,0,0,4,0,name);
        var old=SelectObject(dc,font);
        Size size; GetTextExtentPoint32W(dc,text,text.Length,out size);
        Abc abc = new Abc(); if(text.Length>0) GetCharABCWidthsW(dc,text[text.Length-1],text[text.Length-1],out abc);
        Matrix matrix = new Matrix(); matrix.M11.Value=1; matrix.M22.Value=1;
        Glyph glyph = new Glyph(); if(text.Length>0) GetGlyphOutlineW(dc,text[text.Length-1],6,out glyph,0,IntPtr.Zero,ref matrix);
        SelectObject(dc,old); DeleteObject(font); DeleteDC(dc);
        return name+":"+height+":"+text+":"+size.X+","+size.Y+":width="+width+":abc="+abc.A+","+abc.B+","+abc.C+":glyph="+glyph.Width+","+glyph.X+","+glyph.AdvanceX;
    }
}
'@
foreach ($width in @(0,5,6,7,8,9,10,11,12)) {
    Write-Output ('GDI_WIDTH_PROBE:'+[FontProbe]::Measure('Arial',24,'Hello AV iiii WWWW 12345',$width))
}
foreach ($height in @(12,18,32,48)) {
    foreach ($text in @('A','V','AV','Hello AV','A V')) {
        Write-Output ('GDI_SIZE_PROBE:'+[FontProbe]::Measure('Arial',$height,$text))
    }
}
foreach ($height in @(24,-24)) {
    foreach ($name in @('Arial','VL Gothic')) {
        foreach ($text in @('Hello','iiii','WWWW','12345','','H','e','l','o','i','W','1','A','V','AV')) {
            Write-Output ('GDI_PROBE:'+[FontProbe]::Measure($name,$height,$text))
        }
    }
}
