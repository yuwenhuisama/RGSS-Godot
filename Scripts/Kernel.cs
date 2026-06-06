using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Godot;
using MRuby.Library;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSGodot;

class KernelKeeperCategory { }

public static class Kernel
{
    private static readonly HashSet<string> RequiredPath = new();
    private static RubyScriptManager? manager;

    public static void Init(RubyScriptManager mgr)
    {
        manager = mgr;
        var stat = mgr.State;
        var kernel = stat.GetModule("Kernel");

        var keeper = RbNativeObjectLiveKeeper<KernelKeeperCategory, NativeMethodFunc>.GetOrCreateKeeper(stat);

        kernel.DefineModuleMethod("require", Require, RbHelper.MRB_ARGS_REQ(1), out var func);
        keeper.Keep(func);

        kernel.DefineModuleMethod("msgbox", MsgBox, RbHelper.MRB_ARGS_ANY(), out func);
        keeper.Keep(func);

        kernel.DefineModuleMethod("p", Print, RbHelper.MRB_ARGS_ANY(), out func);
        keeper.Keep(func);

        kernel.DefineModuleMethod("print", Print, RbHelper.MRB_ARGS_ANY(), out func);
        keeper.Keep(func);
    }

    public static bool IsScriptLoaded(string path) => RequiredPath.Contains(path);

    public static void AddPath(string path) => RequiredPath.Add(path);

    public static void Reset() => RequiredPath.Clear();

    private static RbValue Require(RbState state, RbValue self, params RbValue[] args)
    {
        var pathStr = args[0].ToStringUnchecked();
        return Require(state, pathStr);
    }

    private static RbValue Require(RbState state, string pathStr)
    {
        if (!RequiredPath.Add(pathStr))
            return state.RbNil;

        if (manager == null)
            throw new InvalidOperationException("Kernel not initialized with RubyScriptManager");

        var res = manager.LoadScriptInResources(pathStr, out var error);

        if (error)
            state.Raise(res);

        return res;
    }

    private static RbValue MsgBox(RbState state, RbValue self, params RbValue[] args)
    {
        foreach (var arg in args)
        {
            var str = arg.CallMethod("to_s");
            var info = str.IsString ? str.ToStringUnchecked() : "(non-string)";
            GD.Print(info);
        }
        return state.RbNil;
    }

    private static RbValue Print(RbState state, RbValue self, params RbValue[] args)
        => MsgBox(state, self, args);
}
