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
    private readonly List<ViewportData> sortedViewports = new();
    private readonly List<ViewportData> pendingViewports = new();
    private readonly List<SpriteData> pendingSprites = new();
    private readonly List<PlaneData> pendingPlanes = new();
    private readonly List<WindowData> pendingWindows = new();

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

        entry.Wrapper.QueueFree();
        entry.SubViewport.QueueFree();
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
        this.sortedViewports.Clear();
        this.pendingViewports.Clear();
        this.pendingSprites.Clear();
        this.pendingPlanes.Clear();
        this.pendingWindows.Clear();

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
        background.Texture = GetAtlasTexture(background.Texture, data.Windowskin, new Rect2(0, 0, 64, 64));
        background.Position = new Vector2(1.0f, 1.0f);
        background.Size = new Vector2(backgroundWidth, backgroundHeight);
        background.ZIndex = data.Z;
        background.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.BackOpacity) * windowOpacity);

        tiledBackground.Visible = node.Visible && hasWindowskin;
        tiledBackground.Texture = GetAtlasTexture(tiledBackground.Texture, data.Windowskin, new Rect2(0, 64, 64, 64));
        tiledBackground.Position = background.Position;
        tiledBackground.Size = background.Size;
        tiledBackground.ZIndex = data.Z + 1;
        tiledBackground.Modulate = background.Modulate;

        border.Visible = node.Visible && hasWindowskin;
        border.Texture = GetAtlasTexture(border.Texture, data.Windowskin, new Rect2(64, 0, 64, 64));
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
        cursor.Texture = GetAtlasTexture(cursor.Texture, data.Windowskin, new Rect2(64, 64, 32, 32));
        cursor.Position = hasCursor ? new Vector2(cursorRect!.X + data.Padding, cursorRect.Y + data.Padding) : Vector2.Zero;
        cursor.Size = hasCursor ? new Vector2(cursorRect!.Width, cursorRect.Height) : Vector2.Zero;
        cursor.ZIndex = data.Z + 4;
        // RGSS animates this alpha over time; use a stable active highlight until a frame counter is ported.
        cursor.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, (data.Active ? 0.5f : 0.25f) * windowOpacity);
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

    private static Texture2D? GetAtlasTexture(Texture2D? currentTexture, BitmapData? bitmap, Rect2 region)
    {
        if (bitmap is not { Disposed: false, Texture: not null })
            return null;

        if (currentTexture is AtlasTexture atlasTexture && ReferenceEquals(atlasTexture.Atlas, bitmap.Texture) && atlasTexture.Region == region)
            return atlasTexture;

        return new AtlasTexture
        {
            Atlas = bitmap.Texture,
            Region = region,
        };
    }

    private static Vector2 GetNodeRenderSize(Node node)
    {
        if (node.GetViewport() is SubViewport subViewport && subViewport.Size.X > 0 && subViewport.Size.Y > 0)
            return new Vector2(subViewport.Size.X, subViewport.Size.Y);

        return GetRenderSize();
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
