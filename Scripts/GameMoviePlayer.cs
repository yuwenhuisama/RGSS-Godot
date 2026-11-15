using System;
using Godot;

namespace RGSSUnity;

public partial class GameMoviePlayer : CanvasLayer
{
    public static GameMoviePlayer? Current { get; private set; }
    private VideoStreamPlayer? player;

    public static void Start(string filename)
    {
        if (Current is not null)
            throw new InvalidOperationException("A movie is already playing.");
        var path = RMProjectPath.Resolve(filename);
        if (!System.IO.Path.HasExtension(path)) path += ".ogv";
        if (!System.IO.File.Exists(path))
            throw new System.IO.FileNotFoundException("Movie file does not exist.", path);
        if (Engine.GetMainLoop() is not SceneTree tree)
            throw new InvalidOperationException("Movie playback requires a scene tree.");
        var movie = new GameMoviePlayer { Layer = 900 };
        Current = movie;
        tree.Root.AddChild(movie);
        var background = new ColorRect { Color = Colors.Black };
        background.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        movie.AddChild(background);
        movie.player = new VideoStreamPlayer
        {
            Stream = new VideoStreamTheora { File = path },
            Expand = true,
            Bus = AudioServer.GetBusIndex("RGSSMusic") >= 0 ? "RGSSMusic" : "Master",
        };
        movie.player.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        movie.AddChild(movie.player);
        movie.player.Finished += movie.Finish;
        movie.player.Play();
        if (!movie.player.IsPlaying())
        {
            movie.Finish();
            throw new InvalidOperationException("Cannot start movie playback.");
        }
        movie.GetViewport().SizeChanged += movie.LayoutVideo;
        movie.LayoutVideo();
    }

    private void LayoutVideo()
    {
        if (this.player is null) return;
        var texture = this.player.GetVideoTexture();
        if (texture is null || texture.GetWidth() <= 0 || texture.GetHeight() <= 0) return;
        var viewportSize = GetViewport().GetVisibleRect().Size;
        var videoSize = texture.GetSize();
        this.player.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.TopLeft);
        this.player.Size = videoSize;
        this.player.Position = (viewportSize - videoSize) / 2.0f;
    }

    public override void _Process(double delta) => LayoutVideo();

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey { Pressed: true, Echo: false, Keycode: Key.Escape })
        {
            Finish();
            GetViewport().SetInputAsHandled();
        }
    }

    private void Finish()
    {
        this.player?.Stop();
        Current = null;
        QueueFree();
    }

    public static void Stop() => Current?.Finish();

    public override void _ExitTree()
    {
        if (Current == this) Current = null;
    }
}
