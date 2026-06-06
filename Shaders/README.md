# RGSS Unity Shader Port Notes

Translated runtime shaders in this directory:

- `SpriteShader.gdshader` - sprite tone, wave, bush, flash, mirror, opacity, and color mix. Uses M4 packed instance uniforms `_PackedA`, `_PackedB`, `_PackedC`, and `_PackedD`.
- `WindowBackgroundShader.gdshader` - windowskin background tone and gray overlay.
- `PlaneShader.gdshader` - tiled plane rendering with UV modulo, `uv_offset`, optional `TIME` scroll, tone, and color mix.
- `TiledBackgroundShader.gdshader` - tiled window background rendering with UV modulo, `uv_offset`, optional `TIME` scroll, and tone.
- `GraphicsPostprocessShader.gdshader` - M2 BackBufferCopy postprocess brightness/fade using `SCREEN_TEXTURE`.
- `TransitionPostprocessShader.gdshader` - M2 BackBufferCopy transition mask blend using `SCREEN_TEXTURE` for the new frame.
- `ViewportShader.gdshader` - viewport tone and flash overlay.
- `SpriteMaskShader.gdshader` - alpha cutout helper for clipped window contents.

Documented but intentionally not ported:

- `FillRectShader.shader` - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `StretchBltShader.shader` - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `HueChangeShader.shader` (`Custom/HueShiftShader`) - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `BlurShader.shader` - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `BitmapClearShader.shader` - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `GradientFillRectShader.shader` - implemented CPU-side in `Bitmap.cs`, shader not needed.
- `RadiaBlurShader.shader` (`Custom/RadialBlurShader`) - implemented CPU-side in `Bitmap.cs`, shader not needed. Unity also has only a commented `ShaderTest.cs` reference for this outside `Bitmap.cs`.

No other Unity effect shaders were found in `E:\Projects\RGSS-Unity\Assets\Shaders\`.
