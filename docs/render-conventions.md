# Render Conventions

These rules apply to every render binding task in this codebase.

1. M2, implement Graphics postprocess with one `BackBufferCopy` per frame.
   - Ruling: RMVA `Graphics.fadeout`, `fadein`, `transition`, `freeze`, and `brightness` effects run as a postprocess chain that reads the composited frame through Godot's `hint_screen_texture`.
   - Keep the RMVA world render in a composite `CanvasLayer`, then place exactly one `BackBufferCopy` node between that composite layer and the postprocess layer.
   - Do not add one `BackBufferCopy` per pass. The copy is a frame boundary. All postprocess passes for that frame must sample the same copied screen texture, then pass intermediate color inside the postprocess shader or through postprocess nodes that do not request another screen copy.
   - `BackBufferCopy.copy_mode` should cover the full legacy render rectangle. In legacy mode that rectangle is 544x416. In non-legacy mode it matches the configured render surface.
   - The postprocess `CanvasLayer` draws a full-screen `ColorRect` or equivalent `CanvasItem` using a CanvasItem shader with `uniform sampler2D screen_texture : hint_screen_texture`.
   - The shader samples `screen_texture` for the already-composited RMVA frame, then applies brightness, freeze/transition mix, fade color, and any later Graphics postprocess effect in the same ordered chain.
   - Rationale: Godot's screen texture is populated from a back-buffer copy. Keeping a single copy point makes frame identity explicit and prevents later passes from accidentally sampling partially processed output.
   - Node-tree example:
     ```text
     Root
     ├── RmvaCompositeLayer : CanvasLayer(layer = 0)
     │   └── RmvaRenderRoot : Node2D
     │       ├── ViewportWrapper_0 : Sprite2D
     │       ├── ViewportWrapper_1 : Sprite2D
     │       └── DirectScreenObjects : Node2D
     ├── GraphicsBackBufferCopy : BackBufferCopy
     │   ├── copy_mode = VIEWPORT or RECT
     │   └── rect = Rect2(0, 0, render_width, render_height)
     └── GraphicsPostprocessLayer : CanvasLayer(layer = 1)
         └── GraphicsPostprocessQuad : ColorRect
             ├── anchors = full render surface
             └── material = GraphicsPostprocessMaterial
                 └── screen_texture uses hint_screen_texture
     ```

2. M3, map RMVA Z with one CanvasLayer and absolute `z_index`.
   - Ruling: keep all RMVA render objects in one `CanvasLayer` with `layer = 0`.
   - Do not create a new `CanvasLayer` for each RMVA `Viewport`, `Sprite`, `Plane`, or `Window`.
   - Set `z_as_relative = false` on every RMVA render `CanvasItem` that participates in RGSS ordering.
   - Use Godot `z_index` values in the RMVA range 0..200 directly. Do not remap or offset the range unless a later task proves a Godot engine limit requires it.
   - Each RGSS `Viewport` owns a `SubViewport`. The wrapper that displays that `SubViewport` in the main scene is a `Sprite2D` in the single RMVA `CanvasLayer`, with `z_index = viewport.z`.
   - Per-object Z inside a viewport stays inside that viewport. `Sprite2D`, `NinePatchRect`, window contents, and plane nodes rendered into the viewport use `z_index = object.z` and `z_as_relative = false`.
   - Apply coordinate conversion at the render boundary. RGSS positions are top-down and the Unity port flips Y with `-data.Y`; the Godot port must keep that boundary rule near the node placement code, not inside unrelated Ruby data objects.
   - Rationale: RMVA's documented Z range is small and global enough for Godot's `z_index`. A single layer avoids CanvasLayer proliferation, keeps input and postprocess ordering simple, and matches Unity's `sortingOrder = data.Z` contract.
   - Node-tree example:
     ```text
     RmvaCompositeLayer : CanvasLayer(layer = 0)
     └── RmvaRenderRoot : Node2D
         ├── ViewportAWrapper : Sprite2D
         │   ├── texture = ViewportA.get_texture()
         │   ├── z_as_relative = false
         │   └── z_index = viewport_a.z
         ├── ViewportBWrapper : Sprite2D
         │   ├── texture = ViewportB.get_texture()
         │   ├── z_as_relative = false
         │   └── z_index = viewport_b.z
         └── ScreenPlaneWrapper : Sprite2D
             ├── z_as_relative = false
             └── z_index = plane.z

     ViewportA : SubViewport
     └── ViewportARoot : Node2D
         ├── RgssSprite : Sprite2D
         │   ├── z_as_relative = false
         │   └── z_index = sprite.z
         └── RgssWindow : NinePatchRect
             ├── z_as_relative = false
             └── z_index = window.z
     ```

3. M4, pack Sprite instance shader parameters into four vec4 uniforms.
   - Ruling: RGSS `Sprite` effect data must fit the normal batched path by using four CanvasItem `instance uniform vec4` values named `_PackedA`, `_PackedB`, `_PackedC`, and `_PackedD`.
   - Do not add separate instance uniforms for each sprite effect parameter.
   - The C# binding normalizes packed values before calling `set_instance_shader_parameter`. The shader denormalizes only when it needs RGSS-space values for math.
   - Keep Unity's Sprite effect order in the Godot shader: mirror, wave, gray, tone, opacity, bush, flash. Do not move packing concerns into Ruby wrappers.
   - Channel layout:

     | Uniform | Channel | Parameter | C# value written | Shader use |
     | --- | --- | --- | --- | --- |
     | `_PackedA` | x | wave amplitude | raw `wave_amp` float | use directly for wave math |
     | `_PackedA` | y | wave length | raw `wave_length` float | use directly for wave math |
     | `_PackedA` | z | wave speed | raw `wave_speed` float | use directly for wave phase math |
     | `_PackedA` | w | bush opacity | `bush_opacity / 255.0` | already 0..1 |
     | `_PackedB` | x | tone.r | `tone.r / 255.0` | normalized signed tone, range -1..1 |
     | `_PackedB` | y | tone.g | `tone.g / 255.0` | normalized signed tone, range -1..1 |
     | `_PackedB` | z | tone.b | `tone.b / 255.0` | normalized signed tone, range -1..1 |
     | `_PackedB` | w | tone.gray | `tone.gray / 255.0` | grayscale amount, range 0..1 |
     | `_PackedC` | x | flash.r | `flash.r / 255.0` | flash color red, range 0..1 |
     | `_PackedC` | y | flash.g | `flash.g / 255.0` | flash color green, range 0..1 |
     | `_PackedC` | z | flash.b | `flash.b / 255.0` | flash color blue, range 0..1 |
     | `_PackedC` | w | flash.a | `flash.a / 255.0` | flash alpha/progress amount, range 0..1 |
     | `_PackedD` | x | opacity | `opacity / 255.0` | already 0..1 |
     | `_PackedD` | y | mirror | `1.0` when mirrored, else `0.0` | boolean flag |
     | `_PackedD` | z | gray enabled | `1.0` when tone.gray > 0, else `0.0` | boolean gate for grayscale branch if needed |
     | `_PackedD` | w | reserved | `0.0` | reserved, must stay unused until this spec is revised |

   - Normalization conventions:
     - Wave amplitude, length, and speed are not normalized. They are shader math inputs and stay in RGSS units.
     - Tone RGB starts as RGSS floats in -255..255. C# writes -1..1 by dividing by 255.0. The shader adds the normalized signed value to sampled RGB, matching Unity's shader-facing `_Tone.rgb` behavior.
     - Tone gray starts as 0..255. C# writes 0..1. The shader uses it as the grayscale mix amount.
     - Flash RGBA starts as 0..255. C# writes 0..1. The shader treats `_PackedC.rgb` as color and `_PackedC.w` as the flash mix amount.
     - Opacity and bush opacity start as 0..255. C# writes 0..1. The shader multiplies alpha by these values directly.
     - Mirror and gray enabled are flags written as 0.0 or 1.0. The shader must not infer mirror from negative scale because RGSS mirror is an effect parameter.
   - Required call pattern:
     ```text
     sprite_node.set_instance_shader_parameter("_PackedA", Vector4(wave_amp, wave_length, wave_speed, bush_opacity / 255.0))
     sprite_node.set_instance_shader_parameter("_PackedB", Vector4(tone.r / 255.0, tone.g / 255.0, tone.b / 255.0, tone.gray / 255.0))
     sprite_node.set_instance_shader_parameter("_PackedC", Vector4(flash.r / 255.0, flash.g / 255.0, flash.b / 255.0, flash.a / 255.0))
     sprite_node.set_instance_shader_parameter("_PackedD", Vector4(opacity / 255.0, mirror ? 1.0 : 0.0, tone.gray > 0 ? 1.0 : 0.0, 0.0))
     ```
   - Rationale: Godot CanvasItem instance uniforms are limited enough that one parameter per uniform would waste the batched path. Four packed vec4s cover the Unity Sprite shader's effect inputs while leaving one reserved channel for a future compatible revision.
   - Fallback: if a future Sprite effect needs more than these four vec4 values, duplicate the `ShaderMaterial` per sprite and set normal material uniforms on that duplicate. That sprite leaves the batched instance-uniform path by design.

