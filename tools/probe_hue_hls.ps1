$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class HueProbe {
  [DllImport("shlwapi.dll")] public static extern void ColorRGBToHLS(uint rgb, out ushort h, out ushort l, out ushort s);
  [DllImport("shlwapi.dll")] public static extern uint ColorHLSToRGB(ushort h, ushort l, ushort s);
  public static string Run(int r,int g,int b,int degrees) {
    ushort h,l,s;
    ColorRGBToHLS((uint)(r | (g<<8) | (b<<16)),out h,out l,out s);
    var shifted=(ushort)(((h + degrees*240/360)%240+240)%240);
    var rgb=ColorHLSToRGB(shifted,l,s);
    return string.Format("{0},{1},{2};{3};HLS={4},{5},{6};RGB={7},{8},{9}",r,g,b,degrees,h,l,s,rgb&255,(rgb>>8)&255,(rgb>>16)&255);
  }
}
'@
[HueProbe]::Run(255,0,0,120)
[HueProbe]::Run(31,31,30,120)
[HueProbe]::Run(200,80,10,90)
[HueProbe]::Run(200,80,10,-90)
[HueProbe]::Run(62,62,60,120)
[HueProbe]::Run(93,93,90,120)
[HueProbe]::Run(217,217,210,120)
