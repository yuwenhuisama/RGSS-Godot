using MRuby.Library;
using MRuby.Library.Language;

namespace RGSSUnity.RubyClasses
{
    public static class RbClassExtension
    {
        public static RbValue NewObjectWithRData<T>(this RbClass cls, T data, params RbValue[] args)
            where T : RubyData
        {
            // MRuby.Library >= 0.2.0 strong-roots the C# data object itself (GCHandle.Alloc
            // inside NewObjectWithCSharpDataObject) and tracks it in a per-state registry it
            // drains on Ruby.Close. No manual keeper is needed to keep `data` alive anymore.
            var obj = cls.NewObjectWithCSharpDataObject(RubyData.RDataName, data, args);
            return obj;
        }
    }

    public static class RbValueExtension
    {
        public static T GetRDataObject<T>(this RbValue value)
            where T : RubyData
        {
            var data = value.GetDataObject<T>(RubyData.RDataName)!;
            return data;
        }
    }

    public abstract class RubyData
    {
        public const string RDataName = "RData";

        protected RubyData(RbState state)
        {
            // No manual GC-rooting needed: MRuby.Library >= 0.2.0 roots the data object via
            // GCHandle in NewObjectWithCSharpDataObject for the lifetime of the native object.
        }
    }

    public static class RbStateExtension
    {
        public static void RaiseRGSSError(this RbState state, string message)
        {
            var exceptionClass = state.GetExceptionClass("RGSSError");
            var exc = state.GenerateExceptionWithNewStr(exceptionClass, message);
            state.Raise(exc);
        }
    }
}
