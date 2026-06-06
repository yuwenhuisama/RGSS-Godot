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
            ZAsRelative = false,
            ZIndex = data.Z,
            FlipV = true,
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
        node.Position = new Vector2(data.X - data.Ox, -data.Y + data.Oy);
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
    }

    public static void RenderWindow(WindowData data)
    {
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
