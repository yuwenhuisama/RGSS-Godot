using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;

namespace RGSSUnity;

internal static class GameMidiPlayer
{
    [DllImport("winmm.dll")] private static extern uint midiOutOpen(out IntPtr handle, uint id, IntPtr callback, IntPtr instance, uint flags);
    [DllImport("winmm.dll")] private static extern uint midiOutClose(IntPtr handle);
    [DllImport("winmm.dll")] private static extern uint midiOutReset(IntPtr handle);
    [DllImport("winmm.dll")] private static extern uint midiOutShortMsg(IntPtr handle, uint message);

    private sealed record MidiEvent(long Tick, int Order, uint Message, int Tempo, byte[]? SysEx = null);
    [StructLayout(LayoutKind.Sequential)]
    private struct MidiHeader
    {
        public IntPtr Data;
        public uint Length;
        public uint Recorded;
        public UIntPtr User;
        public uint Flags;
        public IntPtr Next;
        public UIntPtr Reserved;
        public uint Offset;
        public UIntPtr R0, R1, R2, R3, R4, R5, R6, R7;
    }
    [DllImport("winmm.dll")] private static extern uint midiOutPrepareHeader(IntPtr handle, ref MidiHeader header, uint size);
    [DllImport("winmm.dll")] private static extern uint midiOutLongMsg(IntPtr handle, ref MidiHeader header, uint size);
    [DllImport("winmm.dll")] private static extern uint midiOutUnprepareHeader(IntPtr handle, ref MidiHeader header, uint size);
    private static IntPtr device;
    private static SoftwareMidiOutput? software;
    private static CancellationTokenSource? cancellation;
    private static Task? playback;
    private static readonly Stopwatch clock = new();
    private static double positionOffset;
    private static float volume = 1;
    private static double fadeStart;
    private static double fadeDuration;
    private static float fadeVolume;
    private static bool muted;
    private static volatile bool paused;
    private static readonly object playbackLock = new();
    private static readonly int[] channelVolumes = new int[16];

    internal static bool Playing => cancellation is { IsCancellationRequested: false };
    internal static bool IsMidi(string path)
        => Path.GetExtension(path).Equals(".mid", StringComparison.OrdinalIgnoreCase)
        || Path.GetExtension(path).Equals(".midi", StringComparison.OrdinalIgnoreCase);

    internal static void Initialize()
    {
        if (!OperatingSystem.IsWindows())
        {
            if (software is not null) return;
            var output = new SoftwareMidiOutput();
            try
            {
                ((Godot.SceneTree)Godot.Engine.GetMainLoop()).Root.AddChild(output);
                output.Initialize();
            }
            catch
            {
                output.Free();
                throw;
            }
            software = output;
            return;
        }
        if (device != IntPtr.Zero) return;
        Check(midiOutOpen(out device, uint.MaxValue, IntPtr.Zero, IntPtr.Zero, 0));
    }

    private static void Check(uint result)
    {
        if (result != 0) throw new InvalidOperationException($"MIDI Mapper error: {result}.");
    }

    internal static void Play(string filename, float requestedVolume, float pitch, float position)
    {
        Stop();
        Initialize();
        var path = RMProjectPath.Resolve(filename);
        if (!File.Exists(path))
        {
            var relative = Path.IsPathRooted(filename) ? Path.GetRelativePath(RMProjectPath.Resolve("."), filename) : filename;
            path = Path.Combine(GlobalConfig.Instance.RtpPath, relative);
        }
        var (events, division) = ReadEvents(File.ReadAllBytes(path));
        var timed = new List<(double Time, uint Message, byte[]? SysEx)>();
        var tempo = 500000;
        long lastTick = 0;
        double time = 0;
        foreach (var item in events)
        {
            if ((division & 0x8000) == 0)
                time += (item.Tick - lastTick) * tempo / (double)division / 1000000;
            else
            {
                var frames = -(sbyte)(division >> 8);
                var frameRate = frames == 29 ? 29.97 : frames;
                time += (item.Tick - lastTick) / (frameRate * (division & 255));
            }
            lastTick = item.Tick;
            if (item.Tempo != 0) tempo = item.Tempo;
            else timed.Add((time, item.Message, item.SysEx));
        }
        Array.Fill(channelVolumes, 100);
        SetVolume(requestedVolume);
        software?.Start();
        var semitones = (int)Math.Round(12 * Math.Log2(Math.Max(0.01f, pitch)));
        positionOffset = Math.Max(0, position);
        clock.Restart();
        cancellation = new CancellationTokenSource();
        var token = cancellation.Token;
        playback = Task.Run(async () =>
        {
            while (!token.IsCancellationRequested)
            {
                foreach (var item in timed)
                {
                    token.ThrowIfCancellationRequested();
                    var status = (int)(item.Message & 0xff);
                    if (item.Time < positionOffset && (status & 0xf0) is 0x80 or 0x90) continue;
                    var remaining = item.Time - positionOffset - clock.Elapsed.TotalSeconds;
                    while (remaining > 0 || paused)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(paused ? 0.01 : Math.Min(0.01, remaining)), token);
                        if (!paused) UpdateFade();
                        remaining = item.Time - positionOffset - clock.Elapsed.TotalSeconds;
                    }
                    lock (playbackLock)
                    {
                    var message = item.Message;
                    if (item.SysEx is not null)
                    {
                        SendSysEx(item.SysEx);
                        continue;
                    }
                    if ((status & 0xf0) == 0xb0 && ((message >> 8) & 0x7f) == 7)
                    {
                        channelVolumes[status & 15] = (int)((message >> 16) & 127);
                        message = (message & 0xff00ffff) | ((uint)Math.Round(channelVolumes[status & 15] * (muted || paused ? 0 : volume)) << 16);
                    }
                    if ((status & 15) != 9 && (status & 0xf0) is 0x80 or 0x90 or 0xa0)
                    {
                        var note = Math.Clamp((int)((message >> 8) & 0x7f) + semitones, 0, 127);
                        message = (message & 0xffff00ff) | ((uint)note << 8);
                    }
                    SendMessage(message);
                    }
                }
                if (timed.Count == 0)
                    await Task.Delay(10, token);
                positionOffset = 0;
                lock (playbackLock)
                {
                    clock.Restart();
                    if (paused) clock.Stop();
                }
            }
        }, token);
    }

    internal static float Position()
    {
        if (playback is { IsFaulted: true }) playback.GetAwaiter().GetResult();
        return Playing ? (float)(positionOffset + clock.Elapsed.TotalSeconds) : 0;
    }

    private static void SendSysEx(byte[] bytes)
    {
        if (software is not null)
        {
            // Universal GM reset, used by standard MIDI files before channel data.
            if (bytes.Length == 6 && bytes[0] == 0xf0 && bytes[1] == 0x7e
                && bytes[3] == 9 && bytes[4] is 1 or 2 && bytes[5] == 0xf7)
                software.Reset();
            else throw new NotSupportedException("Software MIDI supports GM reset SysEx only.");
            return;
        }
        var pin = GCHandle.Alloc(bytes, GCHandleType.Pinned);
        var header = new MidiHeader { Data = pin.AddrOfPinnedObject(), Length = (uint)bytes.Length };
        var size = (uint)Marshal.SizeOf<MidiHeader>();
        try
        {
            Check(midiOutPrepareHeader(device, ref header, size));
            Check(midiOutLongMsg(device, ref header, size));
            uint result;
            while ((result = midiOutUnprepareHeader(device, ref header, size)) == 65)
                Thread.Yield();
            Check(result);
        }
        finally { pin.Free(); }
    }

    internal static void SetVolume(float requested)
    {
        lock (playbackLock)
        {
        volume = Math.Clamp(requested, 0, 1);
        if (device == IntPtr.Zero && software is null) return;
        for (var channel = 0; channel < 16; channel++)
            SendMessage((uint)(0xb0 | channel | (7 << 8) | ((int)Math.Round(channelVolumes[channel] * (muted || paused ? 0 : volume)) << 16)));
        }
    }

    internal static void SetPaused(bool value)
    {
        lock (playbackLock)
        {
            if (!Playing || paused == value) return;
            paused = value;
            if (value) clock.Stop();
            else clock.Start();
            software?.SetPaused(value);
            SetVolume(volume);
        }
    }

    internal static void SetMuted(bool value)
    {
        muted = value;
        SetVolume(volume);
    }

    internal static void Fade(long milliseconds)
    {
        fadeStart = clock.Elapsed.TotalSeconds;
        fadeDuration = Math.Max(0, milliseconds) / 1000.0;
        fadeVolume = volume;
        if (fadeDuration == 0) Stop();
    }

    private static void UpdateFade()
    {
        if (fadeDuration <= 0) return;
        var elapsed = clock.Elapsed.TotalSeconds - fadeStart;
        SetVolume(fadeVolume * (float)Math.Max(0, 1 - elapsed / fadeDuration));
        if (elapsed >= fadeDuration)
        {
            fadeDuration = 0;
            cancellation?.Cancel();
            if (software is not null) software.Stop();
            else ResetDevice();
        }
    }

    internal static void Stop()
    {
        if (cancellation is not null)
        {
            cancellation.Cancel();
            try { playback?.GetAwaiter().GetResult(); }
            catch (OperationCanceledException) { }
            cancellation.Dispose();
            cancellation = null;
            playback = null;
        }
        clock.Reset();
        paused = false;
        fadeDuration = 0;
        software?.SetPaused(false);
        if (software is not null) software.Stop();
        else ResetDevice();
    }

    internal static void Close()
    {
        Stop();
        software?.Close();
        software = null;
        if (device != IntPtr.Zero) Check(midiOutClose(device));
        device = IntPtr.Zero;
    }

    private static void SendMessage(uint message)
    {
        if (software is not null) software.Send(message);
        else Check(midiOutShortMsg(device, message));
    }

    private static void ResetDevice()
    {
        if (software is not null) software.Reset();
        else if (device != IntPtr.Zero) Check(midiOutReset(device));
    }

    private static (List<MidiEvent>, int) ReadEvents(byte[] bytes)
    {
        using var stream = new MemoryStream(bytes);
        using var reader = new BinaryReader(stream);
        uint Read32() => ((uint)reader.ReadByte() << 24) | ((uint)reader.ReadByte() << 16) | ((uint)reader.ReadByte() << 8) | reader.ReadByte();
        int Read16() => (reader.ReadByte() << 8) | reader.ReadByte();
        int Variable()
        {
            var value = 0;
            for (var i = 0; i < 4; i++)
            {
                var next = reader.ReadByte();
                value = (value << 7) | (next & 127);
                if (next < 128) return value;
            }
            throw new InvalidDataException("Invalid MIDI variable integer.");
        }
        if (Read32() != 0x4d546864 || Read32() != 6) throw new InvalidDataException("Invalid MIDI header.");
        var format = Read16();
        var tracks = Read16();
        var division = Read16();
        if (format > 1 || division == 0 || ((division & 0x8000) != 0 && (division & 255) == 0)) throw new NotSupportedException("MIDI format/timing not supported.");
        var result = new List<MidiEvent>();
        var order = 0;
        for (var track = 0; track < tracks; track++)
        {
            if (Read32() != 0x4d54726b) throw new InvalidDataException("Invalid MIDI track.");
            var lengthOfTrack = Read32();
            var end = stream.Position + lengthOfTrack;
            long tick = 0;
            byte running = 0;
            while (stream.Position < end)
            {
                tick += Variable();
                var status = reader.ReadByte();
                if (status < 128)
                {
                    if (running == 0) throw new InvalidDataException("Invalid MIDI running status.");
                    stream.Position--;
                    status = running;
                }
                if (status == 0xff)
                {
                    var kind = reader.ReadByte();
                    var length = Variable();
                    var data = reader.ReadBytes(length);
                    if (data.Length != length) throw new EndOfStreamException();
                    if (kind == 0x51 && length == 3) result.Add(new MidiEvent(tick, order++, 0, (data[0] << 16) | (data[1] << 8) | data[2]));
                    continue;
                }
                if (status is 0xf0 or 0xf7)
                {
                    var length = Variable();
                    var data = reader.ReadBytes(length);
                    if (data.Length != length) throw new EndOfStreamException();
                    if (status == 0xf0)
                    {
                        var message = new byte[length + 1];
                        message[0] = 0xf0;
                        Array.Copy(data, 0, message, 1, length);
                        result.Add(new MidiEvent(tick, order++, 0, 0, message));
                    }
                    else result.Add(new MidiEvent(tick, order++, 0, 0, data));
                    running = 0;
                    continue;
                }
                running = status;
                var first = reader.ReadByte();
                var second = (status & 0xf0) is 0xc0 or 0xd0 ? 0 : reader.ReadByte();
                result.Add(new MidiEvent(tick, order++, (uint)(status | (first << 8) | (second << 16)), 0));
            }
        }
        result.Sort((a,b) => a.Tick != b.Tick ? a.Tick.CompareTo(b.Tick) : a.Order.CompareTo(b.Order));
        return (result, division);
    }
}
