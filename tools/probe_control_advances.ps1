$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ControlAdvances {
  [StructLayout(LayoutKind.Sequential)] public struct Fixed { public ushort Fraction; public short Value; }
  [StructLayout(LayoutKind.Sequential)] public struct Matrix { public Fixed A,B,C,D; }
  [StructLayout(LayoutKind.Sequential)] public struct Metrics { public uint Width,Height; public int X,Y; public short AdvanceX,AdvanceY; }
  [StructLayout(LayoutKind.Sequential)] public struct Size { public int X,Y; }
  [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] public struct TextMetrics { public int Height,Ascent,Descent,InternalLeading,ExternalLeading,AverageWidth,MaximumWidth,Weight,Overhang,AspectX,AspectY; public char First,Last,Default,Break; public byte Italic,Underlined,StruckOut,PitchAndFamily,Charset; }
  [DllImport("gdi32.dll",CharSet=CharSet.Unicode)] public static extern bool GetTextMetricsW(IntPtr dc,out TextMetrics metrics);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr source);
  [DllImport("gdi32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr CreateFontW(int height,int width,int escape,int orientation,int weight,uint italic,uint underline,uint strike,uint charset,uint output,uint clip,uint quality,uint pitch,string name);
  [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr dc,IntPtr obj);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr obj);
  [DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr dc);
  [DllImport("gdi32.dll",CharSet=CharSet.Unicode)] public static extern uint GetGlyphOutlineW(IntPtr dc,uint character,uint format,out Metrics metrics,uint size,IntPtr buffer,ref Matrix matrix);
  [DllImport("gdi32.dll",CharSet=CharSet.Unicode)] public static extern bool GetTextExtentPoint32W(IntPtr dc,string text,int count,out Size size);
  public static void Run() {
    var dc=CreateCompatibleDC(IntPtr.Zero);
    foreach(string name in new string[]{"Arial","nsimsun","", "MS Sans Serif"})
    foreach(int height in new int[]{13,18,20,26,30})
    foreach(int width in new int[]{0}) {
    var font=CreateFontW(height,width,0,0,400,0,0,0,1,0,0,4,0,name);
    var old=SelectObject(dc,font);
    TextMetrics tm; GetTextMetricsW(dc,out tm);
    Console.WriteLine("FONT_METRICS:name={0}:height={1}:average={2}:max={3}:internal={4}",name,height,tm.AverageWidth,tm.MaximumWidth,tm.InternalLeading);
    foreach(string text in new string[]{"Hello AV","HHHH","HHHHHHHHHHHH"}) {
      Size whole; GetTextExtentPoint32W(dc,text,text.Length,out whole);
      Console.WriteLine("WHOLE_EXTENT:width={0}:text={1}:extent={2}",width,text,whole.X);
    }
    try {
      foreach(uint value in new uint[]{10,13,65,66,72,101,108,111,32,86}) {
        var matrix=new Matrix(); matrix.A.Value=1; matrix.D.Value=1;
        Metrics metrics; Size size;
        GetGlyphOutlineW(dc,value,6,out metrics,0,IntPtr.Zero,ref matrix);
        GetTextExtentPoint32W(dc,((char)value).ToString(),1,out size);
        Console.WriteLine("CONTROL_ADVANCE:width={0}:char={1}:glyph={2}:extent={3}:ink={4}",width,value,metrics.AdvanceX,size.X,metrics.Width);
      }
    } finally { SelectObject(dc,old);DeleteObject(font); }
    }
    DeleteDC(dc);
  }
}
'@
[ControlAdvances]::Run()
