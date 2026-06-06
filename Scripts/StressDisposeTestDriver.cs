using System;
using System.Collections;
using System.Reflection;
using Godot;
using RGSSUnity;

namespace RGSSGodot;

[GlobalClass]
public partial class StressDisposeTestDriver : RefCounted
{
    private static readonly FieldInfo ViewportsField = typeof(GameRenderManager).GetField("viewports", BindingFlags.Instance | BindingFlags.NonPublic)!;
    private static readonly FieldInfo SpritesField = typeof(GameRenderManager).GetField("sprites", BindingFlags.Instance | BindingFlags.NonPublic)!;
    private static readonly FieldInfo WindowsField = typeof(GameRenderManager).GetField("windows", BindingFlags.Instance | BindingFlags.NonPublic)!;

    private bool initialized;

    public void Initialize(Node parent)
    {
        if (this.initialized)
            return;

        GlobalConfig.Initialize();
        RMProjectPath.Initialize();
        GameRenderManager.Instance.Initialize(parent);
        RubyScriptManager.Instance.Initialize();
        this.initialized = true;
    }

    public bool RunRuby(string scriptContent)
    {
        _ = RubyScriptManager.Instance.LoadScriptContentWithFileName("stress_dispose", scriptContent, out var error);
        return !error;
    }

    public void UpdateRenderManager()
        => GameRenderManager.Instance.Update();

    public int GetViewportCount()
        => GetDictionaryCount(ViewportsField);

    public int GetSpriteCount()
        => GetDictionaryCount(SpritesField);

    public int GetWindowCount()
        => GetDictionaryCount(WindowsField);

    public long GetManagedMemory()
        => GC.GetTotalMemory(false);

    public void CollectGarbage()
    {
        const string script = "GC.start if defined?(GC) && GC.respond_to?(:start)";
        _ = RubyScriptManager.Instance.LoadScriptContentWithFileName("stress_dispose_gc", script, out _);
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
    }

    public void Shutdown()
    {
        if (!this.initialized)
            return;

        GameRenderManager.Instance.Dispose();
        RubyScriptManager.Instance.Destroy();
        this.initialized = false;
    }

    private static int GetDictionaryCount(FieldInfo field)
    {
        var value = field.GetValue(GameRenderManager.Instance);
        return value is ICollection collection ? collection.Count : -1;
    }
}
