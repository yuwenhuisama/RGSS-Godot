using System;
using System.IO;
using Godot;
using MeltySynth;

namespace RGSSUnity;

internal partial class SoftwareMidiOutput : Node
{
    private const int SampleRate = 44100;
    private const int BlockFrames = 512;
    private readonly object synthLock = new();
    private readonly float[] left = new float[BlockFrames];
    private readonly float[] right = new float[BlockFrames];
    private readonly Vector2[] frames = new Vector2[BlockFrames];
    private Synthesizer synth = null!;
    private AudioStreamPlayer player = null!;
    private AudioStreamGenerator generator = null!;
    private AudioStreamGeneratorPlayback? output;
    private bool resetPending;
    private bool playing;

    internal void Initialize()
    {
        var root = ProjectSettings.GlobalizePath("res://");
        var font = Path.Combine(root, "Plugins", "midi", "TimGM6mb.sf2");
        if (!File.Exists(font))
            font = Path.Combine(AppContext.BaseDirectory, "Plugins", "midi", "TimGM6mb.sf2");
        synth = new Synthesizer(font, SampleRate);
        generator = new AudioStreamGenerator { MixRate = SampleRate, BufferLength = 0.1f };
        player = new AudioStreamPlayer { Name = "SoftwareMidi", Stream = generator };
        AddChild(player);
    }

    public override void _Process(double delta)
    {
        lock (synthLock)
        {
            if (resetPending)
            {
                player.Stop();
                output?.Dispose();
                output = null;
                if (playing)
                {
                    player.Play();
                    output = (AudioStreamGeneratorPlayback)player.GetStreamPlayback();
                }
                resetPending = false;
            }
        }
        if (player.StreamPaused || output is null) return;
        while (output.CanPushBuffer(BlockFrames))
        {
            lock (synthLock) synth.Render(left, right);
            for (var i = 0; i < BlockFrames; i++) frames[i] = new Vector2(left[i], right[i]);
            output.PushBuffer(frames);
        }
    }

    internal void Send(uint message)
    {
        lock (synthLock)
            synth.ProcessMidiMessage((int)(message & 15), (int)(message & 0xf0),
                (int)((message >> 8) & 127), (int)((message >> 16) & 127));
    }

    internal void Reset()
    {
        lock (synthLock)
        {
            synth.Reset();
            resetPending = true;
        }
    }

    internal void Start()
    {
        lock (synthLock)
        {
            playing = true;
            resetPending = true;
        }
    }

    internal void Stop()
    {
        lock (synthLock)
        {
            synth.Reset();
            playing = false;
            resetPending = true;
        }
    }

    internal void SetPaused(bool value) => player.StreamPaused = value;

    internal void Close()
    {
        SetProcess(false);
        player.Stop();
        player.Stream = null;
        output?.Dispose();
        player.Free();
        generator.Dispose();
        QueueFree();
    }
}
