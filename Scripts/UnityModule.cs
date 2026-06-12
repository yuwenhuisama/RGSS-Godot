using System;
using System.Collections.Generic;
using System.IO;
using Godot;
using ICSharpCode.SharpZipLib.Zip.Compression.Streams;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses;

[RbModule("Unity", "")]
public static class UnityModule
{
    public static RbValue? UpdateFiber;

    public static RbState State = null!;

    private static readonly List<(long ScriptId, string ScriptName, string ScriptContent)> RmvaScripts = new();

    [RbInitEntryPoint]
    public static void Init(RbClass cls)
    {
        State = RubyScriptManager.Instance.State;
    }

    public static void Update()
    {
        if (UpdateFiber is not null && State.CheckFiberAlive(UpdateFiber).IsTrue)
        {
            bool error = false;
            var res = State.Protect((_, _, _) => State.FiberResume(UpdateFiber), ref error);

            if (error)
            {
                RGSSLogger.LogError("Failed to resume update fiber");
                RGSSLogger.LogError(SafeClassName(res));
            }
        }
    }

    [RbClassMethod("register_update_fiber")]
    private static RbValue RegisterUpdateFiber(RbState state, RbValue self, RbValue fiber)
    {
        if (!fiber.IsFiber)
            return state.RbNil;

        if (UpdateFiber is not null)
            state.GcUnregister(UpdateFiber);

        UpdateFiber = fiber;
        state.GcRegister(fiber);
        return state.RbNil;
    }

    [RbClassMethod("unregister_update_fiber")]
    private static RbValue UnregisterUpdateFiber(RbState state, RbValue self)
    {
        if (UpdateFiber is not null)
        {
            state.GcUnregister(UpdateFiber);
            UpdateFiber = null;
        }

        return state.RbNil;
    }

    [RbClassMethod("rmva_project_path")]
    private static RbValue GetRmvaProjectPath(RbState state, RbValue self)
        => RMProjectPath.BaseDir.ToValue(state);

    [RbClassMethod("on_top_exception")]
    private static RbValue OnTopExceptionHappened(RbState state, RbValue self, RbValue exceptionString)
    {
        var traceStr = exceptionString.CallMethod("to_s");
        var message = traceStr.IsString ? traceStr.ToStringUnchecked() : SafeClassName(traceStr);
        RGSSLogger.LogError($"Unhandled Ruby exception happened in script:\n {message}");
        return state.RbNil;
    }

    [RbClassMethod("msgbox")]
    private static RbValue MessageBox(RbState state, RbValue self, RbValue[] args)
    {
        foreach (var arg in args)
        {
            var str = arg.CallMethod("to_s");
            RGSSLogger.Log(str.IsString ? str.ToStringUnchecked() : SafeClassName(str));
        }

        return state.RbNil;
    }

    [RbClassMethod("rtp_path")]
    private static RbValue GetRtpPath(RbState state, RbValue self)
        => string.IsNullOrEmpty(GlobalConfig.Instance.RtpPath) ? state.RbNil : GlobalConfig.Instance.RtpPath.ToValue(state);

    [RbClassMethod("exit_game")]
    private static RbValue ExitGame(RbState state, RbValue self)
    {
        if (Engine.GetMainLoop() is SceneTree tree)
            tree.Quit();
        return state.RbNil;
    }

    [RbClassMethod("register_rmva_script")]
    private static RbValue RegisterRmvaScript(RbState state, RbValue self, RbValue scriptId, RbValue scriptName, RbValue scriptContent)
    {
        var id = scriptId.ToIntUnchecked();
        var name = scriptName.IsString ? scriptName.ToStringUnchecked() ?? string.Empty : string.Empty;
        var bytes = RbHelper.GetRawBytesFromRbStringObject(scriptContent);

        if (bytes.Length == 0)
        {
            RmvaScripts.Add((id, name, string.Empty));
            return state.RbNil;
        }

        try
        {
            using var inputStream = new MemoryStream(bytes);
            using var inflaterStream = new InflaterInputStream(inputStream);
            using var outputStream = new MemoryStream();
            inflaterStream.CopyTo(outputStream);

            var scriptString = System.Text.Encoding.UTF8.GetString(outputStream.ToArray());
            RmvaScripts.Add((id, name, scriptString));
        }
        catch (Exception ex)
        {
            RGSSLogger.LogError($"Failed to inflate script '{name}' (id={id}): {ex.Message}");
            RmvaScripts.Add((id, name, string.Empty));
        }

        return state.RbNil;
    }

    [RbClassMethod("run_rmva_scripts")]
    private static RbValue RunRmvaScripts(RbState state, RbValue self)
    {
        var inst = RubyScriptManager.Instance;

        var res = inst.LoadAllScriptInResources("ext", out var error);
        if (error)
        {
            state.Raise(res);
            return res;
        }

        res = inst.LoadAllScriptInResources("rpg", out error);
        if (error)
        {
            state.Raise(res);
            return res;
        }

        foreach (var (_, scriptName, scriptContent) in RmvaScripts)
        {
            RGSSLogger.Log($"run rmva script: {scriptName}");
            res = inst.LoadScriptContentWithFileName(scriptName, scriptContent, out error);

            if (error)
            {
                state.Raise(res);
                return res;
            }
        }

        return state.RbNil;
    }

    private static string SafeClassName(RbValue value)
    {
        try { return value.GetClassName() ?? "RubyException"; }
        catch { return "RubyException"; }
    }
}
