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
    private float graphicsBrightness = 1.0f;
    private bool brightnessFadeActive;
    private float fadeStartBrightness = 1.0f;
    private float fadeTargetBrightness = 1.0f;
    private int fadeTotalFrames;
    private int fadeFramesElapsed;

    // Masked screen transition (Graphics.freeze + Graphics.transition with a mask image).
    private ShaderMaterial? transitionMaterial;
    private Texture2D? frozenTexture;
    private Texture2D? maskTexture;
    private bool transitionActive;
    private int transitionTotalFrames;
    private int transitionFramesElapsed;
    private float transitionVague;
    // Graphics.freeze right after a transition would otherwise capture the last dissolve
    // frame; defer that capture one frame so it grabs the live (post-transition) screen.
    private bool transitionFinishedThisFrame;
    private bool captureFrozenOnNextUpdate;

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
            YSortEnabled = false,
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
        using var postprocessShader = GD.Load<Shader>("res://Shaders/GraphicsPostprocessShader.gdshader");
        if (postprocessShader is not null)
        {
            this.postprocessMaterial = new ShaderMaterial { Shader = postprocessShader };
            this.postprocessMaterial.SetShaderParameter("brightness", 1.0f);
            this.postprocessQuad.Material = this.postprocessMaterial;
        }

        this.postprocessQuad.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        this.postprocessLayer.AddChild(this.postprocessQuad);

        using var transitionShader = GD.Load<Shader>("res://Shaders/TransitionPostprocessShader.gdshader");
        if (transitionShader is not null)
            this.transitionMaterial = new ShaderMaterial { Shader = transitionShader };

        using var spriteShader = GD.Load<Shader>("res://Shaders/SpriteShader.gdshader");
        if (spriteShader is not null)
            this.spriteMaterial = new ShaderMaterial { Shader = spriteShader };

        this.initialized = true;
    }

    public void Update()
    {
        // A deferred freeze (requested right after a transition finished) captures the
        // now-rendered live frame.
        if (this.captureFrozenOnNextUpdate)
        {
            this.CaptureFrozenTextureNow();
            this.captureFrozenOnNextUpdate = false;
        }

        // The "just finished" flag only suppresses a same-turn synchronous freeze; one
        // engine frame has now elapsed, so clear it.
        this.transitionFinishedThisFrame = false;

        this.TickBrightnessFade();
        this.TickTransition();
        this.SyncRenderState();
    }

    public void SyncRenderState()
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

            if (viewportData.IsDefault)
            {
                foreach (var child in this.renderRoot.GetChildren())
                {
                    if (child is SpriteDataNode defaultSprite) RenderSprite(defaultSprite.Data);
                    else if (child is PlaneDataNode defaultPlane) RenderPlane(defaultPlane.Data);
                    else if (child is WindowDataNode defaultWindow) RenderWindow(defaultWindow.Data);
                    else if (child is TilemapDataNode defaultTilemap) RenderTilemap(defaultTilemap.Data);
                }
                entry.Wrapper.Visible = false;
                continue;
            }

            // Viewport is a clipped segment of the screen draw list. Its objects blend
            // against the preceding screen before the full rectangle's effects run.
            var rectWidth = Math.Max(1, viewportData.Width);
            var rectHeight = Math.Max(1, viewportData.Height);
            entry.Clip.Position = new Vector2(viewportData.X, viewportData.Y);
            entry.Clip.Size = new Vector2(rectWidth, rectHeight);
            entry.Wrapper.Size = entry.Clip.Size;
            entry.SubViewportRoot.Position = new Vector2(-viewportData.Ox, -viewportData.Oy);
            entry.Clip.Visible = viewportData.Visible && viewportData.Width > 0 && viewportData.Height > 0
                && !(viewportData.FlashRemain > 0 && viewportData.FlashColor is null);
            entry.Wrapper.Visible = true;
            if (entry.Wrapper.Material is ShaderMaterial viewportMaterial)
            {
                viewportMaterial.SetShaderParameter("tone", new Vector4(viewportData.Tone?.Red ?? 0, viewportData.Tone?.Green ?? 0, viewportData.Tone?.Blue ?? 0, viewportData.Tone?.Gray ?? 0));
                viewportMaterial.SetShaderParameter("mix_color", ToGodotColor(viewportData.Color));
                viewportMaterial.SetShaderParameter("flash_color", ToGodotColor(viewportData.FlashColor));
                viewportMaterial.SetShaderParameter("flash_progress", viewportData.FlashRemain > 0 ? (float)viewportData.FlashRemain / viewportData.FlashDuration : 0.0f);
            }

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
        this.OrderScreenDrawables();
    }

    private void OrderScreenDrawables()
    {
        var segments = new List<(int Z, float Y, ulong Sequence, List<CanvasItem> Items)>();
        foreach (var pair in this.viewports)
        {
            var items = new List<CanvasItem>();
            foreach (var child in pair.Value.SubViewportRoot.GetChildren())
            {
                if (child is SpriteDataNode sprite) items.Add(sprite);
                else if (child is PlaneDataNode or WindowDataNode or TilemapDataNode)
                {
                    foreach (var drawable in child.GetChildren())
                        if (drawable is CanvasItem item) items.Add(item);
                    ((CanvasItem)child).ZIndex = 0;
                }
            }
            items.Sort(static (a, b) =>
            {
                var z = a.ZIndex.CompareTo(b.ZIndex);
                if (z != 0) return z;
                var y = (a is SpriteDataNode sa ? sa.Data.Y : 0).CompareTo(b is SpriteDataNode sb ? sb.Data.Y : 0);
                var sequenceA = a is SpriteDataNode spriteA ? spriteA.Data.CreationSequence : a.GetParent() is TilemapDataNode tileA ? tileA.Data.CreationSequence : a.GetInstanceId();
                var sequenceB = b is SpriteDataNode spriteB ? spriteB.Data.CreationSequence : b.GetParent() is TilemapDataNode tileB ? tileB.Data.CreationSequence : b.GetInstanceId();
                return y != 0 ? y : sequenceA.CompareTo(sequenceB);
            });
            if (pair.Key.IsDefault)
            {
                foreach (var item in items)
                    segments.Add((item.ZIndex, item is SpriteDataNode sprite ? sprite.Data.Y : 0, item is SpriteDataNode orderedSprite ? orderedSprite.Data.CreationSequence : item.GetParent() is TilemapDataNode tile ? tile.Data.CreationSequence : item.GetInstanceId(), new List<CanvasItem> { item }));
            }
            else
            {
                items.Add(pair.Value.Wrapper);
                segments.Add((pair.Key.Z, 0, pair.Key.CreationSequence, items));
            }
        }
        segments.Sort(static (a, b) =>
        {
            var z = a.Z.CompareTo(b.Z);
            if (z != 0) return z;
            var y = a.Y.CompareTo(b.Y);
            return y != 0 ? y : a.Sequence.CompareTo(b.Sequence);
        });
        var slot = -4096;
        foreach (var segment in segments)
            foreach (var item in segment.Items)
                item.ZIndex = slot++;
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

        var initialWidth = Math.Max(1, data.Width);
        var initialHeight = Math.Max(1, data.Height);
        var subViewportRoot = new Node2D
        {
            Name = "RmvaViewportContents",
        };

        var clip = new Control
        {
            Name = $"ViewportClip_{this.viewports.Count}",
            ClipContents = true,
            MouseFilter = Control.MouseFilterEnum.Ignore,
            Position = new Vector2(data.X, data.Y),
            Size = new Vector2(initialWidth, initialHeight),
        };
        this.renderRoot.AddChild(clip);
        clip.AddChild(subViewportRoot);

        using var viewportShader = GD.Load<Shader>("res://Shaders/ViewportShader.gdshader");
        var wrapper = new ColorRect
        {
            Name = $"ViewportWrapper_{this.viewports.Count}",
            Color = Colors.White,
            Size = clip.Size,
            MouseFilter = Control.MouseFilterEnum.Ignore,
            ZAsRelative = false,
            ZIndex = data.Z,
            Material = new ShaderMaterial { Shader = viewportShader },
        };
        clip.AddChild(wrapper);
        wrapper.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });

        this.viewports.Add(data, new ViewportRenderEntry(data.IsDefault ? this.renderRoot : subViewportRoot, wrapper, clip));
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

        var viewportMaterial = entry.Wrapper.Material;
        entry.Wrapper.Material = null;
        viewportMaterial?.Dispose();
        entry.Clip.QueueFree();
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
            TextureFilter = CanvasItem.TextureFilterEnum.Nearest,
            ZAsRelative = false,
            Material = this.spriteMaterial?.Duplicate() as Material,
        };

        entry.SubViewportRoot.AddChild(node);
        node.BackgroundCopy = new BackBufferCopy
        {
            CopyMode = BackBufferCopy.CopyModeEnum.Viewport,
            ShowBehindParent = true,
        };
        node.AddChild(node.BackgroundCopy);
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

    public void Dispose()
    {
        foreach (var cached in RegionTextureCache.Values)
            cached.Texture.Dispose();
        RegionTextureCache.Clear();
        DirtyBitmapDataSet.Clear();
        foreach (var entry in this.viewports.Values)
        {
            var viewportMaterial = entry.Wrapper.Material;
            entry.Wrapper.Material = null;
            viewportMaterial?.Dispose();
            entry.Clip.QueueFree();
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
        this.spriteMaterial?.Dispose();
        this.spriteMaterial = null;
        this.postprocessMaterial?.Dispose();
        this.postprocessMaterial = null;

        this.transitionActive = false;
        this.captureFrozenOnNextUpdate = false;
        this.transitionFinishedThisFrame = false;
        ReleaseTexture(ref this.maskTexture);
        ReleaseTexture(ref this.frozenTexture);
        this.transitionMaterial?.Dispose();
        this.transitionMaterial = null;

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

        if (node is SpriteDataNode blendNode)
        {
            blendNode.SetBlendType(data.BlendType);
            blendNode.BackgroundCopy.Visible = data.BlendType == 2 || (data.BlendType == 0
                && (data.Opacity < 255 || data.BushDepth > 0 || data.Bitmap?.Image.DetectAlpha() != Image.AlphaMode.None));
        }

        node.Visible = data.Visible && data.Bitmap is { Disposed: false } && data.ZoomX > 0 && data.ZoomY > 0
            && data.SrcRect is { Width: > 0, Height: > 0 }
            && !(data.FlashRemain > 0 && data.FlashColor is null);
        node.Texture = data.Bitmap?.Texture;
        node.ZIndex = data.Z;
        node.Position = new Vector2(data.X, data.Y);
        node.Offset = new Vector2(-data.Ox, -data.Oy);
        node.Scale = new Vector2(data.ZoomX, data.ZoomY);
        node.RotationDegrees = -data.Angle;
        node.FlipH = data.Mirror;

        if (data.Bitmap is not null && data.SrcRect is not null && data.SrcRect.Width > 0 && data.SrcRect.Height > 0)
        {
            node.RegionEnabled = true;
            node.RegionRect = new Rect2(data.SrcRect.X, data.SrcRect.Y, data.SrcRect.Width, data.SrcRect.Height);
        }
        else
            node.RegionEnabled = false;

        if (node.Visible && (data.Angle != 0 || data.ZoomX != MathF.Truncate(data.ZoomX) || data.ZoomY != MathF.Truncate(data.ZoomY)) && node is SpriteDataNode spriteNode)
            spriteNode.RenderRotation();
        if (node.Visible && data.WaveAmp != 0 && node is SpriteDataNode waveNode)
            waveNode.RenderWave();

        var width = data.SrcRect?.Width > 0 ? data.SrcRect.Width : data.Bitmap?.Width ?? 1;
        var height = data.SrcRect?.Height > 0 ? data.SrcRect.Height : data.Bitmap?.Height ?? 1;
        node.SetInstanceShaderParameter("_PackedA", new Vector4(0, data.WaveLength, data.WavePhase, data.BushOpacity / 255.0f));
        node.SetInstanceShaderParameter("_PackedB", new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f));
        node.SetInstanceShaderParameter("_PackedC", BuildFlashVector(data));
        node.SetInstanceShaderParameter("_PackedD", new Vector4(data.Opacity / 255.0f, 0.0f, (data.Tone?.Gray ?? 0.0f) > 0.0f ? 1.0f : 0.0f, 0.0f));

        if (node.Material is ShaderMaterial material)
        {
            material.SetShaderParameter("mix_color", ToGodotColor(data.Color));
            var textureHeight = Math.Max(1, node.Texture?.GetHeight() ?? height);
            var regionBottom = node.RegionEnabled ? node.RegionRect.End.Y : textureHeight;
            material.SetShaderParameter("bush_depth", regionBottom / textureHeight - data.BushDepth / Math.Max(1.0f, textureHeight * node.Scale.Y));
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
        node.Visible = data.Visible && hasBitmap && Math.Floor(bitmap!.Width * data.ZoomX) > 0 && Math.Floor(bitmap.Height * data.ZoomY) > 0;

        drawable.Visible = node.Visible;
        drawable.Texture = hasBitmap ? bitmap!.Texture : null;
        drawable.Size = viewportSize;
        drawable.Position = new Vector2(data.Viewport?.Ox ?? 0, data.Viewport?.Oy ?? 0);
        drawable.ZIndex = data.Z;
        drawable.Modulate = Colors.White;

        if (!node.Visible)
            return;

        if (drawable.Material is not ShaderMaterial material || material.ResourceName != GetPlaneMaterialName(data.BlendType))
        {
            material = CreatePlaneMaterial(data.BlendType);
            drawable.Material = material;
        }

        var zoomX = data.ZoomX;
        var zoomY = data.ZoomY;
        material.SetShaderParameter("mix_color", ToGodotColor(data.Color));
        material.SetShaderParameter("tone", new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f));
        material.SetShaderParameter("tile_scale", new Vector2(viewportSize.X / bitmap!.Width / zoomX, viewportSize.Y / bitmap.Height / zoomY));
        material.SetShaderParameter("viewport_size", viewportSize);
        material.SetShaderParameter("bitmap_size", new Vector2(bitmap.Width, bitmap.Height));
        material.SetShaderParameter("zoom", new Vector2(zoomX, zoomY));
        material.SetShaderParameter("scroll", new Vector2(data.Ox + (data.Viewport?.Ox ?? 0), data.Oy + (data.Viewport?.Oy ?? 0)));
        material.SetShaderParameter("scroll_speed", Vector2.Zero);
        material.SetShaderParameter("opacity", ToAlpha(data.Opacity));
        material.SetShaderParameter("blend_type", data.BlendType);
        material.SetShaderParameter("uv_offset", new Vector2((data.Ox + (data.Viewport?.Ox ?? 0)) / (bitmap.Width * zoomX), (data.Oy + (data.Viewport?.Oy ?? 0)) / (bitmap.Height * zoomY)));
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
        var border = GetOrCreateWindowNinePatch(node, "WindowBorder", 16, false);
        var contents = GetOrCreateWindowContents(node);
        var cursor = GetOrCreateWindowNinePatch(node, "WindowCursor", 4, true);
        cursor.TextureFilter = CanvasItem.TextureFilterEnum.Nearest;

        var openness = Math.Clamp(data.Openness / 255.0f, 0.0f, 1.0f);
        var width = Math.Max(0, data.Width);
        var height = Math.Max(0, data.Height);
        var backgroundWidth = Math.Max(0, width - 2);
        var backgroundHeight = Math.Max(0, height - 2) * openness;
        var borderHeight = (int)(height * openness);
        var windowOpacity = ToAlpha(data.Opacity);
        var hasWindowskin = data.Windowskin is { Disposed: false, Texture: not null };

        node.Visible = data.Visible && width > 0 && height > 0 && openness > 0.0f;
        node.ZIndex = data.Z;
        node.Position = new Vector2(data.X, data.Y + (height - borderHeight) / 2);

        background.Visible = node.Visible && hasWindowskin;
        background.Texture = GetRegionTexture(data.Windowskin, new Rect2I(0, 0, 64, 64));
        background.Position = new Vector2(1.0f, 1.0f);
        background.Size = new Vector2(backgroundWidth, backgroundHeight);
        background.ZIndex = data.Z;
        background.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.BackOpacity) * windowOpacity);


        border.Visible = node.Visible && hasWindowskin;
        border.Texture = GetRegionTexture(data.Windowskin, new Rect2I(64, 0, 64, 64));
        border.Position = new Vector2(0.0f, 0.0f);
        border.Size = new Vector2(width, height);
        border.Scale = new Vector2(1.0f, height > 0 ? borderHeight / (float)height : 0.0f);
        if (border.Material is not ShaderMaterial borderMaterial)
        {
            using var borderShader = GD.Load<Shader>("res://Shaders/WindowBorderShader.gdshader");
            borderMaterial = new ShaderMaterial { Shader = borderShader };
            border.Material = borderMaterial;
            border.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
        }
        borderMaterial.SetShaderParameter("window_size", new Vector2(width, height));
        border.ZIndex = data.Z + 2;
        border.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, windowOpacity);

        var tone = new Vector4(data.Tone?.Red ?? 0.0f, data.Tone?.Green ?? 0.0f, data.Tone?.Blue ?? 0.0f, data.Tone?.Gray ?? 0.0f);
        if (background.Material is ShaderMaterial backgroundMaterial)
        {
            backgroundMaterial.SetShaderParameter("tone", tone);
            using var tiledTextureParameter = Variant.From(GetRegionTexture(data.Windowskin, new Rect2I(0, 64, 64, 64)));
            backgroundMaterial.SetShaderParameter("tiled_texture", tiledTextureParameter);
            backgroundMaterial.SetShaderParameter("background_size", background.Size);
        }


        var contentWidth = Math.Max(0, width - data.Padding * 2);
        var contentHeight = Math.Max(0, height - data.Padding - data.PaddingBottom);
        var hasContents = data.Contents is { Disposed: false, Texture: not null, Width: > 0, Height: > 0 };
        contents.Visible = node.Visible && hasContents && data.Openness == 255;
        contents.Texture = hasContents ? data.Contents!.Texture : null;
        contents.Position = new Vector2(data.Padding - data.Ox, data.Padding - data.Oy);
        contents.ZIndex = data.Z + 5;
        // Contents (text/icons) alpha is driven SOLELY by contents_opacity, never by the
        // window's `opacity`. In RGSS3 (and mkxp/mkxp-z) `opacity` only fades the windowskin
        // background+frame (the `base` quad); the contents quad is a separate object whose
        // vertex alpha is contents_opacity alone. This is what makes Window_BattleLog work:
        // it sets `self.opacity = 0` (using a separate back-sprite for its dark band) while
        // keeping contents_opacity = 255 so the battle-log TEXT stays fully visible.
        contents.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, ToAlpha(data.ContentsOpacity));

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
        cursor.ZIndex = data.Z + 3;
        // Cursor brightness follows the measured 40-frame cycle; contents opacity
        // subtracts its lost brightness rather than multiplying the blink alpha.
        var cursorAlpha = Math.Max(0.0f, GetCursorBlinkAlpha(data.Active, data.CursorTick) - (255 - data.ContentsOpacity) / 255.0f);
        cursor.Visible = cursor.Visible && cursorAlpha > 0.0f;
        if (cursor.Material is not ShaderMaterial)
        {
            using var cursorShader = GD.Load<Shader>("res://Shaders/WindowCursorShader.gdshader");
            cursor.Material = new ShaderMaterial { Shader = cursorShader };
            cursor.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
        }
        cursor.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, cursorAlpha);
        ((ShaderMaterial)cursor.Material).SetShaderParameter("cursor_size", hasCursor ? new Vector2(cursorRect!.Width, cursorRect.Height) : Vector2.One);

        RenderWindowPause(node, data, width, height, windowOpacity);
        RenderWindowArrows(node, data, width, height, contentWidth, contentHeight, windowOpacity);
    }

    // RGSS3 cursor blink: a 32-frame cycle where alpha ramps 255 -> 128 over the first
    // 16 frames and back to 255 over the next 16 (a symmetric triangle wave). When the
    // window is inactive the cursor is shown at a constant dim alpha.
    private static float GetCursorBlinkAlpha(bool active, int tick)
    {
        if (!active)
            return 127.0f / 255.0f;

        var phase = tick % 40;
        var alpha = 255 - Math.Min(phase, 40 - phase) * 8;
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
        if (pause.Material is not ShaderMaterial)
        {
            using var pauseShader = GD.Load<Shader>("res://Shaders/WindowPauseShader.gdshader");
            pause.Material = new ShaderMaterial { Shader = pauseShader };
            pause.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
        }
        // Centred horizontally, sitting on the bottom border (16px tall sign).
        pause.Position = new Vector2(width / 2.0f - 8.0f, height - 16.0f);
        pause.ZIndex = data.Z + 4;
        pause.Modulate = new Godot.Color(1.0f, 1.0f, 1.0f, windowOpacity * Math.Min(data.PauseFadeTick / 8.0f, 1.0f));
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
        arrow.Modulate = Colors.White;
    }

    private static TextureRect GetOrCreatePlaneDrawable(PlaneDataNode node, int blendType)
    {
        var drawable = node.GetNodeOrNull<TextureRect>("PlaneDrawable");
        if (drawable is not null)
            return drawable;

        drawable = new TextureRect
        {
            Name = "PlaneDrawable",
            TextureFilter = CanvasItem.TextureFilterEnum.Nearest,
            ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
            StretchMode = TextureRect.StretchModeEnum.Scale,
            ZAsRelative = false,
            TextureRepeat = CanvasItem.TextureRepeatEnum.Enabled,
            Material = CreatePlaneMaterial(blendType),
        };
        // A TextureRect gives the bare PlaneDataNode a viewport-sized quad; PlaneShader handles RGSS tiling via UV fract().
        node.AddChild(drawable);
        drawable.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
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
        using var shader = GD.Load<Shader>(shaderPath);
        if (shader is not null)
            textureRect.Material = new ShaderMaterial { Shader = shader };

        node.AddChild(textureRect);
        if (name == "WindowBackground")
            textureRect.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
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
        using var shader = GD.Load<Shader>("res://Shaders/SpriteMaskShader.gdshader");
        if (shader is not null)
            contents.Material = new ShaderMaterial { Shader = shader };

        node.AddChild(contents);
        contents.AddChild(new BackBufferCopy { CopyMode = BackBufferCopy.CopyModeEnum.Viewport, ShowBehindParent = true });
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
    private static readonly Dictionary<(ulong, int, int, int, int), (long Revision, ImageTexture Texture)> RegionTextureCache = new();

    private static Texture2D? GetRegionTexture(BitmapData? bitmap, Rect2I region)
    {
        if (bitmap is not { Disposed: false, Image: not null })
            return null;

        var key = (bitmap.Image.GetInstanceId(), region.Position.X, region.Position.Y, region.Size.X, region.Size.Y);
        if (RegionTextureCache.TryGetValue(key, out var cached) && cached.Revision == bitmap.TextureRevision)
            return cached.Texture;

        var img = bitmap.Image;
        var clamped = region.Intersection(new Rect2I(0, 0, img.GetWidth(), img.GetHeight()));
        if (clamped.Size.X <= 0 || clamped.Size.Y <= 0)
            return null;

        using var sub = img.GetRegion(clamped);
        if (sub.GetFormat() != Image.Format.Rgba8)
            sub.Convert(Image.Format.Rgba8);

        var tex = cached.Texture;
        if (tex is null)
            tex = ImageTexture.CreateFromImage(sub);
        else
            tex.Update(sub);
        RegionTextureCache[key] = (bitmap.TextureRevision, tex);
        return tex;
    }

    private static Vector2 GetNodeRenderSize(Node node)
    {
        var viewport = node switch
        {
            PlaneDataNode plane => plane.Data.Viewport,
            TilemapDataNode tilemap => tilemap.Data.Viewport,
            _ => null,
        };
        if (viewport is { IsDefault: false })
            return new Vector2(Math.Max(1, viewport.Width), Math.Max(1, viewport.Height));
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

        // Flash blink phase only matters (and only forces recompositing) when flash data
        // is present, so ordinary maps never recomposite just for the flash counter.
        var flashIdx = ((data.FlashTick % TilemapRenderer.FlashCycle) + TilemapRenderer.FlashCycle) % TilemapRenderer.FlashCycle;
        var flashAlpha = data.FlashData is not null ? TilemapRenderer.FlashAlpha[flashIdx] : -1;

        // Recomposite only when the visible chunk, map, flags, or animation phase changes.
        var needComposite = data.LayersDirty
            || data.CachedOriginTileX != originTileX
            || data.CachedOriginTileY != originTileY
            || data.CachedAnimFrameA != animA
            || data.CachedAnimFrameC != animC
            || data.CachedFlashAlpha != flashAlpha
            || data.CachedMapRevision != data.MapData.Revision
            || data.CachedFlagsRevision != (data.Flags?.Revision ?? 0)
            || data.CachedFlashRevision != (data.FlashData?.Revision ?? 0)
            || data.CachedMapDataId != mapId;

        if (needComposite)
        {
            CompositeTilemap(data, ground, over, originTileX, originTileY, tilesW, tilesH, animA, animC, flashIdx);
            data.CachedOriginTileX = originTileX;
            data.CachedOriginTileY = originTileY;
            data.CachedAnimFrameA = animA;
            data.CachedAnimFrameC = animC;
            data.CachedFlashAlpha = flashAlpha;
            data.CachedMapDataId = mapId;
            data.CachedMapRevision = data.MapData.Revision;
            data.CachedFlagsRevision = data.Flags?.Revision ?? 0;
            data.CachedFlashRevision = data.FlashData?.Revision ?? 0;
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
        int originTileX, int originTileY, int tilesW, int tilesH, int animA, int animC, int flashAlphaIdx)
    {
        var map = data.MapData!;
        var pixelW = tilesW * TilemapRenderer.TileSize;
        var pixelH = tilesH * TilemapRenderer.TileSize;

        using var groundImg = Image.CreateEmpty(pixelW, pixelH, false, Image.Format.Rgba8);
        using var overImg = Image.CreateEmpty(pixelW, pixelH, false, Image.Format.Rgba8);
        groundImg.Fill(Colors.Transparent);
        overImg.Fill(Colors.Transparent);

        var mapW = map.XSize;
        var mapH = map.YSize;
        var hasShadowLayer = map.ZSize >= 4;
        var flash = data.FlashData;

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

                // Flash overlay (SRPG move-range pulse), additively blended over the tile.
                if (flash is not null)
                {
                    var packed = GetFlashColor(flash, wx, wy);
                    if (packed != 0)
                        TilemapRenderer.DrawFlash(groundImg, px, py, packed, flashAlphaIdx);
                }
            }
        }

        ApplyLayerImage(ground, groundImg);
        ApplyLayerImage(over, overImg);
    }

    private static int GetFlashColor(TableData flash, int x, int y)
    {
        if (flash.XSize <= 0 || flash.YSize <= 0)
            return 0;
        var index = x + y * flash.XSize;   // flash_data is a 2D width x height Table
        if (index < 0 || index >= flash.Data.Length)
            return 0;
        return flash.Data[index] & 0xFFFF;
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
        var target = z == 2 && (flag & TilemapRenderer.OverPlayerFlag) != 0 ? overImg : groundImg;
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
            var previous = sprite.Texture;
            sprite.Texture = ImageTexture.CreateFromImage(img);
            previous?.Dispose();
        }
    }

    private static Sprite2D GetOrCreateTilemapLayer(TilemapDataNode node, string name, int zIndex)
    {
        var layer = node.GetNodeOrNull<Sprite2D>(name);
        if (layer is not null)
        {
            layer.ZIndex = zIndex;
            return layer;
        }

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
        using var shader = blendType switch
        {
            1 => CreatePlaneShaderVariant("blend_add"),
            2 => CreatePlaneShaderVariant("blend_mix"),
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
            Code = GD.Load<Shader>("res://Shaders/PlaneShader.gdshader").Code.Replace("blend_mix", blendMode),
        };
    }

    private static Vector2 GetRenderSize()
        => RubyClasses.Graphics.GetRenderSize();

    public float GetGraphicsBrightness() => this.graphicsBrightness;

    // Immediate, cancels any active fade. Used by Graphics.brightness=.
    public void SetGraphicsBrightnessImmediate(float brightness)
    {
        this.brightnessFadeActive = false;
        this.graphicsBrightness = Math.Clamp(brightness, 0.0f, 1.0f);
        this.ApplyGraphicsBrightness(this.graphicsBrightness);
    }

    // Begin a linear brightness ramp from the current value to `target` over `durationFrames`
    // engine frames, driven by Update(). durationFrames<=0 applies immediately.
    public void StartBrightnessFade(float target, int durationFrames)
    {
        target = Math.Clamp(target, 0.0f, 1.0f);

        if (durationFrames <= 0)
        {
            this.SetGraphicsBrightnessImmediate(target);
            return;
        }

        this.fadeStartBrightness = this.graphicsBrightness;
        this.fadeTargetBrightness = target;
        this.fadeTotalFrames = durationFrames;
        this.fadeFramesElapsed = 0;
        this.brightnessFadeActive = true;

        // The first Graphics.update yields after this call, so its frame must
        // already carry the first fade step. The last yielded frame reaches target.
        this.TickBrightnessFade();
    }

    private void ApplyGraphicsBrightness(float brightness)
    {
        this.postprocessMaterial?.SetShaderParameter("brightness", Math.Clamp(brightness, 0.0f, 1.0f));
    }

    // Advances the brightness ramp by one frame. Increment-first so that on frame
    // `fadeTotalFrames` the value reaches EXACTLY the target. Called once per engine
    // frame from Update(), independent of the Ruby fiber: the fade keeps animating
    // while Ruby is parked in Graphics.wait/fadeout's `n.times { update }` loop.
    private void TickBrightnessFade()
    {
        if (!this.brightnessFadeActive)
            return;

        this.fadeFramesElapsed++;
        float t = (float)this.fadeFramesElapsed / this.fadeTotalFrames;

        if (t >= 1.0f)
        {
            this.graphicsBrightness = this.fadeTargetBrightness;
            this.brightnessFadeActive = false;
        }
        else
        {
            this.graphicsBrightness = Mathf.Lerp(this.fadeStartBrightness, this.fadeTargetBrightness, t);
        }

        this.ApplyGraphicsBrightness(this.graphicsBrightness);
    }

    // ── Masked screen transition (Graphics.freeze + Graphics.transition) ─────────────

    // Capture the current rendered screen into frozenTexture for use as the transition's
    // "old" frame. Deferred by one frame if requested right after a transition finished
    // (so battle, not the last dissolve frame, is captured).
    public void FreezeScreen()
    {
        if (!this.initialized)
            return;

        if (this.transitionFinishedThisFrame)
        {
            this.captureFrozenOnNextUpdate = true;
            return;
        }

        this.CaptureFrozenTextureNow();
    }

    private void CaptureFrozenTextureNow()
    {
        var viewport = this.parent?.GetViewport();
        if (viewport is null)
            return;

        using var image = viewport.GetTexture()?.GetImage();
        if (image is null || image.IsEmpty())
            return;

        if (image.GetFormat() != Image.Format.Rgba8)
            image.Convert(Image.Format.Rgba8);

        ReleaseTexture(ref this.frozenTexture);
        this.frozenTexture = ImageTexture.CreateFromImage(image);
    }

    // Reveal the current scene from the frozen frame. A null mask is a uniform
    // crossfade; a mask controls the spatial reveal. Ownership transfers here.
    public void StartTransition(Texture2D? maskTexture, int vague, int durationFrames)
    {
        this.brightnessFadeActive = false;
        this.graphicsBrightness = 1.0f;
        this.ApplyGraphicsBrightness(1.0f);

        if (this.transitionActive)
            this.FinishTransition(markFinished: false);

        // Capture the OLD scene now if Graphics.freeze didn't already (defensive).
        if (this.frozenTexture is null)
            this.CaptureFrozenTextureNow();

        // Fall back to an instant finish if we can't run a real dissolve.
        if (durationFrames <= 0 || this.postprocessQuad is null || this.transitionMaterial is null || this.frozenTexture is null)
        {
            maskTexture?.Dispose();
            ReleaseTexture(ref this.frozenTexture);
            if (this.postprocessQuad is not null && this.postprocessMaterial is not null)
                this.postprocessQuad.Material = this.postprocessMaterial;
            this.transitionFinishedThisFrame = true;
            return;
        }

        ReleaseTexture(ref this.maskTexture);
        this.maskTexture = maskTexture;

        this.transitionTotalFrames = Math.Max(1, durationFrames);
        this.transitionFramesElapsed = 0;
        this.transitionVague = Math.Max(vague / 256.0f, 0.0001f);
        this.transitionActive = true;

        using var frozenTextureParameter = Variant.From(this.frozenTexture);
        using var maskTextureParameter = Variant.From(this.maskTexture);
        this.transitionMaterial.SetShaderParameter("frozen_tex", frozenTextureParameter);
        this.transitionMaterial.SetShaderParameter("transition_tex", maskTextureParameter);
        this.transitionMaterial.SetShaderParameter("has_mask", maskTexture is not null);
        this.transitionMaterial.SetShaderParameter("vague", this.transitionVague);
        this.transitionMaterial.SetShaderParameter("progress", 0.0f);
        this.postprocessQuad.Material = this.transitionMaterial;
        this.TickTransition();
    }

    private void TickTransition()
    {
        if (!this.transitionActive)
            return;

        this.transitionFramesElapsed++;
        if (this.transitionFramesElapsed >= this.transitionTotalFrames)
        {
            this.FinishTransition(markFinished: true);
            return;
        }

        float progress = (float)this.transitionFramesElapsed / this.transitionTotalFrames;
        this.transitionMaterial?.SetShaderParameter("progress", progress);
    }

    private void FinishTransition(bool markFinished)
    {
        this.transitionActive = false;
        this.transitionFramesElapsed = 0;
        this.transitionTotalFrames = 0;

        this.graphicsBrightness = 1.0f;
        this.brightnessFadeActive = false;
        this.ApplyGraphicsBrightness(1.0f);

        if (this.postprocessQuad is not null && this.postprocessMaterial is not null)
            this.postprocessQuad.Material = this.postprocessMaterial;

        ReleaseTexture(ref this.maskTexture);
        ReleaseTexture(ref this.frozenTexture);

        if (markFinished)
            this.transitionFinishedThisFrame = true;
    }

    private static void ReleaseTexture(ref Texture2D? texture)
    {
        texture?.Dispose();
        texture = null;
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

    private sealed record ViewportRenderEntry(Node2D SubViewportRoot, ColorRect Wrapper, Control Clip);
}

public partial class SpriteDataNode : Sprite2D
{
    public SpriteData Data { get; set; } = null!;
    public BackBufferCopy BackgroundCopy { get; set; } = null!;
    public int RotationPadding { get; set; }
    private SpriteRotationRaster? rotation;
    private SpriteWaveRaster? wave;
    private int blendType;

    public void SetBlendType(int value)
    {
        if (this.blendType == value)
            return;
        var mode = value == 1 ? "blend_add" : "blend_mix";
        var code = GD.Load<Shader>("res://Shaders/SpriteShader.gdshader").Code.Replace("blend_mix", mode);
        if (value == 1)
            code = code.Replace("if (compose_background && col.a > 0.0 && col.a < 1.0)", "if (false)");
        if (value == 2)
            code = code.Replace("if (compose_background && col.a > 0.0 && col.a < 1.0)", "if (false)")
                .Replace("COLOR = col;", "COLOR = vec4(max(texture(background_texture, SCREEN_UV).rgb - col.rgb * col.a, vec3(0.0)), 1.0);");
        var shader = new Shader { Code = code };
        this.Material?.Dispose();
        this.Material = new ShaderMaterial { Shader = shader };
        this.blendType = value;
    }

    public void RenderRotation()
    {
        this.rotation ??= new SpriteRotationRaster();
        this.rotation.Apply(this, this.Data);
    }

    public void RenderWave()
    {
        this.wave ??= new SpriteWaveRaster();
        this.wave.Apply(this, this.Data);
    }

    public override void _ExitTree()
    {
        var material = this.Material;
        this.Material = null;
        material?.Dispose();
        this.rotation?.Dispose();
        this.rotation = null;
        this.wave?.Dispose();
        this.wave = null;
    }
}

public partial class PlaneDataNode : Node2D
{
    public PlaneData Data { get; set; } = null!;

    public override void _ExitTree()
    {
        foreach (var child in GetChildren())
        {
            if (child is CanvasItem item)
            {
                var material = item.Material;
                item.Material = null;
                material?.Dispose();
            }
        }
    }
}

public partial class WindowDataNode : Node2D
{
    public WindowData Data { get; set; } = null!;

    public override void _ExitTree()
    {
        foreach (var child in GetChildren())
        {
            if (child is CanvasItem item)
            {
                var material = item.Material;
                item.Material = null;
                material?.Dispose();
            }
        }
    }
}

public partial class TilemapDataNode : Node2D
{
    public TilemapData Data { get; set; } = null!;

    public override void _ExitTree()
    {
        foreach (var child in GetChildren())
        {
            if (child is Sprite2D sprite)
            {
                var texture = sprite.Texture;
                sprite.Texture = null;
                texture?.Dispose();
            }
        }
    }
}
