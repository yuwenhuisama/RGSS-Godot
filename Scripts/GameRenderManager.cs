using System;
using System.Collections.Generic;
using Godot;
using RGSSUnity.RubyClasses;

namespace RGSSUnity;

public sealed class GameRenderManager : IDisposable
{
    public static readonly GameRenderManager Instance = new();
    public static HashSet<BitmapData> DirtyBitmapDataSet = new();

    private readonly Dictionary<ViewportData, ViewportRenderEntry> viewports = new();
    private readonly Dictionary<SpriteData, SpriteDataNode> sprites = new();
    private readonly Dictionary<PlaneData, PlaneDataNode> planes = new();
    private readonly Dictionary<WindowData, WindowDataNode> windows = new();
    private readonly Dictionary<TilemapData, TilemapDataNode> tilemaps = new();
    private readonly List<ViewportData> sortedViewports = new();
    private readonly List<ViewportData> pendingViewports = new();
    private readonly List<SpriteData> pendingSprites = new();
    private readonly List<PlaneData> pendingPlanes = new();
    private readonly List<WindowData> pendingWindows = new();
    private readonly List<TilemapData> pendingTilemaps = new();

    private CanvasLayer? compositeLayer;
    private Node2D? renderRoot;
    private BackBufferCopy? backBufferCopy;
    private CanvasLayer? postprocessLayer;
    private ColorRect? postprocessQuad;
    private Node? parent;
    private ShaderMaterial? spriteMaterial;
    private ShaderMaterial? postprocessMaterial;
    private bool initialized;
    private bool viewportNodeCreationReady;

    private GameRenderManager()
    {
    }

    public void Initialize(Node parent)
    {
        if (this.initialized)
            return;

        this.parent = parent;
        this.viewportNodeCreationReady = false;

        this.compositeLayer = new CanvasLayer
        {
            Name = "RmvaCompositeLayer",
            Layer = 0,
        };
        parent.AddChild(this.compositeLayer);

        this.renderRoot = new Node2D
        {
            Name = "RmvaRenderRoot",
        };
        this.compositeLayer.AddChild(this.renderRoot);

        this.backBufferCopy = new BackBufferCopy
        {
            Name = "GraphicsBackBufferCopy",
            CopyMode = BackBufferCopy.CopyModeEnum.Viewport,
        };
        parent.AddChild(this.backBufferCopy);

        this.postprocessLayer = new CanvasLayer
        {
            Name = "PostprocessLayer",
            Layer = 1,
        };
        parent.AddChild(this.postprocessLayer);

        var renderSize = GetRenderSize();
        this.postprocessQuad = new ColorRect
        {
            Name = "PostprocessQuad",
            Size = renderSize,
            Color = Colors.Transparent,
        };
        var postprocessShader = GD.Load<Shader>("res://Shaders/GraphicsPostprocessShader.gdshader");
        if (postprocessShader is not null)
        {
            this.postprocessMaterial = new ShaderMaterial { Shader = postprocessShader };
            this.postprocessMaterial.SetShaderParameter("brightness", 1.0f);
            this.postprocessQuad.Material = this.postprocessMaterial;
        }

        this.postprocessQuad.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        this.postprocessLayer.AddChild(this.postprocessQuad);

        var spriteShader = GD.Load<Shader>("res://Shaders/SpriteShader.gdshader");
        if (spriteShader is not null)
            this.spriteMaterial = new ShaderMaterial { Shader = spriteShader };

        this.initialized = true;
    }

    public void Update()
    {
        ResetDirtyDataSet();

        if (this.pendingViewports.Count > 0 && this.initialized && this.renderRoot is not null)
        {
            var pendingViewports = new List<ViewportData>(this.pendingViewports);
            this.pendingViewports.Clear();

            foreach (var viewportData in pendingViewports)
                this.RegisterViewport(viewportData);
        }

        if (this.pendingSprites.Count > 0 && this.initialized)
        {
            var pendingSprites = new List<SpriteData>(this.pendingSprites);
            this.pendingSprites.Clear();

            foreach (var spriteData in pendingSprites)
            {
                if (spriteData.Viewport is not null)
                    this.RegisterSprite(spriteData, spriteData.Viewport);
            }
        }

        if (this.pendingPlanes.Count > 0 && this.initialized)
        {
            var pendingPlanes = new List<PlaneData>(this.pendingPlanes);
            this.pendingPlanes.Clear();

            foreach (var planeData in pendingPlanes)
            {
                if (planeData.Viewport is not null)
                    this.RegisterPlane(planeData, planeData.Viewport);
            }
        }

        if (this.pendingWindows.Count > 0 && this.initialized)
        {
            var pendingWindows = new List<WindowData>(this.pendingWindows);
            this.pendingWindows.Clear();

            foreach (var windowData in pendingWindows)
            {
                if (windowData.Viewport is not null)
                    this.RegisterWindow(windowData, windowData.Viewport);
            }
        }

        if (this.pendingTilemaps.Count > 0 && this.initialized)
        {
            var pendingTilemaps = new List<TilemapData>(this.pendingTilemaps);
            this.pendingTilemaps.Clear();

            foreach (var tilemapData in pendingTilemaps)
            {
                if (tilemapData.Viewport is not null)
                    this.RegisterTilemap(tilemapData, tilemapData.Viewport);
            }
        }

        this.viewportNodeCreationReady = true;

        if (!this.initialized || this.renderRoot is null)
            return;

        this.sortedViewports.Clear();
        this.sortedViewports.AddRange(this.viewports.Keys);
        this.sortedViewports.Sort(static (left, right) => left.Z.CompareTo(right.Z));

        foreach (var viewportData in this.sortedViewports)
        {
            if (!this.viewports.TryGetValue(viewportData, out var entry))
                continue;

            entry.Wrapper.ZIndex = viewportData.Z;
            entry.Wrapper.Position = new Vector2(-viewportData.Ox, -viewportData.Oy);

            foreach (var child in entry.SubViewportRoot.GetChildren())
            {
                if (child is SpriteDataNode spriteNode)
                    RenderSprite(spriteNode.Data);
                else if (child is PlaneDataNode planeNode)
                    RenderPlane(planeNode.Data);
                else if (child is WindowDataNode windowNode)
                    RenderWindow(windowNode.Data);
                else if (child is TilemapDataNode tilemapNode)
                    RenderTilemap(tilemapNode.Data);
            }
        }
    }

    public void RegisterViewport(ViewportData data)
    {
        if (this.viewports.ContainsKey(data))
            return;

        if (!this.initialized || this.renderRoot is null || !this.viewportNodeCreationReady)
        {
            if (!this.pendingViewports.Contains(data))
                this.pendingViewports.Add(data);

            return;
        }

        var renderSize = GetRenderSize();
        var subViewport = new SubViewport
        {
            Name = $"RmvaSubViewport_{this.viewports.Count}",
            Size = new Vector2I((int)renderSize.X, (int)renderSize.Y),
            TransparentBg = true,
            RenderTargetUpdateMode = SubViewport.UpdateMode.Always,
        };

        var subViewportRoot = new Node2D
        {
            Name = "RmvaSubViewportRoot",
        };
        subViewport.AddChild(subViewportRoot);
        this.renderRoot.AddChild(subViewport);

        var wrapper = new Sprite2D
        {
            Name = $"ViewportWrapper_{this.viewports.Count}",
            Texture = subViewport.GetTexture(),
            Centered = false,
            FlipV = false,
            Position = Vector2.Zero,
            ZAsRelative = false,
            ZIndex = data.Z,
        };
        this.renderRoot.AddChild(wrapper);

        this.viewports.Add(data, new ViewportRenderEntry(subViewport, subViewportRoot, wrapper));
    }

    public void UnregisterViewport(ViewportData data)
    {
        if (!this.viewports.Remove(data, out var entry))
            return;

        foreach (var sprite in new List<SpriteData>(this.sprites.Keys))
        {
            if (ReferenceEquals(sprite.Viewport, data))
                this.UnregisterSprite(sprite);
        }

        foreach (var window in new List<WindowData>(this.windows.Keys))
        {
            if (ReferenceEquals(window.Viewport, data))
                this.UnregisterWindow(window);
        }

        foreach (var window in new List<WindowData>(this.pendingWindows))
        {
            if (ReferenceEquals(window.Viewport, data))
                this.UnregisterWindow(window);
        }

        foreach (var plane in new List<PlaneData>(this.planes.Keys))
        {
            if (ReferenceEquals(plane.Viewport, data))
                this.UnregisterPlane(plane);
        }

        foreach (var plane in new List<PlaneData>(this.pendingPlanes))
        {
            if (ReferenceEquals(plane.Viewport, data))
                this.UnregisterPlane(plane);
        }

        foreach (var tilemap in new List<TilemapData>(this.tilemaps.Keys))
        {
            if (ReferenceEquals(tilemap.Viewport, data))
                this.UnregisterTilemap(tilemap);
        }

        foreach (var tilemap in new List<TilemapData>(this.pendingTilemaps))
        {
            if (ReferenceEquals(tilemap.Viewport, data))
                this.UnregisterTilemap(tilemap);
        }

        entry.Wrapper.QueueFree();
        entry.SubViewport.QueueFree();
    }

    public void RegisterTilemap(TilemapData data, ViewportData viewport)
    {
        if (data.Disposed)
            return;

        data.Viewport = viewport;

        if (!this.initialized || !this.viewports.TryGetValue(viewport, out var entry))
        {
            if (!this.pendingTilemaps.Contains(data))
                this.pendingTilemaps.Add(data);

            return;
        }

        if (this.tilemaps.TryGetValue(data, out var existing))
        {
            if (existing.GetParent() != entry.SubViewportRoot)
                existing.Reparent(entry.SubViewportRoot);

            return;
        }

        var node = new TilemapDataNode
        {
            Name = "RgssTilemap",
            Data = data,
            ZAsRelative = false,
        };

        entry.SubViewportRoot.AddChild(node);
        data.Node = node;
        this.tilemaps.Add(data, node);
    }

    public void UnregisterTilemap(TilemapData data)
    {
        this.pendingTilemaps.Remove(data);

        if (!this.tilemaps.Remove(data, out var node))
            return;

        data.Node = null;
        node.QueueFree();
    }

    public void RegisterSprite(SpriteData data, ViewportData viewport)
    {
        if (data.Disposed)
            return;

        data.Viewport = viewport;

        if (!this.initialized || !this.viewports.TryGetValue(viewport, out var entry))
        {
            if (!this.pendingSprites.Contains(data))
                this.pendingSprites.Add(data);

            return;
        }

        if (this.sprites.TryGetValue(data, out var existing))
        {
            if (existing.GetParent() != entry.SubViewportRoot)
                existing.Reparent(entry.SubViewportRoot);

            return;
        }

        var node = new SpriteDataNode
        {
            Name = "RgssSprite",
            Data = data,
            Centered = false,
            ZAsRelative = false,
            Material = this.spriteMaterial?.Duplicate() as Material,
        };

        entry.SubViewportRoot.AddChild(node);
        data.Node = node;
        this.sprites.Add(data, node);
    }

    public void UnregisterSprite(SpriteData data)
    {
        this.pendingSprites.Remove(data);

        if (!this.sprites.Remove(data, out var node))
            return;

        data.Node = null;
        node.QueueFree();
    }

    public void RegisterPlane(PlaneData data, ViewportData viewport)
    {
        if (data.Disposed)
            return;

        data.Viewport = viewport;

        if (!this.initialized || !this.viewports.TryGetValue(viewport, out var entry))
        {
            if (!this.pendingPlanes.Contains(data))
                this.pendingPlanes.Add(data);

            return;
        }

        if (this.planes.TryGetValue(data, out var existing))
        {
            if (existing.GetParent() != entry.SubViewportRoot)
                existing.Reparent(entry.SubViewportRoot);

            return;
        }

        var node = new PlaneDataNode
        {
            Name = "RgssPlane",
            Data = data,
        };

        entry.SubViewportRoot.AddChild(node);
        data.Node = node;
        this.planes.Add(data, node);
    }

    public void UnregisterPlane(PlaneData data)
    {
        this.pendingPlanes.Remove(data);

        if (!this.planes.Remove(data, out var node))
            return;

        data.Node = null;
        node.QueueFree();
    }

    public void RegisterWindow(WindowData data, ViewportData viewport)
    {
        if (data.Disposed)
            return;

        data.Viewport = viewport;

        if (!this.initialized || !this.viewports.TryGetValue(viewport, out var entry))
        {
            if (!this.pendingWindows.Contains(data))
                this.pendingWindows.Add(data);

            return;
        }

        if (this.windows.TryGetValue(data, out var existing))
        {
            if (existing.GetParent() != entry.SubViewportRoot)
                existing.Reparent(entry.SubViewportRoot);

            return;
        }

        var node = new WindowDataNode
        {
            Name = "RgssWindow",
            Data = data,
            ZAsRelative = false,
        };

        entry.SubViewportRoot.AddChild(node);
        data.Node = node;
        this.windows.Add(data, node);
    }

    public void UnregisterWindow(WindowData data)
    {
        this.pendingWindows.Remove(data);

        if (!this.windows.Remove(data, out var node))
            return;

        data.Node = null;
        node.QueueFree();
    }

    public SubViewport GetSubViewport(ViewportData data)
    {
        if (!this.viewports.TryGetValue(data, out var entry))
            throw new KeyNotFoundException("Viewport is not registered.");

        return entry.SubViewport;
    }

    public void Dispose()
    {
        foreach (var entry in this.viewports.Values)
        {
            entry.Wrapper.QueueFree();
            entry.SubViewport.QueueFree();
        }

        this.viewports.Clear();
        this.sprites.Clear();
        this.planes.Clear();
        this.windows.Clear();
        this.tilemaps.Clear();
        this.sortedViewports.Clear();
        this.pendingViewports.Clear();
        this.pendingSprites.Clear();
        this.pendingPlanes.Clear();
        this.pendingWindows.Clear();
        this.pendingTilemaps.Clear();

        this.postprocessQuad?.QueueFree();
        this.postprocessLayer?.QueueFree();
        this.backBufferCopy?.QueueFree();
        this.compositeLayer?.QueueFree();

        this.postprocessQuad = null;
        this.postprocessLayer = null;
        this.backBufferCopy = null;
        this.renderRoot = null;
        this.compositeLayer = null;
        this.parent = null;
        this.spriteMaterial = null;
        this.postprocessMaterial = null;
        this.initialized = false;
        this.viewportNodeCreationReady = false;
    }

    public static void ResetDirtyDataSet()
    {
        foreach (var data in DirtyBitmapDataSet)
            data.UpdateTexture();

        DirtyBitmapDataSet.Clear();
    }

    public static void RenderSprite(SpriteData data)
    {
        var node = data.Node;
        if (node is null || data.Disposed)
            return;

        if (data.Bitmap is { Dirty: true })
            data.Bitmap.UpdateTexture();

        node.Visible = data.Visible && data.Bitmap is { Disposed: false };
        node.Texture = data.Bitmap?.Texture;
        node.ZIndex = data.Z;
        node.Position = new Vector2(data.X - data.Ox, data.Y - data.Oy);
        node.Scale = new Vector2(data.ZoomX, data.ZoomY);
        node.RotationDegrees = data.Angle;
        node.FlipH = data.Mirror;

        if (data.Bitmap is not null && data.SrcRect is not null && data.SrcRect.Width > 0 && data.SrcRect.Height > 0)
        {
            node.RegionEnabled = true;
            node.RegionRect = new Rect2(data.SrcRect.X, data.SrcRect.Y, data.SrcRect.Width, data.SrcRect.Height);
        }
        else
            node.RegionEnabled = false;

        var width = data.SrcRect?.Width > 0 ? data.SrcRect.Width : data.Bitmap?.Width ?? 1;
        var height = data.SrcRect?.Height > 0 ? data.SrcRect.Height : data.Bitmap?.Height ?? 1;
        node.SetInstanceShaderParameter("_PackedA", new Vector4(data.WaveAmp, data.WaveLength, data.WaveSpeed, data.BushOpacity / 255.0f));
        node.SetInstanceShaderParameter("_PackedB", new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f));
        node.SetInstanceShaderParameter("_PackedC", BuildFlashVector(data));
        node.SetInstanceShaderParameter("_PackedD", new Vector4(data.Opacity / 255.0f, data.Mirror ? 1.0f : 0.0f, (data.Tone?.Gray ?? 0.0f) > 0.0f ? 1.0f : 0.0f, 0.0f));

        if (node.Material is ShaderMaterial material)
        {
            material.SetShaderParameter("mix_color", ToGodotColor(data.Color));
            material.SetShaderParameter("bush_depth", data.BushDepth / 255.0f);
            material.SetShaderParameter("texture_size", new Vector2(Math.Max(1, width), Math.Max(1, height)));
        }
    }

    public static void RenderPlane(PlaneData data)
    {
        var node = data.Node as PlaneDataNode;
        if (node is null || data.Disposed)
            return;

        if (data.Bitmap is { Dirty: true })
            data.Bitmap.UpdateTexture();

        var drawable = GetOrCreatePlaneDrawable(node, data.BlendType);
        var bitmap = data.Bitmap;
        var hasBitmap = bitmap is { Disposed: false, Texture: not null, Width: > 0, Height: > 0 };
        var viewportSize = GetNodeRenderSize(node);

        node.ZIndex = data.Z;
        node.Visible = data.Visible && hasBitmap;

        drawable.Visible = node.Visible;
        drawable.Texture = hasBitmap ? bitmap!.Texture : null;
        drawable.Size = viewportSize;
        drawable.ZIndex = data.Z;
        drawable.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.Opacity));

        if (!hasBitmap)
            return;

        if (drawable.Material is not ShaderMaterial material || material.ResourceName != GetPlaneMaterialName(data.BlendType))
        {
            material = CreatePlaneMaterial(data.BlendType);
            drawable.Material = material;
        }

        var zoomX = Math.Abs(data.ZoomX) > 0.0001f ? data.ZoomX : 1.0f;
        var zoomY = Math.Abs(data.ZoomY) > 0.0001f ? data.ZoomY : 1.0f;
        material.SetShaderParameter("mix_color", ToGodotColor(data.Color));
        material.SetShaderParameter("tone", new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f));
        material.SetShaderParameter("tile_scale", new Vector2(viewportSize.X / bitmap!.Width / zoomX, viewportSize.Y / bitmap.Height / zoomY));
        material.SetShaderParameter("uv_offset", new Vector2(data.Ox / Math.Max(1.0f, viewportSize.X), data.Oy / Math.Max(1.0f, viewportSize.Y)));
        material.SetShaderParameter("scroll_speed", Vector2.Zero);
    }

    public static void RenderWindow(WindowData data)
    {
        var node = data.Node as WindowDataNode;
        if (node is null || data.Disposed)
            return;

        if (data.Windowskin is { Dirty: true })
            data.Windowskin.UpdateTexture();

        if (data.Contents is { Dirty: true })
            data.Contents.UpdateTexture();

        var background = GetOrCreateWindowTextureRect(node, "WindowBackground", "res://Shaders/WindowBackgroundShader.gdshader");
        var tiledBackground = GetOrCreateWindowTextureRect(node, "WindowTiledBackground", "res://Shaders/TiledBackgroundShader.gdshader");
        var border = GetOrCreateWindowNinePatch(node, "WindowBorder", 16, false);
        var contents = GetOrCreateWindowContents(node);
        var cursor = GetOrCreateWindowNinePatch(node, "WindowCursor", 2, true);

        var openness = Math.Clamp(data.Openness / 255.0f, 0.0f, 1.0f);
        var width = Math.Max(0, data.Width);
        var height = Math.Max(0, data.Height);
        var backgroundWidth = Math.Max(0, width - 2);
        var backgroundHeight = Math.Max(0, height - 2) * openness;
        var borderHeight = height * openness;
        var windowOpacity = ToAlpha(data.Opacity);
        var hasWindowskin = data.Windowskin is { Disposed: false, Texture: not null };

        node.Visible = data.Visible && width > 0 && height > 0 && openness > 0.0f;
        node.ZIndex = data.Z;
        node.Position = new Vector2(data.X, data.Y + height * (1.0f - openness) / 2.0f);

        background.Visible = node.Visible && hasWindowskin;
        background.Texture = GetRegionTexture(data.Windowskin, new Rect2I(0, 0, 64, 64));
        background.Position = new Vector2(1.0f, 1.0f);
        background.Size = new Vector2(backgroundWidth, backgroundHeight);
        background.ZIndex = data.Z;
        background.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.BackOpacity) * windowOpacity);

        tiledBackground.Visible = node.Visible && hasWindowskin;
        tiledBackground.Texture = GetRegionTexture(data.Windowskin, new Rect2I(0, 64, 64, 64));
        tiledBackground.Position = background.Position;
        tiledBackground.Size = background.Size;
        tiledBackground.ZIndex = data.Z + 1;
        tiledBackground.Modulate = background.Modulate;

        border.Visible = node.Visible && hasWindowskin;
        border.Texture = GetRegionTexture(data.Windowskin, new Rect2I(64, 0, 64, 64));
        border.Position = new Vector2(0.0f, 0.0f);
        border.Size = new Vector2(width, borderHeight);
        border.ZIndex = data.Z + 2;
        border.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, windowOpacity);

        var tone = new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f);
        if (background.Material is ShaderMaterial backgroundMaterial)
            backgroundMaterial.SetShaderParameter("tone", tone);

        if (tiledBackground.Material is ShaderMaterial tiledMaterial)
        {
            tiledMaterial.SetShaderParameter("tone", tone);
            tiledMaterial.SetShaderParameter("tile_scale", new Vector2(backgroundWidth / 64.0f, Math.Max(0.0f, height - 2) / 64.0f));
            tiledMaterial.SetShaderParameter("uv_offset", new Vector2(2.0f / 64.0f, 2.0f / 64.0f));
            tiledMaterial.SetShaderParameter("scroll_speed", Vector2.Zero);
        }

        var contentWidth = Math.Max(0, width - data.Padding * 2);
        var contentHeight = Math.Max(0, height - data.Padding - data.PaddingBottom);
        var hasContents = data.Contents is { Disposed: false, Texture: not null, Width: > 0, Height: > 0 };
        contents.Visible = node.Visible && hasContents && data.Openness == 255;
        contents.Texture = hasContents ? data.Contents!.Texture : null;
        contents.Position = new Vector2(data.Padding - data.Ox, data.Padding - data.Oy);
        contents.ZIndex = data.Z + 3;
        contents.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.ContentsOpacity) * windowOpacity);

        if (contents.Material is ShaderMaterial contentsMaterial && hasContents)
        {
            contentsMaterial.SetShaderParameter(
                "region",
                new Vector4(
                    data.Ox / (float)Math.Max(1, data.Contents!.Width),
                    data.Oy / (float)Math.Max(1, data.Contents.Height),
                    Math.Clamp(contentWidth / (float)Math.Max(1, data.Contents.Width), 0.0f, 1.0f),
                    Math.Clamp(contentHeight / (float)Math.Max(1, data.Contents.Height), 0.0f, 1.0f)));
        }

        var cursorRect = data.CursorRect;
        var hasCursor = hasWindowskin && cursorRect is { Width: > 0, Height: > 0 } && data.Openness == 255;
        cursor.Visible = node.Visible && hasCursor;
        cursor.Texture = GetRegionTexture(data.Windowskin, new Rect2I(64, 64, 32, 32));
        cursor.Position = hasCursor ? new Vector2(cursorRect!.X + data.Padding, cursorRect.Y + data.Padding) : Vector2.Zero;
        cursor.Size = hasCursor ? new Vector2(cursorRect!.Width, cursorRect.Height) : Vector2.Zero;
        cursor.ZIndex = data.Z + 4;
        // Cursor blink: RGSS3 oscillates the cursor alpha on a 32-frame triangle wave
        // (255 down to 128 and back) while the window is active; a dimmed static
        // highlight when inactive. AnimationTick is advanced by Window#update per frame.
        var cursorAlpha = GetCursorBlinkAlpha(data.Active, data.AnimationTick);
        cursor.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, cursorAlpha * windowOpacity);

        RenderWindowPause(node, data, width, height, windowOpacity);
        RenderWindowArrows(node, data, width, height, contentWidth, contentHeight, windowOpacity);
    }

    // RGSS3 cursor blink: a 32-frame cycle where alpha ramps 255 -> 128 over the first
    // 16 frames and back to 255 over the next 16 (a symmetric triangle wave). When the
    // window is inactive the cursor is shown at a constant dim alpha.
    private static float GetCursorBlinkAlpha(bool active, int tick)
    {
        if (!active)
            return 128.0f / 255.0f;

        var phase = ((tick % 32) + 32) % 32;     // 0..31, guard against negatives
        var distance = Math.Abs(phase - 16);     // 16 at phase 0, 0 at phase 16
        var alpha = 128 + distance * 8;          // 128..256 -> clamp to 255
        return Math.Min(255, alpha) / 255.0f;
    }

    // Pause sign: 4 animation frames (16x16) in the windowskin's bottom strip, cycling
    // ~every 16 game frames. Drawn centred on the window's bottom edge when data.Pause.
    private static readonly Rect2I[] PauseFrameRects =
    {
        new(96, 64, 16, 16),
        new(112, 64, 16, 16),
        new(96, 80, 16, 16),
        new(112, 80, 16, 16),
    };

    private static void RenderWindowPause(WindowDataNode node, WindowData data, int width, int height, float windowOpacity)
    {
        var pause = GetOrCreateWindowSprite(node, "WindowPause");
        var hasWindowskin = data.Windowskin is { Disposed: false, Texture: not null };
        var show = node.Visible && data.Pause && hasWindowskin && data.Openness == 255;
        pause.Visible = show;
        if (!show)
            return;

        var frame = (data.AnimationTick / 16) % PauseFrameRects.Length;
        pause.Texture = GetRegionTexture(data.Windowskin, PauseFrameRects[frame]);
        // Centred horizontally, sitting on the bottom border (16px tall sign).
        pause.Position = new Vector2(width / 2.0f - 8.0f, height - 16.0f);
        pause.ZIndex = data.Z + 5;
        pause.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, windowOpacity);
    }

    // Scroll arrows live in the centre of the windowskin border region (64,0,64,64).
    // Each is shown only when the contents overflow in that direction and arrows_visible.
    private static readonly Rect2I ArrowUpRect = new(88, 16, 16, 8);
    private static readonly Rect2I ArrowDownRect = new(88, 40, 16, 8);
    private static readonly Rect2I ArrowLeftRect = new(80, 24, 8, 16);
    private static readonly Rect2I ArrowRightRect = new(104, 24, 8, 16);

    private static void RenderWindowArrows(
        WindowDataNode node, WindowData data, int width, int height, int contentWidth, int contentHeight, float windowOpacity)
    {
        var hasWindowskin = data.Windowskin is { Disposed: false, Texture: not null };
        var baseVisible = node.Visible && data.ArrowsVisible && hasWindowskin && data.Openness == 255;
        var contents = data.Contents;
        var contentsWidth = contents?.Width ?? 0;
        var contentsHeight = contents?.Height ?? 0;

        // Overflow = the contents bitmap is larger than the visible content area, and the
        // scroll origin (ox/oy) is not pinned to the corresponding edge.
        var canUp = baseVisible && data.Oy > 0;
        var canDown = baseVisible && contentsHeight - data.Oy > contentHeight;
        var canLeft = baseVisible && data.Ox > 0;
        var canRight = baseVisible && contentsWidth - data.Ox > contentWidth;

        UpdateArrow(node, "WindowArrowUp", data, ArrowUpRect, canUp,
            new Vector2(width / 2.0f - 8.0f, 2.0f), windowOpacity);
        UpdateArrow(node, "WindowArrowDown", data, ArrowDownRect, canDown,
            new Vector2(width / 2.0f - 8.0f, height - 10.0f), windowOpacity);
        UpdateArrow(node, "WindowArrowLeft", data, ArrowLeftRect, canLeft,
            new Vector2(2.0f, height / 2.0f - 8.0f), windowOpacity);
        UpdateArrow(node, "WindowArrowRight", data, ArrowRightRect, canRight,
            new Vector2(width - 10.0f, height / 2.0f - 8.0f), windowOpacity);
    }

    private static void UpdateArrow(
        WindowDataNode node, string name, WindowData data, Rect2I region, bool show, Vector2 position, float windowOpacity)
    {
        var arrow = GetOrCreateWindowSprite(node, name);
        arrow.Visible = show;
        if (!show)
            return;

        arrow.Texture = GetRegionTexture(data.Windowskin, region);
        arrow.Position = position;
        arrow.ZIndex = data.Z + 5;
        arrow.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, windowOpacity);
    }

    private static TextureRect GetOrCreatePlaneDrawable(PlaneDataNode node, int blendType)
    {
        var drawable = node.GetNodeOrNull<TextureRect>("PlaneDrawable");
        if (drawable is not null)
            return drawable;

        drawable = new TextureRect
        {
            Name = "PlaneDrawable",
            ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
            StretchMode = TextureRect.StretchModeEnum.Scale,
            ZAsRelative = false,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Enabled,
            Material = CreatePlaneMaterial(blendType),
        };
        // A TextureRect gives the bare PlaneDataNode a viewport-sized quad; PlaneShader handles RGSS tiling via UV fract().
        node.AddChild(drawable);
        return drawable;
    }

    private static TextureRect GetOrCreateWindowTextureRect(WindowDataNode node, string name, string shaderPath)
    {
        var textureRect = node.GetNodeOrNull<TextureRect>(name);
        if (textureRect is not null)
            return textureRect;

        textureRect = new TextureRect
        {
            Name = name,
            ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
            StretchMode = TextureRect.StretchModeEnum.Scale,
            ZAsRelative = false,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Enabled,
        };
        var shader = GD.Load<Shader>(shaderPath);
        if (shader is not null)
            textureRect.Material = new ShaderMaterial { Shader = shader };

        node.AddChild(textureRect);
        return textureRect;
    }

    private static NinePatchRect GetOrCreateWindowNinePatch(WindowDataNode node, string name, int margin, bool drawCenter)
    {
        var ninePatch = node.GetNodeOrNull<NinePatchRect>(name);
        if (ninePatch is not null)
            return ninePatch;

        ninePatch = new NinePatchRect
        {
            Name = name,
            ZAsRelative = false,
            DrawCenter = drawCenter,
            PatchMarginLeft = margin,
            PatchMarginTop = margin,
            PatchMarginRight = margin,
            PatchMarginBottom = margin,
        };
        node.AddChild(ninePatch);
        return ninePatch;
    }

    private static Sprite2D GetOrCreateWindowContents(WindowDataNode node)
    {
        var contents = node.GetNodeOrNull<Sprite2D>("WindowContents");
        if (contents is not null)
            return contents;

        contents = new Sprite2D
        {
            Name = "WindowContents",
            Centered = false,
            ZAsRelative = false,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Disabled,
        };
        var shader = GD.Load<Shader>("res://Shaders/SpriteMaskShader.gdshader");
        if (shader is not null)
            contents.Material = new ShaderMaterial { Shader = shader };

        node.AddChild(contents);
        return contents;
    }

    // Plain top-left-anchored Sprite2D used for the pause sign and scroll arrows
    // (small fixed-size windowskin sub-regions, no clipping shader needed).
    private static Sprite2D GetOrCreateWindowSprite(WindowDataNode node, string name)
    {
        var sprite = node.GetNodeOrNull<Sprite2D>(name);
        if (sprite is not null)
            return sprite;

        sprite = new Sprite2D
        {
            Name = name,
            Centered = false,
            ZAsRelative = false,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Disabled,
        };
        node.AddChild(sprite);
        return sprite;
    }

    // Godot's AtlasTexture does NOT clip correctly when fed to a NinePatchRect
    // (get_scaled_rid returns the FULL atlas, so nine-patch + custom shaders sample
    // the whole 128x128 windowskin and adjacent regions -- palette swatches, arrows,
    // cursor -- bleed into the window). Documented Godot limitation. The robust fix
    // is to extract each sub-region ONCE into its own standalone ImageTexture via
    // Image.GetRegion(): NinePatchRect then nine-slices the isolated sub-image, and a
    // canvas_item shader's TEXTURE/UV map exactly to it with zero bleed.
    private static readonly Dictionary<(ulong, int, int, int, int), ImageTexture> RegionTextureCache = new();

    private static Texture2D? GetRegionTexture(BitmapData? bitmap, Rect2I region)
    {
        if (bitmap is not { Disposed: false, Image: not null })
            return null;

        var key = (bitmap.Image.GetInstanceId(), region.Position.X, region.Position.Y, region.Size.X, region.Size.Y);
        if (RegionTextureCache.TryGetValue(key, out var cached) && cached is not null)
            return cached;

        var img = bitmap.Image;
        var clamped = region.Intersection(new Rect2I(0, 0, img.GetWidth(), img.GetHeight()));
        if (clamped.Size.X <= 0 || clamped.Size.Y <= 0)
            return null;

        var sub = img.GetRegion(clamped);
        if (sub.GetFormat() != Image.Format.Rgba8)
            sub.Convert(Image.Format.Rgba8);

        var tex = ImageTexture.CreateFromImage(sub);
        RegionTextureCache[key] = tex;
        return tex;
    }

    private static Vector2 GetNodeRenderSize(Node node)
    {
        if (node.GetViewport() is SubViewport subViewport && subViewport.Size.X > 0 && subViewport.Size.Y > 0)
            return new Vector2(subViewport.Size.X, subViewport.Size.Y);

        return GetRenderSize();
    }

    // One margin tile around the visible area so partial tiles at edges are drawn.
    private const int TilemapMargin = 1;

    // RGSS3 autotile animation: A-type ping-pongs 0,1,2,1; C-type (waterfall) cycles
    // 0,1,2; both advance one phase every 30 frames over a 360-frame loop.
    private static readonly int[] AnimIndicesA = { 0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 2, 1 };
    private static readonly int[] AnimIndicesC = { 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2 };

    public static void RenderTilemap(TilemapData data)
    {
        var node = data.Node as TilemapDataNode;
        if (node is null || data.Disposed)
            return;

        // Flush any dirty tileset bitmaps so their CPU Images are current before sampling.
        foreach (var bmp in data.Bitmaps)
        {
            if (bmp is { Dirty: true })
                bmp.UpdateTexture();
        }

        var ground = GetOrCreateTilemapLayer(node, "TilemapGround", 0);
        var over = GetOrCreateTilemapLayer(node, "TilemapOver", 200);

        node.ZIndex = 0;
        node.Visible = data.Visible;
        if (!data.Visible || data.MapData is null)
        {
            ground.Visible = false;
            over.Visible = false;
            return;
        }

        var viewportSize = GetNodeRenderSize(node);
        var tilesW = (int)Math.Ceiling(viewportSize.X / TilemapRenderer.TileSize) + TilemapMargin * 2;
        var tilesH = (int)Math.Ceiling(viewportSize.Y / TilemapRenderer.TileSize) + TilemapMargin * 2;

        // Chunk origin: the top-left tile baked into the layer images.
        var originTileX = (int)Math.Floor(data.Ox / TilemapRenderer.TileSize) - TilemapMargin;
        var originTileY = (int)Math.Floor(data.Oy / TilemapRenderer.TileSize) - TilemapMargin;

        var animA = AnimIndicesA[(data.AnimationTick / 30) % AnimIndicesA.Length];
        var animC = AnimIndicesC[(data.AnimationTick / 30) % AnimIndicesC.Length];
        var mapId = (ulong)data.MapData.GetHashCode();

        // Recomposite only when the visible chunk, map, flags, or animation phase changes.
        var needComposite = data.LayersDirty
            || data.CachedOriginTileX != originTileX
            || data.CachedOriginTileY != originTileY
            || data.CachedAnimFrameA != animA
            || data.CachedAnimFrameC != animC
            || data.CachedMapDataId != mapId;

        if (needComposite)
        {
            CompositeTilemap(data, ground, over, originTileX, originTileY, tilesW, tilesH, animA, animC);
            data.CachedOriginTileX = originTileX;
            data.CachedOriginTileY = originTileY;
            data.CachedAnimFrameA = animA;
            data.CachedAnimFrameC = animC;
            data.CachedMapDataId = mapId;
            data.LayersDirty = false;
        }

        // Sub-tile scroll: position the baked chunk so it tracks ox/oy smoothly.
        var posX = originTileX * TilemapRenderer.TileSize - data.Ox;
        var posY = originTileY * TilemapRenderer.TileSize - data.Oy;
        ground.Position = new Vector2(posX, posY);
        over.Position = new Vector2(posX, posY);
        ground.Visible = true;
        over.Visible = true;
    }

    private static void CompositeTilemap(
        TilemapData data, Sprite2D ground, Sprite2D over,
        int originTileX, int originTileY, int tilesW, int tilesH, int animA, int animC)
    {
        var map = data.MapData!;
        var pixelW = tilesW * TilemapRenderer.TileSize;
        var pixelH = tilesH * TilemapRenderer.TileSize;

        var groundImg = Image.CreateEmpty(pixelW, pixelH, false, Image.Format.Rgba8);
        var overImg = Image.CreateEmpty(pixelW, pixelH, false, Image.Format.Rgba8);
        groundImg.Fill(Colors.Transparent);
        overImg.Fill(Colors.Transparent);

        var mapW = map.XSize;
        var mapH = map.YSize;
        var hasShadowLayer = map.ZSize >= 4;

        for (var ty = 0; ty < tilesH; ty++)
        {
            var my = originTileY + ty;
            for (var tx = 0; tx < tilesW; tx++)
            {
                var mx = originTileX + tx;

                var px = tx * TilemapRenderer.TileSize;
                var py = ty * TilemapRenderer.TileSize;

                // Wrap coordinates so loop maps show the opposite edge in the margin.
                // For non-loop maps the camera clamps, so wrapped tiles stay off-screen
                // (matches mkxp-z tableGetWrapped behaviour).
                var wx = Wrap(mx, mapW);
                var wy = Wrap(my, mapH);
                if (wx < 0 || wy < 0)
                    continue;

                // RGSS3 layer order: z=0, z=1, shadow (z=3), z=2 (so the top tile layer
                // draws over shadows). Shadows go onto the ground image, below characters.
                DrawMapTile(data, groundImg, overImg, map, wx, wy, 0, px, py, animA, animC);
                DrawMapTile(data, groundImg, overImg, map, wx, wy, 1, px, py, animA, animC);
                if (hasShadowLayer)
                {
                    var shadow = GetMapTile(map, wx, wy, 3) & 0xF;
                    if (shadow != 0)
                        TilemapRenderer.DrawShadow(groundImg, px, py, shadow);
                }
                DrawMapTile(data, groundImg, overImg, map, wx, wy, 2, px, py, animA, animC);
            }
        }

        ApplyLayerImage(ground, groundImg);
        ApplyLayerImage(over, overImg);
    }

    // Positive modulo wrap for loop-map tile reads. Returns -1 for a non-positive size.
    private static int Wrap(int v, int size)
    {
        if (size <= 0)
            return -1;
        var m = v % size;
        return m < 0 ? m + size : m;
    }

    // Draws one map cell's tile at layer z onto the correct (ground/over) image,
    // honouring the over-player (0x10) and table (0x80) flags.
    private static void DrawMapTile(
        TilemapData data, Image groundImg, Image overImg, TableData map,
        int wx, int wy, int z, int px, int py, int animA, int animC)
    {
        var tileId = GetMapTile(map, wx, wy, z);
        if (tileId <= 0)
            return;

        var flag = GetTileFlag(data.Flags, tileId);
        var target = (flag & TilemapRenderer.OverPlayerFlag) != 0 ? overImg : groundImg;
        var isTable = (flag & TilemapRenderer.TableFlag) != 0;
        TilemapRenderer.DrawTile(target, px, py, tileId, data.Bitmaps, animA, animC, isTable);
    }

    private static int GetMapTile(TableData map, int x, int y, int z)
    {
        var index = x + y * map.XSize + z * map.XSize * map.YSize;
        if (index < 0 || index >= map.Data.Length)
            return 0;
        return map.Data[index];
    }

    private static int GetTileFlag(TableData? flags, int tileId)
    {
        if (flags is null || tileId < 0 || tileId >= flags.Data.Length)
            return 0;
        return flags.Data[tileId];
    }

    private static void ApplyLayerImage(Sprite2D sprite, Image img)
    {
        if (sprite.Texture is ImageTexture tex
            && tex.GetWidth() == img.GetWidth() && tex.GetHeight() == img.GetHeight())
        {
            tex.Update(img);
        }
        else
        {
            sprite.Texture = ImageTexture.CreateFromImage(img);
        }
    }

    private static Sprite2D GetOrCreateTilemapLayer(TilemapDataNode node, string name, int zIndex)
    {
        var layer = node.GetNodeOrNull<Sprite2D>(name);
        if (layer is not null)
            return layer;

        layer = new Sprite2D
        {
            Name = name,
            Centered = false,
            ZAsRelative = false,
            ZIndex = zIndex,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Disabled,
            TextureFilter = CanvasItem.TextureFilterEnum.Nearest,
        };
        node.AddChild(layer);
        return layer;
    }

    private static float ToAlpha(int opacity)
        => Math.Clamp(opacity / 255.0f, 0.0f, 1.0f);

    private static ShaderMaterial CreatePlaneMaterial(int blendType)
    {
        var shader = blendType switch
        {
            1 => CreatePlaneShaderVariant("blend_add"),
            2 => CreatePlaneShaderVariant("blend_sub"),
            _ => GD.Load<Shader>("res://Shaders/PlaneShader.gdshader"),
        };

        return new ShaderMaterial
        {
            Shader = shader,
            ResourceName = GetPlaneMaterialName(blendType),
        };
    }

    private static string GetPlaneMaterialName(int blendType)
        => blendType switch
        {
            1 => "RgssPlaneBlendAdd",
            2 => "RgssPlaneBlendSub",
            _ => "RgssPlaneBlendMix",
        };

    private static Shader CreatePlaneShaderVariant(string blendMode)
    {
        return new Shader
        {
            Code = $$"""
shader_type canvas_item;
render_mode {{blendMode}}, unshaded;

uniform vec4 mix_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 tile_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 scroll_speed = vec2(0.0, 0.0);

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
    vec2 uv = UV * tile_scale;
    uv.y -= tile_scale.y - 1.0;
    uv += vec2(uv_offset.x, -uv_offset.y) + (scroll_speed * TIME);
    uv = fract(uv);

    vec4 col = texture(TEXTURE, uv);

    float luma = dot(col.rgb, LUMA);
    col.rgb = mix(col.rgb, vec3(luma), tone.a);
    col.rgb += tone.rgb;
    col.rgb = mix(col.rgb, mix_color.rgb, mix_color.a);

    COLOR = col;
}
""",
        };
    }

    private static Vector2 GetRenderSize()
    {
        if (GlobalConfig.Instance.LegacyMode)
            return new Vector2(GlobalConfig.Instance.LegacyModeWidth, GlobalConfig.Instance.LegacyModeHeight);

        var root = Engine.GetMainLoop() is SceneTree tree ? tree.Root : null;
        if (root is not null)
            return root.GetVisibleRect().Size;

        return DisplayServer.WindowGetSize();
    }

    public void SetGraphicsBrightness(float brightness)
    {
        this.postprocessMaterial?.SetShaderParameter("brightness", Math.Clamp(brightness, 0.0f, 1.0f));
    }

    private static Vector4 BuildFlashVector(SpriteData data)
    {
        if (data.FlashColor is null || data.FlashDuration <= 0 || data.FlashRemain <= 0)
            return new Vector4(1.0f, 1.0f, 1.0f, 0.0f);

        var progress = Math.Clamp((float)data.FlashRemain / data.FlashDuration, 0.0f, 1.0f);
        return new Vector4(data.FlashColor.R, data.FlashColor.G, data.FlashColor.B, data.FlashColor.A * progress);
    }

    private static Godot.Color ToGodotColor(ColorData? color)
    {
        if (color is null)
            return Colors.Transparent;

        return new Godot.Color(NormalizeColorChannel(color.R), NormalizeColorChannel(color.G), NormalizeColorChannel(color.B), NormalizeColorChannel(color.A));
    }

    private static float NormalizeColorChannel(float value)
        => Math.Clamp(value > 1.0f ? value / 255.0f : value, 0.0f, 1.0f);

    private sealed record ViewportRenderEntry(SubViewport SubViewport, Node2D SubViewportRoot, Sprite2D Wrapper);
}

public partial class SpriteDataNode : Sprite2D
{
    public SpriteData Data { get; set; } = null!;
}

public partial class PlaneDataNode : Node2D
{
    public PlaneData Data { get; set; } = null!;
}

public partial class WindowDataNode : Node2D
{
    public WindowData Data { get; set; } = null!;
}

public partial class TilemapDataNode : Node2D
{
    public TilemapData Data { get; set; } = null!;
}
