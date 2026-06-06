using System.Collections.Concurrent;
using Godot;

namespace RGSSUnity
{
    // Deferred logger queue for rescue-path safety and main-thread flushing.
    public static class RGSSLogger
    {
        private static readonly ConcurrentQueue<(bool IsError, string Message)> messageQueue = new();

        public static void Log(string msg)
        {
            messageQueue.Enqueue((false, msg));
        }

        public static void LogError(string msg)
        {
            messageQueue.Enqueue((true, msg));
        }

        public static void FlushPendingMessages()
        {
            while (messageQueue.TryDequeue(out var entry))
            {
                if (entry.IsError)
                {
                    GD.PrintErr(entry.Message);
                }
                else
                {
                    GD.Print(entry.Message);
                }
            }
        }
    }
}
